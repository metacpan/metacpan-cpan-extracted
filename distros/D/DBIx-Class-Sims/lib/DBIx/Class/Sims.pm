# vim: set sw=2 ft=perl:
package DBIx::Class::Sims;

use 5.010_001;

use strictures 2;

our $VERSION = '0.500012';

{
  # Do **NOT** import a clone() function into the DBIx::Class::Schema namespace
  # because that will override DBIC's clone() method and break all the things.
  package MyCloner;

  sub clone {
    my ($data) = @_;

    if (ref($data) eq 'HASH') {
      return {
        map { $_ => clone($data->{$_}) }
        keys %$data
      };
    }
    elsif (ref($data) eq 'ARRAY') {
      return [
        map { clone($_) }
        @$data
      ];
    }

    return $data;
  }
}

use DDP;

use Data::Walk qw( walk );
use DateTime;
use DBIx::Class::TopoSort ();
use Hash::Merge;
use List::Util qw( first );
use List::MoreUtils qw( natatime );
use Scalar::Util qw( blessed );

{
  # The aliases in this block are done at BEGIN time so that the ::Types class
  # can use them when it is loaded through `use`.

  my @sim_names;
  my %sim_types;
  my @sim_matchers;

  sub set_sim_type {
    shift;
    my $types = shift // '';

    if (ref($types) eq 'HASH') {
      while ( my ($name, $meth) = each(%$types) ) {
        next unless ref($meth) eq 'CODE';

        $sim_types{$name} = $meth;
        push @sim_names, $name;
      }
    }
    elsif (ref($types) eq 'ARRAY') {
      foreach my $item (@$types) {
        next unless ref($item->[2]) eq 'CODE';

        push @sim_names, $item->[0];
        push @sim_matchers, [ qr/^$item->[1]$/, $item->[2] ];
      }
    }

    return;
  }
  BEGIN { *set_sim_types = \&set_sim_type; }

  sub __find_sim_type {
    my ($str) = @_;

    unless (exists $sim_types{$str}) {
      my $item = first { $str =~ $_->[0] } @sim_matchers;
      if ($item) {
        $sim_types{$str} = $item->[1];
      }
    }

    return $sim_types{$str};
  }

  sub sim_type {
    shift;

    # If no specific type requested, then return the complete list of all
    # registered types.
    return sort @sim_names if @_ == 0;

    return __find_sim_type($_[0]) if @_ == 1;
    return map { __find_sim_type($_) } @_;
  }
  BEGIN { *sim_types = \&sim_type; }
}
use DBIx::Class::Sims::Types;

use DBIx::Class::Sims::Runner;
use DBIx::Class::Sims::Util qw( normalize_aoh reftype );

sub add_sims {
  my $class = shift;
  my ($schema, $source, @remainder) = @_;

  my $rsrc = $schema->source($source);
  my $it = natatime(2, @remainder);
  my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
  while (my ($column, $sim_info) = $it->()) {
    my $col_info = $schema->source($source)->column_info($column) // next;
    $col_info->{sim} = $merger->merge(
      $col_info->{sim} // {},
      $sim_info // {},
    );
  }

  return;
}
*add_sim = \&add_sims;

sub load_sims {
  my $self = shift;
  my $schema;
  if (ref($self) && $self->isa('DBIx::Class::Schema')) {
    $schema = $self;
  }
  else {
    $schema = shift(@_);
  }
  my ($spec_proto, $opts_proto) = @_;
  $spec_proto = MyCloner::clone($spec_proto // {});
  $opts_proto = MyCloner::clone($opts_proto // {});

  my $spec = massage_input($schema, normalize_input($spec_proto));
  my $opts = normalize_input($opts_proto);

  # Create a lookup of the items passed in so we can return them back.
  my $initial_spec = {};
  foreach my $name (keys %$spec) {
    my $normalized = normalize_aoh($spec->{$name});
    unless ($normalized) {
      warn "Skipping $name - I don't know what to do!\n";
      delete $spec->{$name};
      next;
    }
    $spec->{$name} = $normalized;

    foreach my $item (@{$spec->{$name}}) {
      $initial_spec->{$name}{$item} = 1;
    }
  }

  my ($rows, $additional) = ({}, {});
  if (keys %{$spec}) {
    # Yes, this invokes srand() twice, once in implicitly in rand() and once
    # again right after. But, that's okay. We don't care what the seed is and
    # this allows DBIC to be called multiple times in the same process in the
    # same second without problems.
    $additional->{seed} = $opts->{seed} //= rand(time & $$);
    srand($opts->{seed});

    my @toposort;
    if ( $opts->{topograph_file} ) {
      @toposort = load_topograph($opts->{topograph_file});
    }
    else {
      @toposort = DBIx::Class::TopoSort->toposort(
        $schema,
        %{$opts->{toposort} // {}},
      );
    }

    if ( $opts->{topograph_trace} ) {
      save_topograph(\@toposort, $opts->{topograph_trace});
    }

    my $strict_mode = $opts->{strict_mode} // 0;
    if ($strict_mode) {
      $opts->{ignore_unknown_tables} //= 0;
      $opts->{ignore_unknown_columns} //= 0;
      $opts->{allow_relationship_column_names} //= 0;
      $opts->{die_on_failure} //= 1;
      $opts->{die_on_unique_mismatch} //= 1;
    }

    my $runner = DBIx::Class::Sims::Runner->new(
      parent => $self,
      schema => $schema,
      toposort => \@toposort,
      initial_spec => $initial_spec,
      spec => $spec,
      constraints => normalize_input($opts->{constraints} // {}),

      hooks => $opts->{hooks} // {},

      # Set this to false to throw a warning if a PK auto-increment column
      # has a value set. It defaults to false. Set to true to disable.
      allow_pk_set_value => $opts->{allow_pk_set_value} // 0,
      ignore_unknown_tables => $opts->{ignore_unknown_tables} // 0,
      ignore_unknown_columns => $opts->{ignore_unknown_columns} // 0,
      allow_relationship_column_names => $opts->{allow_relationship_column_names} // 1,
      die_on_unique_mismatch => $opts->{die_on_unique_mismatch} // 1,

      object_trace => $opts->{object_trace},
      predictable_values => $opts->{predictable_values},
    );

    $rows = eval {
      $runner->run();
    }; if ($@) {
      $additional->{error} = $@;

      if ($opts->{die_on_failure} // 1) {
        warn "SEED: $opts->{seed}\n";
        die $@;
      }
    }

    $additional->{created}    = $runner->{created};
    $additional->{duplicates} = $runner->{duplicates};

    # Force a reload from the database of every row we're returning.
    foreach my $item (values %$rows) {
      $_->discard_changes for @$item;
    }
  }

  if (wantarray) {
    return ($rows, $additional);
  }
  else {
    return $rows;
  }
}

use JSON::MaybeXS qw( decode_json encode_json );
use YAML::Any qw( LoadFile Load );
sub normalize_input {
  my ($proto) = @_;

  if ( ref($proto) ) {
    return $proto;
  }

  # Doing a stat on a filename with a newline throws an error.
  my $x = eval {
    no warnings;
    if ( -e $proto ) {
      return LoadFile($proto);
    }
  };
  return $x if $x;

  return Load($proto);
}

sub massage_input {
  my ($schema, $struct) = @_;

  my $dtp = $schema->storage->datetime_parser;
  my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
  walk({
    preprocess => sub {
      # Don't descend into the weeds. Only do the things we care about.
      return if grep { blessed($_) } @_;
      return unless grep { reftype($_) } @_;
      return @_;
    },
    wanted => sub {
      return unless reftype($_) eq 'HASH' && !blessed($_);
      foreach my $k ( keys %$_ ) {
        my $t = $_;

        # Expand the dot-naming convention.
        while ( $k =~ /([^.]*)\.(.*)/ ) {
          $t->{$1} = $merger->merge(
            ($t->{$1} // {}),
            { $2 => delete($t->{$k}) },
          );
          $t = $t->{$1}; $k = $2;
        }

        # Handle DateTime values passed to us.
        if (defined $t->{$k}) {
          if ( $t->{$k} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)$/ ) {
            # format_datetime() requires a DateTime object. This may be a
            # string, therefore hoist it if need-be.
            unless (blessed($t->{$k})) {
              $t->{$k} = DateTime->new(
                year   => $1, month  => $2, day    => $3,
                hour   => $4, minute => $5, second => $6,
              );
            }
            $t->{$k} = $dtp->format_datetime($t->{$k});
          }
        }
      }
    },
  }, $struct);

  return $struct;
}

sub load_topograph {
  my ($filename) = @_;
  my $data = do {
    local $/;
    open my $fh, '<', $filename;
    <$fh>;
  };
  return @{decode_json($data)};
}

sub save_topograph {
  my ($array, $filename) = @_;
  open my $fh, '>', $filename;
  print $fh encode_json($array);
  close $fh;
}

1;
__END__

=head1 NAME

DBIx::Class::Sims - The addition of simulating data to DBIx::Class

=head1 SYNOPSIS (CLASS VERSION)

  DBIx::Class::Sims->add_sims(
      $schema, 'source_name',
      address => { type => 'us_address' },
      zip_code => { type => 'us_zipcode' },
      # ...
  );

  my $rows = DBIx::Class::Sims->load_sims($schema, {
    Table1 => [
      {}, # Take sims or default values for everything
      { # Override some values, take sim values for others
        column1 => 20,
        column2 => 'something',
      },
    ],
  });

=head1 SYNOPSIS (COMPONENT VERSION)

Within your schema class:

  __PACKAGE__->load_components('Sims');

Within your resultsources, specify the sims generation rules for columns that
need specified.

  __PACKAGE__->add_columns(
    ...
    address => {
      data_type => 'varchar',
      is_nullable => 1,
      data_length => 10,
      sim => { type => 'us_address' },
    },
    zipcode => {
      data_type => 'varchar',
      is_nullable => 1,
      data_length => 10,
      sim => { type => 'us_zipcode' },
    },
    column1 => {
      data_type => 'int',
      is_nullable => 0,
      sim => {
        min => 10,
        max => 20,
      },
    },
    column2 => {
      data_type => 'varchar',
      is_nullable => 1,
      data_length => 10,
      default_value => 'foobar',
    },
    ...
  );

Later:

  $schema->deploy({
    add_drop_table => 1,
  });

  my $rows = $schema->load_sims({
    Table1 => [
      {}, # Take sims or default values for everything
      { # Override some values, take sim values for others
        column1 => 20,
        column2 => 'something',
      },
    ],
  });

=head1 PURPOSE

Generating test data for non-simplistic databases is extremely hard, especially
as the schema grows and changes. Designing scenarios B<should> be doable by only
specifying the minimal elements actually used in the test with the test being
resilient to any changes in the schema that don't affect the elements specified.
This includes changes like adding a new parent table, new required child tables,
and new non-NULL columns to the table being tested.

With Sims, you specify only what you care about. Any required parent rows are
automatically generated. If a row requires a certain number of child rows (all
artists must have one or more albums), that can be set as well. If a column must
have specific data in it (a US zipcode or a range of numbers), you can specify
that in the table definition.

And, in all cases, you can override anything.

=head1 DESCRIPTION

This is a L<DBIx::Class> component that adds a few methods to your
L<DBIx::Class::Schema> object. These methods make it much easier to create data
for testing purposes (though, obviously, it's not limited to just test data).

Alternately, it can be used as a class method vs. a component, if that fits your
needs better.

=head1 METHODS

=head2 load_sims

C<< $rv, $addl? = $schema->load_sims( $spec, ?$opts ) >>
C<< $rv, $addl? = DBIx::Class::Sims->load_sims( $schema, $spec, ?$opts ) >>

This method will load the rows requested in C<$spec>, plus any additional rows
necessary to make those rows work. This includes any parent rows (as defined by
C<belongs_to>) and per any constraints defined in C<< $opts->{constraints} >>. If
need-be, you can pass in hooks (as described below) to manipulate the data.

load_sims does all of its work within a call to L<DBIx::Class::Schema/txn_do>.
If anything goes wrong, load_sims will rethrow the error after the transaction
is rolled back.

This, of course, assumes that the tables you are working with support
transactions. (I'm looking at you, MyISAM!) If they do not, that is on you.

=head3 Return value

This returns one or two values, depending on if you call load_sims in a scalar
or array context.

The first value is a hash of arrays of hashes. This will match the C<$spec>,
except that where the C<$spec> has a requested set of things to make, the return
will have the DBIx::Class::Row objects that were created.

Note that you do not get back the objects for anything other than the objects
specified at the top level.

This second value is a hashref with additional items that may be useful. It may
contain:

=over 4

=item * error

This will contain any error that happened while trying to create the rows.

This is most useful when C<< die_on_failure >> is set to 0.

=item * seed

This is the random seed that was used in this run. If you set the seed in the
opts parameter in the load_sims call, it will be that value. Otherwise, it will
be set to a usefully random value for you. It will be different every time even
if you call load_sims multiple times within the same process in the same second.

=item * created

This is a hashref containing a count of each source that was created. This is
different from the first return value in that this lists everything created, not
just what was requested. It also only has counts, not the actual rows.

=item * duplicates

This is a hashref containing a list for each source of all the duplicates that
were found when creating rows for that source. For each duplicate found, there
will be an entry that specifies the criteria used to find that duplicate and the
row in the database that was found.

The list will be ordered by when the duplicate was found, but that ordering will
B<NOT> be stable across different runs unless the same C<< seed >> is used.

=item * allow_set_pk_value

If this is false or omitted, then a warning will be emitted if a sims spec sets
a value for a column that is:

=over 4

=item * in a primary key (either alone or with other columns)

=item * NOT NULLL

=item * set to auto_increment

=back

If this is true, then the warning is suppressed.

=back

=head2 set_sim_type

C<< $class_or_obj->set_sim_type({ $name => $handler, ... }); >>
C<< $class_or_obj->set_sim_type([ [ $name, $regex, $handler ], ... ]); >>

This method will set the handler for the C<$name> sim type. The C<$handler> must
be a reference to a subroutine. You may pass in as many name/handler pairs as you
like.

You may alternately pass in an arrayref of triplets. This allows you to use a
regex to match the provided type. C<$name> will be returned when the user
introspects the list of loaded sim types. C<$regex> will be used when finding the
type to handle this column. C<$handler> must be a reference to a subroutine.

You cannot set pairs and triplets in the same invocation.

This method may be called as a class or object method.

This method returns nothing.

C<set_sim_types()> is an alias to this method.

=head2 sim_types

C<< $class_or_obj->sim_types(); >>

This method will return a sorted list of all registered sim types.

This method may be called as a class or object method.

=head2 add_sims

Given a C<< $schema >>, source name, and pairs of column/sim_type info, this
method will decorate the source's columns with appropriate sim types. This is
in lieu of adding the sim information to the column definition.

This method is only meant for usage as a class method. Do not use this method if
you load Sims as a component.

=head1 SPECIFICATION

The specification can be passed along as a filename that contains YAML or JSON,
a string that contains YAML or JSON, or as a hash of arrays of hashes. The
structure should look like:

  {
    ResultSourceName => [
      {
        column => $value,
        column => $value,
        relationship => $parent_object,
        relationship => {
          column => $value,
        },
        'relationship.column' => $value,
        'rel1.rel2.rel3.column' => $value,
      },
    ],
  }

If a column is a belongs_to relationship name, then the row associated with that
relationship specifier will be used. This is how you would specify a specific
parent-child relationship. (Otherwise, a random choice will be made as to which
parent to use, creating one as necessary if possible.) The dots will be followed
as far as necessary.

If a column's value is a hashref, then that will be treated as a sim entry.
Example:

  {
    Artist => [
      {
        name => { type => 'us_name' },
      },
    ],
  }

That will use the provided sim type 'us_name'. This will override any sim entry
specified on the column. See L</SIM ENTRY> for more information.

Note: Before 0.300800, this behavior was triggered by a reference to a hashref.
That will still work, but is deprecated, throws a warning, and will be removed
in a future release.

Columns that have not been specified will be populated in one of two ways. The
first is if the database has a default value for it. Otherwise, you can specify
the C<sim> key in the column_info for that column. This is a new key that is not
used by any other component. See L</SIM ENTRY> for more information.

(Please see L<DBIx::Class::ResultSource/add_columns> for details on column_info)

B<NOTE>: The keys of the outermost hash are resultsource names. The keys within
the row-specific hashes are either columns or relationships. Not resultsources.

=head2 Reuse wherever possible

The Sims's normal behavior is to attempt to reuse whenever possible. The theory
is that if you didn't say you cared about something, you do B<NOT> care about
that thing.

=head3 Unique constraints

If a source has unique constraints defined, the Sims will use them to determine
if a new row with these values I<can> be created or not. If a row already
exists with these values for the unique constraints, then that row will be used
instead of creating a new one.

This is B<REGARDLESS> of the values for the non-unique-constraint rows.

=head3 Forcing creation of a parent

If you do not specify values for a parent (i.e., belongs_to), then the first row
for that parent will be be used. If you don't care what values the parent has,
but you care that a different parent is used, then you can set the __META__ key
as follows:

  $schema->load_sims({
    Album => {
      artist => { __META__ => { create => 1 } },
      name => 'Some name',
    }
  })

This will force the creation of a parent instead of reusing the parent.

B<NOTE>: If the simmed values within the parent's class would result in values
that are the same across a unique constraint with an existing row, then that
row will be used. This just bypasses the "attempt to use the first parent".

=head2 Alternatives

=head3 Hard-coded number of things

If you only want N of a thing, not really caring just what the column values end
up being, you can take a shortcut:

  {
    ResultSourceName => 3,
  }

That will create 3 of that thing, taking all the defaults and sim'ed options as
exist.

This will also work if you want 3 of a child via a has_many relationship. For
example, you can do:

  {
      Artist => {
          name => 'Someone Famous',
          albums => 240,
      },
  }

That will create 240 different albums for that artist, all with the defaults.

=head3 Just one thing

If you are creating one of a thing and setting some of the values, you can skip
the arrayref and pass the hashref directly.

  {
    ResultSourceName => {
      column => $value,
      column => $value,
      relationship => {
        column => $value,
      },
      'relationship.column' => $value,
      'rel1.rel2.rel3.column' => $value,
    },
  }

And that will work exactly as expected.

=head3 References

Let's say you have a table that's a child of two other tables. You can specify
that relationship as follows:

  {
      Parent1 => 1,
      Parent2 => {
          Child => {
              parent1 => \"Parent1[0]",
          },
      },
  }

That's a reference to a string with the tablename as a pseudo-array, then the
index into that array. This only works for rows that you are going to return
back from the C<< load_sims() >> call.

This also only works for belongs_to relationships. Since all parents are created
before all children, the Sims cannot back-reference into children.

=head3 Methods of References

Let's say you want to create something where an attribute needs to have the same
value as a parent's attribute. You can do it as so:

  {
      Parent => {
          name => 'foo',
          Child => {
              name => \"Parent[0].name",
          },
      },
  }

All the rules of back-references apply. This will only work for method calls
that do not require parameters.

You can chain method calls as well. For example:

  {
      Artist => {
          name => 'They Might Be Giants',
      },
      Album => {
          artist => \'Artist[0]',
          name => 'Flood',
      },
      Track => {
          album => \'Album[0]',
          name => \'Album[0].artist.name',
      },
  }

(Yes, TMBG released a song called "TMBG". If only the album was also "TMBG" ...)

=head2 Notes

=over 4

=item * Multiply-specified children

Sometimes, you will have a table with more than one parent (q.v. t/t5.t for an
example of this). If you specify a row for each parent and, in each parent,
specify a child with the same characteristics, only one child will be created.
The assumption is that you meant the same row.

This does B<not> apply to creating multiple rows with the same characteristics
as children of the same parent. The assumption is that you meant to do that.

=back

=head1 OPTS

There are several possible options.

=head2 constraints

The constraints can be passed along as a filename that contains YAML or JSON, a
string that contains YAML or JSON, or as a hash of arrays of hashes. The
structure should look like:

  {
    Person => {
      addresses => 2,
    },
  }

All the C<belongs_to> relationships are automatically added to the constraints.
You can add additional constraints, as needed. The most common use for this will
be to add required child rows. For example, C<< Person->has_many('addresses') >>
would normally mean that if you create a Person, no Address rows would be
created.  But, we could specify a constraint that says "Every person must have
at least 2 addresses." Now, whenever a Person is created, two Addresses will be
added along as well, if they weren't already created through some other
specification.

=head2 die_on_failure

If set to 0, this will prevent a die when creating a row. Instead, you will be
responsible for checking C<< $additional->{error} >> yourself.

This defaults to 1.

=head2 seed

If set, this will be the srand() seed used for this invocation.

=head2 ignore_unknown_columns

If set to 1, this will ignore column names that don't exist in the schema.
Otherwise, it will raise an error.

This defaults to 0.

=head2 ignore_unknown_tables

If set to 1, this will ignore table names that don't exist in the schema.
Otherwise, it will raise an error.

This defaults to 0.

=head2 allow_relationship_column_names

If set to 0, this will raise an error if relationship is specified with the
column name instead of the relationship name.

If they are the same, this will not raise an error. (This is generally a bad
idea, but some schemas do this.)

This defaults to 1.

=head2 die_on_unique_mismatch

If set to 0, this will prevent a die when an existing row is found that matches
the unique columns set in the spec, but the other columns don't match. Instead,
you will be responsible for checking C<< $additional->{error} >> yourself.

This defaults to 1.

=head2 strict_mode

This sets the following options:

=over 4

=item * C<< die_on_failure => 1 >>

=item * C<< ignore_unknown_columns => 0 >>

=item * C<< ignore_unknown_tables => 0 >>

=item * C<< allow_relationship_column_names => 0 >>

=item * C<< die_on_unique_mismatch => 1 >>

=back

If you have explicitly set one of these options, it will override strict_mode.

=head2 toposort

This is passed directly to the call to C<< DBIx::Class::TopoSort->toposort >>.

See L<DBIx::Class::TopoSort/toposort> for more information.

=head2 topograph_trace

If this is set, then the list of tables from the toposort graph will be written
out in JSON to this file.

=head2 topograph_file

If this is set, then the list of tables of the toposort graph will be read from
this file in JSON. It's expected that it will return a list of strings.

If this is set, then the toposort option will be ignored.

This is often best used with the topograph_trace option.

=head2 object_trace

If this is set, then the ojbects found and created will be written out in JSON
to this file.

=head2 hooks

Most people will never need to use this. But, some schema definitions may have
reasons that prevent a clean simulating with this module. For example, there may
be application-managed sequences. To that end, you may specify the following
hooks:

=over 4

=item * preprocess

This receives C<$source, $spec> and ignores any return value.

=over 4

=item * C<$source>

This is a L<DBIx::Class::Sims::Source/> object.

=item * C<$spec>

This is a hashref of the Sims specification that was received. You are expected
to modify this as needed.

This will B<NOT> have any generated values.

=back

=item * before_create

This receives C<$source, $item> and ignores any return value.

=over 4

=item * C<$source>

This is a L<DBIx::Class::Sims::Source/> object.

=item * C<$item>

This is a L<DBIx::Class::Sims::Item/> object. You will probably want to call
C<< $item->set_value($col, $val) >>.

=back

=item * postprocess

This receives C<$source, $row> and ignores any return value.

=over 4

=item * C<$source>

This is a L<DBIx::Class::Sims::Source/> object.

=item * C<$row>

This is the L<DBIx::Class::Row/> that was either found or created. You are
expected to modify this as needed.

=back

=back

=head1 SIM ENTRY

To control how a column's values are simulated, add a "sim" entry in the
column_info for that column. The sim entry is a hash that can have the followingkeys:

=over 4

=item * value / values

This behaves just like default_value would behave, but doesn't require setting a
default value on the column.

  sim => {
      value => 'The value to always use',
  },

This can be either a string, number, or an arrayref of strings or numbers. If it
is an arrayref, then a random choice from that array will be selected.

=item * value_not / values_not

This is the value(s) to avoid. It can be a string, arrayref of strings, or a
function which takes a value and returns true if the value should be avoided.
This can be combined with anything else to constrain in a specific situation.

=item * type

This labels the column as having a certain type. A type is registered using
L</set_sim_type>. The type acts as a name for a function that's used to generate
the value. See L</Types> for more information.

=item * min / max

If the column is numeric, then the min and max bound the random value generated.
If the column is a string, then the min and max are the length of the random
value generated.

=item * func

This is a function that is provided the column info. Its return value is used to
populate the column.

=item * null_chance

If the column is nullable I<and> this is set I<and> it is a number between 0 and
1, then if C<rand()> is less than that number, the column will be set to null.
Otherwise, the standard behaviors will apply.

If the column is B<not> nullable, this setting is ignored.

=back

(Please see L<DBIx::Class::ResultSource/add_columns> for details on column_info)

=head2 Types

The handler for a sim type will receive the column info (as defined in
L<DBIx::Class::ResultSource/add_columns>). From that, the handler returns the
value that will be used for this column.

Please see L<DBIx::Class::Sims::Types> for the list of included sim types.

=head1 SEQUENCE OF EVENTS

When an item is created, the following actions are taken (in this order):

=over 4

=item 1. The preprocess hook fires.

You can modify the Sims specification hashref as necessary. This includes
potentially changing what parent and/or child rows to associate with this row.

=item 2. Direct values are resolved.

These are backreferences and blessed objects. They are resolved immediately
because all other actions expect scalars.

=item 3. Attempt to find a unique match (#1)

This is the first of N attempts to find a unique match with what's been set so
far. All combinations of the unique keys are attempted and all other columns
are ignored. If a match is found, then other columns are compared against what
was found to see if there's a mismatch (in which case an exception is thrown).

If a row is found, then some other actions will be skipped.

=item 4. Populate all non-NULL parent columns

Resolve all parent relationships. This will involve creating an
L<DBIx::Class::Sims::Item> object for each one. Parent rows will be created, if
necessary.

If a row has already been found, this step is skipped.

=item 5. Attempt to find a unique match (#2)

This is the second of N attempts to find a unique match with what's been set so
far. This time, we include all parent information.

If a row has already been found, this step is skipped.

=item 6. The columns are fixed up.

If a row has not been found, then ensure all columns which should have a value
have a value set. After this is done, all the values that will be inserted into
the database are now available.

q.v. L</SIM ENTRY> for more information.

=item 7. Attempt to find a unique match (#3)

This is the third of N attempts to find a unique match with what's been set so
far. This time, we include all columns.

If a row has already been found, this step is skipped.

=item 8. Attempt to find any match

Given all values that have been set, attempt to see if this row already exists
in the database. This is regardless of unique constraints.

If a row has already been found, this step is skipped.

=item 9. The before_create hook fires.

You can modify the L<DBIx::Class::Sims::Item> object as necessary, potentially
changing what the column values are.

If a row has already been found, this step is skipped.

=item 10. The row is created.

If a row has already been found, this step is skipped.

=item 11. Populate all NULL-able parent columns

Resolve all nullable parent relationships. This will involve creating an
L<DBIx::Class::Sims::Item> object for each one. Parent rows will be created, if
necessary.

If a row has already been found, this step is skipped.

=item 12. All child relationships are handled

Because they're a child relationship, they are deferred until the time that
model is handled in the toposorted graph. They are not created now because they
might associate with a different parent that has not been created yet.

=item 13. The postprocess hook fires.

You can modify the created/found row as necessary.

=back

=head1 DEBUGGING

If you set the envvar C<< SIMS_DEBUG >> to true, then lots of useful information
will be output.

=head1 TODO

=head2 Multi-column types

In some applications, columns like "state" and "zipcode" are correlated. Values
for one must be legal for the value in the other. The Sims currently has no way
of generating correlated columns like this.

This is most useful for saying "These 6 columns should be a coherent address".

=head2 Allow a column to reference other columns

Sometimes, a column should alter its behavior based on other columns. A fullname
column may have the firstname and lastname columns concatenated, with other
things thrown in. Or, a zipcode column should only generate a zipcode that're
legal for the state.

=head1 BUGS/SUGGESTIONS

This module is hosted on Github at
L<https://github.com/robkinyon/dbix-class-sims>. Pull requests are strongly
encouraged.

=head1 DBIx::Class::Fixtures

L<DBIx::Class::Fixtures> is another way to load data into a database. Unlike
this module, L<DBIx::Class::Fixtures> approaches the problem by loading the same
data every time. This is complementary because some tables (such as lookup
tables of countries) want to be seeded with the same data every time. The ideal
solution would be to have a set of tables loaded with fixtures and another set
of tables loaded with sims.

=head1 SEE ALSO

L<DBIx::Class>, L<DBIx::Class::Fixtures>

=head1 AUTHOR

Rob Kinyon <rob.kinyon@gmail.com>

=head1 LICENSE

Copyright (c) 2013 Rob Kinyon. All Rights Reserved.
This is free software, you may use it and distribute it under the same terms
as Perl itself.

=cut

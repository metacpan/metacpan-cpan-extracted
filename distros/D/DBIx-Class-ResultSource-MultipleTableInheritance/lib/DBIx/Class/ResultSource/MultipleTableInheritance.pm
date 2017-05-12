package DBIx::Class::ResultSource::MultipleTableInheritance;

use strict;
use warnings;
use parent qw(DBIx::Class::ResultSource::View);
use Method::Signatures::Simple;
use Carp::Clan qw/^DBIx::Class/;
use aliased 'DBIx::Class::ResultSource::Table';
use aliased 'DBIx::Class::ResultClass::HashRefInflator';
use String::TT qw(strip tt);
use Scalar::Util qw(blessed);
use namespace::autoclean -also => [qw/argify qualify_with body_cols pk_cols names_of function_body arg_hash rule_body/];

our $VERSION = 0.03;

__PACKAGE__->mk_group_accessors(simple => qw(parent_source additional_parents));

# how this works:
#
# On construction, we hook $self->result_class->result_source_instance
# if present to get the superclass' source object
#
# When attached to a schema, we need to add sources to that schema with
# appropriate relationships for the foreign keys so the concrete tables
# get generated
#
# We also generate our own view definition using this class' concrete table
# and the view for the superclass, and stored procedures for the insert,
# update and delete operations on this view.
#
# deploying the postgres rules through SQLT may be a pain though.

method new ($class: @args) {
  my $new = $class->next::method(@args);
  my $rc = $new->result_class;
  if (my $meth = $rc->can('result_source_instance')) {
    my $source = $rc->$meth;
    if ($source->result_class ne $new->result_class
        && $new->result_class->isa($source->result_class)) {
      $new->parent_source($source);
    }
  }
  return $new;
}

method add_additional_parents (@classes) {
  foreach my $class (@classes) {
    Class::C3::Componentised->ensure_class_loaded($class);
    $self->add_additional_parent(
      $class->result_source_instance
    );
  }
}

method add_additional_parent ($source) {
  my ($our_pk, $their_pk) = map {
    join('|',sort $_->primary_columns)
  } ($self, $source);

  confess "Can't attach additional parent ${\$source->name} - it has different PKs ($their_pk versus our $our_pk)"
    unless $their_pk eq $our_pk;
  $self->additional_parents([
    @{$self->additional_parents||[]}, $source
  ]);
  $self->add_columns(
    map {
      $_ => # put the extra key first to default it
      { originally_defined_in => $source->name, %{$source->column_info($_)}, },
    } grep !$self->has_column($_), $source->columns
  );
  foreach my $rel ($source->relationships) {
    my $rel_info = $source->relationship_info($rel);
    $self->add_relationship(
      $rel, $rel_info->{source}, $rel_info->{cond},
      # extra key first to default it
      {originally_defined_in => $source->name, %{$rel_info->{attrs}}},
    );
  }
  { no strict 'refs';
    push(@{$self->result_class.'::ISA'}, $source->result_class);
  }
}

method _source_by_name ($name) {
  my $schema = $self->schema;
  my ($source) =
    grep { $_->name eq $name }
      map $schema->source($_), $schema->sources;
  confess "Couldn't find attached source for parent $name - did you use load_classes? This module is only compatible with load_namespaces"
    unless $source;
  return $source;
}

method schema (@args) {
  my $ret = $self->next::method(@args);
  if (@args) {
    if ($self->parent_source) {
      my $parent_name = $self->parent_source->name;
      $self->parent_source($self->_source_by_name($parent_name));
    }
    $self->additional_parents([
      map { $self->_source_by_name($_->name) }
      @{$self->additional_parents||[]}
    ]);
  }
  return $ret;
}

method attach_additional_sources () {
  my $raw_name = $self->raw_source_name;
  my $schema = $self->schema;

  # if the raw source is already present we can assume we're done
  return if grep { $_ eq $raw_name } $schema->sources;

  # our parent should've been registered already actually due to DBIC
  # attaching subclass sources later in load_namespaces

  my $parent;
  if ($self->parent_source) {
      my $parent_name = $self->parent_source->name;
    ($parent) =
      grep { $_->name eq $parent_name }
        map $schema->source($_), $schema->sources;
    confess "Couldn't find attached source for parent $parent_name - did you use load_classes? This module is only compatible with load_namespaces"
      unless $parent;
    $self->parent_source($parent); # so our parent is the one in this schema
  }

  # create the raw table source

  my $table = Table->new({ name => $self->raw_table_name });

  # we don't need to add the PK cols explicitly if we're the root table
  # since they'll get added below

  my %pk_join;

  if ($parent) {
    foreach my $pri ($self->primary_columns) {
      my %info = %{$self->column_info($pri)};
      delete @info{qw(is_auto_increment sequence auto_nextval)};
      $table->add_column($pri => \%info);
      $pk_join{"foreign.${pri}"} = "self.${pri}";
    }
    # have to use source name lookups rather than result class here
    # because we don't actually have a result class on the raw sources
    $table->add_relationship('parent', $parent->raw_source_name, \%pk_join);
    $self->deploy_depends_on->{$parent->result_class} = 1;
  }

  foreach my $add (@{$self->additional_parents||[]}) {
    $table->add_relationship(
      'parent_'.$add->name, $add->source_name, \%pk_join
    );
    $self->deploy_depends_on->{$add->result_class} = 1 if $add->isa('DBIx::Class::ResultSource::View');
  }
  $table->add_columns(
    map { ($_ => { %{$self->column_info($_)} }) }
      grep { $self->column_info($_)->{originally_defined_in} eq $self->name }
        $self->columns
  );
  $table->set_primary_key($self->primary_columns);

  # we need to copy our rels to the raw object as well
  # note that ->add_relationship on a source object doesn't create an
  # accessor so we can leave that part in the attributes

  # if the other side is a table then we need to copy any rels it has
  # back to us, as well, so that they point at the raw table. if the
  # other side is an MTI view then we need to create the rels to it to
  # point at -its- raw table; we don't need to worry about backrels because
  # it's going to run this method too (and its raw source might not exist
  # yet so we can't, anyway)

  foreach my $rel ($self->relationships) {
    my $rel_info = $self->relationship_info($rel);

    # if we got this from the superclass, -its- raw table will nail this.
    # if we got it from an additional parent, it's its problem.
    next unless $rel_info->{attrs}{originally_defined_in} eq $self->name;

    my $f_source = $schema->source($rel_info->{source});

    # __PACKAGE__ is correct here because subclasses should be caught

    my $one_of_us = $f_source->isa(__PACKAGE__);

    my $f_source_name = $f_source->${\
                        ($one_of_us ? 'raw_source_name' : 'source_name')
                      };

    $table->add_relationship(
      '_'.$rel, $f_source_name, @{$rel_info}{qw(cond attrs)}
    );

    unless ($one_of_us) {
      my $reverse = do {
        # we haven't been registered yet, so reverse_ cries
        # XXX this is evil and will probably break eventually
        local @{$schema->source_registrations}
               {map $self->$_, qw(source_name result_class)}
          = ($self, $self);
        $self->reverse_relationship_info($rel);
      };
      foreach my $rev_rel (keys %$reverse) {
        $f_source->add_relationship(
          '_raw_'.$rev_rel, $raw_name, @{$reverse->{$rev_rel}}{qw(cond attrs)}
        );
      }
    }
  }

  $schema->register_source($raw_name => $table);
}

method set_primary_key (@args) {
  if ($self->parent_source) {
    confess "Can't set primary key on a subclass";
  }
  return $self->next::method(@args);
}

method set_sequence ($table_name, @pks) {
  return $table_name . '_' . join('_',@pks) . '_' . 'seq';
}

method raw_source_name () {
  my $base = $self->source_name;
  confess "Can't generate raw source name for ${\$self->name} when we don't have a source_name"
    unless $base;
  return 'Raw::'.$base;
}

method raw_table_name () {
  return '_'.$self->name;
}

method add_columns (@args) {
  my $ret = $self->next::method(@args);
  $_->{originally_defined_in} ||= $self->name for values %{$self->_columns};
  return $ret;
}

method add_relationship ($name, $f_source, $cond, $attrs) {
  $self->next::method(
    $name, $f_source, $cond,
    { originally_defined_in => $self->name, %{$attrs||{}}, }
  );
}

BEGIN {

  # helper routines

  sub argify {
    my @names = @_;
    map '_' . $_, @names;
  }

  sub qualify_with {
    my $source = shift;
    my @names  = @_;
    my $name   = blessed($source) ? $source->name : $source;
    map join( '.', $name, $_ ), @names;
  }

  sub body_cols {
    my $source = shift;
    my %pk;
    @pk{ $source->primary_columns } = ();
    map +{ %{ $source->column_info($_) }, name => $_ },
      grep !exists $pk{$_}, $source->columns;
  }

  sub pk_cols {
    my $source = shift;
    map +{ %{ $source->column_info($_) }, name => $_ },
      $source->primary_columns;
  }

  sub names_of { my @cols = @_; map $_->{name}, @cols }

  sub function_body {
    my ( $name, $args, $body_parts ) = @_;
    my $arglist =
      join( ', ', map "_${\$_->{name}} ${\uc($_->{data_type})}", @$args );
    my $body = join( "\n", '', map "          $_;", @$body_parts );
    return strip tt q{
      CREATE OR REPLACE FUNCTION [% name %]
        ([% arglist %])
        RETURNS VOID AS $function$
        BEGIN
          [%- body %]
        END;
      $function$ LANGUAGE plpgsql;
    };
  }
}

BEGIN {

  sub arg_hash {
    my $source = shift;
    map +( $_ => \( argify $_) ), names_of body_cols $source;
  }

  sub rule_body {
    my ( $on, $to, $oldlist, $newlist ) = @_;
    my $arglist = join( ', ',
      ( qualify_with 'OLD', names_of @$oldlist ),
      ( qualify_with 'NEW', names_of @$newlist ),
    );
    $to = $to->name if blessed($to);
    return strip tt q{
      CREATE RULE _[% to %]_[% on %]_rule AS
        ON [% on | upper %] TO [% to %]
        DO INSTEAD (
          SELECT [% to %]_[% on %]([% arglist %])
        );
    };
  }
}

method root_table () {
  $self->parent_source
    ? $self->parent_source->root_table
    : $self->schema->source($self->raw_source_name)
}

method view_definition () {
  my $schema = $self->schema;
  confess "Can't generate view without connected schema, sorry"
    unless $schema && $schema->storage;
  my $sqla = $schema->storage->sql_maker;
  my $table = $self->schema->source($self->raw_source_name);
  my $super_view = $self->parent_source;
  my @all_parents = my @other_parents = @{$self->additional_parents||[]};
  push(@all_parents, $super_view) if defined($super_view);
  my @sources = ($table, @all_parents);
  my @body_cols = map body_cols($_), @sources;

  # Order body_cols to match the columns order.
  # Must match or you get typecast errors.
  my %body_cols = map { $_->{name} => $_ } @body_cols;
  @body_cols =
    map { $body_cols{$_} }
    grep { defined $body_cols{$_} }
    $self->columns;
  my @pk_cols = pk_cols $self;

  # Grab sequence from root table. Only works with one PK named id...
  # TBD: Fix this so it's more flexible.
  for my $pk_col (@pk_cols) {
    $self->columns_info->{ $pk_col->{name} }->{sequence} =
      $self->root_table->name . '_id_seq';
  }

  # SELECT statement

  my $am_root = !($super_view || @other_parents);

  my $select = $sqla->select(
    ($am_root
      ? ($table->name)
      : ([   # FROM _tbl _tbl
           { $table->name => $table->name },
           map {
             my $parent = $_;
             [ # JOIN view view
               { $parent->name => $parent->name },
               # ON _tbl.id = view.id
               { map +(qualify_with($parent, $_), qualify_with($table, $_)),
                   names_of @pk_cols }
             ]
           } @all_parents
         ])
      ),
    [ (qualify_with $table, names_of @pk_cols), names_of @body_cols ],
  ).';';

  my ($now, @next) = grep defined, $super_view, $table, @other_parents;

  # INSERT function

  # NOTE: this assumes a single PK col called id with a sequence somewhere
  # but nothing else -should- so fixing this should make everything work
  my $insert_func =
    function_body
      $self->name.'_insert',
      \@body_cols,
      [
        $sqla->insert( # INSERT INTO tbl/super_view (foo, ...) VALUES (_foo, ...)
          $now->name,
          { arg_hash $now },
        ),
        (map {
          $sqla->insert( # INSERT INTO parent (id, ...)
                         #   VALUES (currval('_root_tbl_id_seq'), ...)
            $_->name,
            {
              (arg_hash $_),
              id => \"currval('${\$self->root_table->name}_id_seq')",
            }
          )
        } @next)
      ];

  # note - similar to arg_hash but not quite enough to share code sanely
  my $pk_where = { # id = _id AND id2 = _id2 ...
    map +($_ => \"= ${\argify $_}"), names_of @pk_cols
  };

  # UPDATE function

  my $update_func =
    function_body
      $self->name.'_update',
      [ @pk_cols, @body_cols ],
      [ map $sqla->update(
          $_->name, # UPDATE foo
          { arg_hash $_ }, # SET a = _a
          $pk_where,
        ), @sources
      ];

  # DELETE function

  my $delete_func =
    function_body
      $self->name.'_delete',
      [ @pk_cols ],
      [ map $sqla->delete($_->name, $pk_where), @sources ];

  my @rules = (
    (rule_body insert => $self, [], \@body_cols),
    (rule_body update => $self, \@pk_cols, \@body_cols),
    (rule_body delete => $self, \@pk_cols, []),
  );
  return join("\n\n", $select, $insert_func, $update_func, $delete_func, @rules);
}

1;

__END__

=head1 NAME

DBIx::Class::ResultSource::MultipleTableInheritance
Use multiple tables to define your classes

=head1 NOTICE

This only works with PostgreSQL at the moment. It has been tested with
PostgreSQL 9.0, 9.1 beta, and 9.1.

There is one additional caveat: the "parent" result classes that you
defined with this resultsource must have one primary column and it must
be named "id."

=head1 SYNOPSIS

    {
        package Cafe::Result::Coffee;

        use strict;
        use warnings;
        use parent 'DBIx::Class::Core';
        use aliased 'DBIx::Class::ResultSource::MultipleTableInheritance'
            => 'MTI';

        __PACKAGE__->table_class(MTI);
        __PACKAGE__->table('coffee');
        __PACKAGE__->add_columns(
            "id", { data_type => "integer" },
            "flavor", {
                data_type => "text",
                default_value => "good" },
        );

        __PACKAGE__->set_primary_key("id");

        1;
    }

    {
        package Cafe::Result::Sumatra;

        use parent 'Cafe::Result::Coffee';

        __PACKAGE__->table('sumatra');

        __PACKAGE__->add_columns( "aroma",
            { data_type => "text" }
        );

        1;
    }

    ...

    my $schema = Cafe->connect($dsn,$user,$pass);

    my $cup = $schema->resultset('Sumatra');

    print STDERR Dwarn $cup->result_source->columns;

        "id"
        "flavor"
        "aroma"
        ..

Inherit from this package and you can make a resultset class from a view, but
that's more than a little bit misleading: the result is B<transparently
writable>.

This is accomplished through the use of stored procedures that map changes
written to the view to changes to the underlying concrete tables.

=head1 WHY?

In many applications, many classes are subclasses of others. Let's say you
have this schema:

    # Conceptual domain model

    class User {
        has id,
        has name,
        has password
    }

    class Investor {
        has id,
        has name,
        has password,
        has dollars
    }

That's redundant. Hold on a sec...

    class User {
        has id,
        has name,
        has password
    }

    class Investor extends User {
        has dollars
    }

Good idea, but how to put this into code?

One far-too common and absolutely horrendous solution is to have a "checkbox"
in your database: a nullable "investor" column, which entails a nullable
"dollars" column, in the user table.

    create table "user" (
        "id" integer not null primary key autoincrement,
        "name" text not null,
        "password" text not null,
        "investor" tinyint(1),
        "dollars" integer
    );

Let's not discuss that further.

A second, better, solution is to break out the two tables into user and
investor:

    create table "user" (
        "id" integer not null primary key autoincrement,
        "name" text not null,
        "password" text not null
    );

    create table "investor" (
        "id" integer not null references user("id"),
        "dollars" integer
    );

So that investor's PK is just an FK to the user. We can clearly see the class
hierarchy here, in which investor is a subclass of user. In DBIx::Class
applications, this second strategy looks like:

    my $user_rs = $schema->resultset('User');
    my $new_user = $user_rs->create(
        name => $args->{name},
        password => $args->{password},
    );

    ...

    my $new_investor = $schema->resultset('Investor')->create(
        id => $new_user->id,
        dollars => $args->{dollars},
    );

One can cope well with the second strategy, and it seems to be the most popular
smart choice.

=head1 HOW?

There is a third strategy implemented here. Make the database do more of the
work: hide the nasty bits so we don't have to handle them unless we really want
to. It'll save us some typing and it'll make for more expressive code. What if
we could do this:

    my $new_investor = $schema->resultset('Investor')->create(
        name => $args->{name},
        password => $args->{password},
        dollars => $args->{dollars},
    );

And have it Just Work? The user...

    {
        name => $args->{name},
        password => $args->{password},
    }

should be created behind the scenes, and the use of either user or investor
in your code should require no special handling. Deleting and updating
$new_investor should also delete or update the user row.

It does. User and investor are both views, their concrete tables abstracted
away behind a set of rules and triggers. You would expect the above DBIC
create statement to look like this in SQL:

    INSERT INTO investor ("name","password","dollars") VALUES (...);

But using MTI, it is really this:

    INSERT INTO _user_table ("username","password") VALUES (...);
    INSERT INTO _investor_table ("id","dollars") VALUES (currval('_user_table_id_seq',...) );

For deletes, the triggers fire in reverse, to preserve referential integrity
(foreign key constraints). For instance:

   my $investor = $schema->resultset('Investor')->find({id => $args->{id}});
   $investor->delete;

Becomes:

    DELETE FROM _investor_table WHERE ("id" = ?);
    DELETE FROM _user_table WHERE ("id" = ?);


=head1 METHODS

=over

=item new


MTI find the parents, if any, of your resultset class and adds them to the
list of parent_sources for the table.


=item add_additional_parents


Continuing with coffee:

    __PACKAGE__->result_source_instance->add_additional_parents(
        qw/
            MyApp::Schema::Result::Beverage
            MyApp::Schema::Result::Liquid
        /
    );

This just lets you manually add additional parents beyond the ones MTI finds.

=item add_additional_parent

    __PACKAGE__->result_source_instance->add_additional_parent(
            MyApp::Schema::Result::Beverage
    );

You can also add just one.

=item attach_additional_sources

MTI takes the parents' sources and relationships, creates a new
DBIx::Class::Table object from them, and registers this as a new, raw, source
in the schema, e.g.,

    use MyApp::Schema;

    print STDERR map { "$_\n" } MyApp::Schema->sources;

    # Coffee
    # Beverage
    # Liquid
    # Sumatra
    # Raw::Sumatra

Raw::Sumatra will be used to generate the view.

=item view_definition

This takes the raw table and generates the view (and stored procedures) you will use.

=back

=head1 AUTHOR

Matt S. Trout, E<lt>mst@shadowcatsystems.co.ukE<gt>

=head2 CONTRIBUTORS

Amiri Barksdale, E<lt>amiri@roosterpirates.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2011 the DBIx::Class::ResultSource::MultipleTableInheritance
L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBIx::Class>
L<DBIx::Class::ResultSource>

=cut

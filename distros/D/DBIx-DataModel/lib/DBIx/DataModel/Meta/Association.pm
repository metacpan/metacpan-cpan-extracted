package DBIx::DataModel::Meta::Association;
use strict;
use warnings;
use parent "DBIx::DataModel::Meta";
use DBIx::DataModel;
use DBIx::DataModel::Meta::Utils;

use Carp;
use Params::Validate qw/validate SCALAR ARRAYREF HASHREF OBJECT UNDEF/;
use List::MoreUtils  qw/pairwise/;
use Scalar::Util     qw/weaken dualvar looks_like_number/;
use Module::Load     qw/load/;
use POSIX            qw/LONG_MAX/;
use namespace::clean;

{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

# specification for parameters to new()
my $association_spec = {
  schema => {type => OBJECT, isa  => "DBIx::DataModel::Meta::Schema"},
  A      => {type => HASHREF},
  B      => {type => HASHREF},
  name   => {type => SCALAR, optional => 1}, # computed if absent
  kind   => {type => SCALAR,
             regex => qr/^(Association|Aggregation|Composition)$/},
};

# specification for sub-parameters 'A' and 'B'
my $association_end_spec = {
  table        => {type => OBJECT, 
                   isa  => 'DBIx::DataModel::Meta::Source::Table'},
  role         => {type => SCALAR|UNDEF, optional => 1},
  multiplicity => {type => SCALAR|ARRAYREF},    # if scalar : "$min..$max"
  join_cols    => {type => ARRAYREF,     optional => 1},
};

#----------------------------------------------------------------------
# PUBLIC METHODS
#----------------------------------------------------------------------

sub new {
  my $class = shift;

  my $self = validate(@_, $association_spec);

  # work on both association ends (A and  B)
  for my $letter (qw/A B/) {
    # parse parameters for this association end
    my @letter_params = %{$self->{$letter}};
    my $assoc_end = validate(@letter_params, $association_end_spec);

    croak "join_cols is present but empty"
      if $assoc_end->{join_cols} && !@{$assoc_end->{join_cols}};

    # transform multiplicity scalar into a pair [$min, $max]
    $class->_parse_multiplicity($assoc_end);

    $self->{$letter} = $assoc_end;
  }

  # set default association name
  my @names = map {$self->{$_}{role} || $self->{$_}{table}{name}} qw/A B/;
  $self->{name} ||= join "_", @names;

  # if many-to-many, needs special treatment
  my $install_method;
  if ($self->{A}{multiplicity}[1] > 1 && $self->{B}{multiplicity}[1] > 1) {
    $install_method = '_install_many_to_many';
  }

  # otherwise, treat as a regular association
  else {
    $install_method = '_install_path';

    # handle implicit column names
    if ($self->{A}{multiplicity}[1] > 1) { # n-to-1
      $self->{B}{join_cols} ||= $self->{B}{table}{primary_key};
      $self->{A}{join_cols} ||= $self->{B}{join_cols};
    }
    elsif ($self->{B}{multiplicity}[1] > 1) { # 1-to-n
      $self->{A}{join_cols} ||= $self->{A}{table}{primary_key};
      $self->{B}{join_cols} ||= $self->{A}{join_cols};
    }

    # check if we have the same number of columns on both sides
    @{$self->{A}{join_cols}} == @{$self->{B}{join_cols}}
      or croak "Association: numbers of columns do not match";
  }

  # instantiate
  bless $self, $class;

  # special checks for compositions
  $self->_check_composition if $self->{kind} eq 'Composition';

  # install methods from A to B and B to A, if role names are not empty
  $self->{A}{role} || $self->{B}{role}
    or croak "at least one side of the association must have a role name";
  $self->$install_method(qw/A B/) if $self->{B}{role};
  $self->$install_method(qw/B A/) if $self->{A}{role};

  # EXPERIMENTAL : no longer need association ends; all info is stored in Paths
  delete@{$self}{qw/A B/};

  # avoid circular reference
  weaken $self->{schema};

  return $self;
}


# accessor methods
DBIx::DataModel::Meta::Utils->define_readonly_accessors(
  __PACKAGE__, qw/schema name kind path_AB path_BA/,
);


#----------------------------------------------------------------------
# PRIVATE UTILITY METHODS
#----------------------------------------------------------------------

sub _parse_multiplicity {
  my ($class, $assoc_end) = @_;

  # nothing to do if already an arrayref
  return if ref $assoc_end->{multiplicity};

  # otherwise, parse the scalar
  $assoc_end->{multiplicity} =~ /^(?:             # optional part
                                     (\d+)        #   minimum 
                                     \s*\.\.\s*   #   followed by ".."
                                   )?             # end of optional part
                                   (\d+|\*|n)     # maximum
                                   $/x
    or croak "illegal multiplicity : $assoc_end->{multiplicity}";

  # multiplicity '*' is a shortcut for '0..*', and
  # multiplicity '1' is a shortcut for '1..1'.
  my $max_is_star = !looks_like_number($2);
  my $min = defined $1   ? $1             : ($max_is_star ? 0 : $2);
  my $max = $max_is_star ? dualvar(POSIX::LONG_MAX, '*') : $2;
  $assoc_end->{multiplicity} = [$min, $max];
}


sub _install_many_to_many {
  my ($self, $from, $to) = @_;

  # path must contain exactly 2 items (intermediate table + remote table)
  my $role = $self->{$to}{role};
  my @path = @{$self->{$to}{join_cols}};
  @path == 2
    or croak "many-to-many : should have exactly 2 roles";

  # define the method
  $self->{$from}{table}->define_navigation_method($role, @path);
}


sub _install_path {
  my ($self, $from, $to) = @_;

  # build the "ON" condition for SQL::Abstract::More
  my $from_cols = $self->{$from}{join_cols};
  my $to_cols   = $self->{$to}  {join_cols};
  my %condition = pairwise {$a => $b} @$from_cols, @$to_cols;

  # define path
  my $path_metaclass = $self->{schema}{path_metaclass};
  load $path_metaclass;
  my $path_name = $self->{$to}{role};
  $self->{"path_$from$to"} = $path_metaclass->new(
    name         => $path_name,
    from         => $self->{$from}{table},
    to           => $self->{$to}{table},
    on           => \%condition,
    multiplicity => $self->{$to}{multiplicity},
    association  => $self,
    direction    => "$from$to",
   );

  # if 1-to-many, define insertion method
  if ($self->{$to}{multiplicity}[1] > 1) {

    # build method parts
    my $method_name   = "insert_into_$path_name";
    my $to_table_name = $self->{$to}{table}{name};
    my $method_body = sub {
      my $source = shift; # remaining @_ contains refs to records for insert()
      ref($source) or croak "$method_name cannot be called as class method";

      # add join information into records that will be inserted
      foreach my $record (@_) {

        # if this is a scalar, it's no longer a record, but an arg to insert()
        last if !ref $record; # since args are at the end, we exit the loop

        # check that we won't overwrite existing data
	not (grep {exists $record->{$_}} @$to_cols) or
	  croak "args to $method_name should not contain values in @$to_cols";

        # shallow copy and insert values for the join
        $record = {%$record};
	@{$record}{@$to_cols} = @{$source}{@$from_cols};
      }

      return $source->schema->table($to_table_name)->insert(@_);
    };

    # define the method
    DBIx::DataModel::Meta::Utils->define_method(
      class => $self->{$from}{table}{class},
      name  => $method_name,
      body  => $method_body,
     );
  }
}

sub _check_composition {
  my $self = shift;

  # multiplicities must be 1-to-n
  $self->{A}{multiplicity}[1] == 1
    or croak "max multiplicity of first class in a composition must be 1";
  $self->{B}{multiplicity}[1] > 1
    or croak "max multiplicity of second class in a composition must be > 1";

  # check for conflicting compositions
  while (my ($name, $path) = each %{$self->{B}{table}{path} || {}}) {
    if ($path->association->kind eq 'Composition' && $path->direction eq 'BA'
        && ($path->multiplicity)[0] > 0) {
      croak "$self->{B}{table}{name} can't be a component "
          . "of $self->{A}{table}{name} "
          . "(already component of $path->{to}{name})";
    }
  }
}


1;

__END__

=head1 NAME

DBIx::DataModel::Meta::Association - meta-information about an association

=head1 SYNOPSIS

  # create the assoc.; best called through $meta_schema->define_association(..)
  my $association = new (
    schema => $meta_schema,
    A      => {
      table        => $meta_table_instance,
      role         => $role_name,         # optional
      multiplicity => $multiplicity_spec, # ex. "1..*"
      join_cols    => [$col1, ...]        # optional
    },
    B      => $B_association_end, # same structure as 'A'
    name   => $association_name, #optional
    kind   => $kind, # one of : Association, Aggregation, Composition
  );

  # example
  my $path = $association->path_AB;
  # 

=head1 DESCRIPTION

An instance of this class represents a UML association between
two instances of L<DBIx::DataModel::Meta::Source::Table>.

The association also creates instances of 
L<DBIx::DataModel::Meta::Path> for representing the 
directional paths between those sources.
Perl methods are created within the L<DBIx::DataModel::Meta::Path>
class, so Perl symbol tables are not touched by the present class.

=head1 PUBLIC METHODS

=head2 new

Constructor method. Normally this will be called indirectly
through 

  $meta_schema->define_association(%args)

because the L<DBIx::DataModel::Meta::Schema/define_association>
method automatically adds its own invocant (the C<$meta_schema>)
into C<%args>.

Named arguments to C<new()> are :

=over

=item schema

An instance of L<DBIx::DataModel::Meta::Schema>.

=item A

A description of the first I<association end>, which is composed of

=over

=item table

An instance of L<DBIx::DataModel::Meta::Source::Table>.

=item role

The role name of that source within the association.
A Perl method of the same name will be defined in the
remote source (the other end of the association).
Besides, the role name is also used when building
joins through 

  $schema->join(qw/FirstTable role1 role2 .../)

One of the role names in the association can be
anonymous (undef), but not both. If anonymous, there
will be no Perl method and no possibility to join in that
direction, so it defines a unidirectional association.

=item multiplicity

The multiplicity specification, i.e. the minimum and maximum 
number of occurrences of that association end, for any given
instance of the other end (if not clear, see UML textbooks).

The multiplicity can be expressed either as an 
arrayref C<< [$min, $max] >>, or as a string C<"$min..$max">.
The C<$max> can be C<'*'> or C<'n'>, which is interpreted
as the maximum integer value. If expressed as a string,
a mere C<'*'> is interpreted as C<'0..*'>, and a mere
C<'1'> is interpreted as C<'1..1'>.

=item join_cols

An arrayref of columns that participate in the database join,
for this side of the association. The full database join will
be built by creating a C<LEFT|INNER JOIN ... ON ..> clause in
which the left-hand and right-hand sides of the C<ON> subclause
come from the C<join_cols> of both association ends.

This argument is optional: if absent, it will be filled
by default by taking the primary key of the table with minimum
multiplicity 1, for both sides of the association.

If the association is many-to-many (i.e. if the maximum
multiplicity is greater than 1 on both sides), then 
C<join_cols> takes a special meaning : it no longer
represents database columns, but rather represents 
two role names (in the sense just defined above) to follow
for reaching the remote end of the association.
Therefore C<join_cols> must contain exactly 2 items in that case :
the path to the intermediate table, and the path from the intermediate
table to the remote end. Here is again the example from 
L<DBIx::DataModel/SYNOPSIS> : 

  My::Schema->define_association(
    kind => 'Association',
    A    => {
      table        => My::Schema::Department->metadm,
      role         => 'departments',
      multiplicity => '*',
      join_cols    => [qw/activities department/],
    },
    B    => {
      table        => My::Schema::Employee->metadm,
      role         => 'employees',
      multiplicity => '*',
      join_cols    => [qw/activities employee/],
    },
  );

=back

=item B

A description of the second I<association end>, following exactly the 
same principles as for the C<'A'> end.

=item name

Optional name for the association (otherwise an implicit name
will be built by default from the concatenation of the role names).

=item kind

A string describing the association kind, i.e. one of :
C<Association>, C<Aggregation> or C<Composition>.

Special behaviour is attached to the kind C<Composition> :

=over

=item *

the multiplicity must be 1-to-n

=item * 

the C<'B'> end of the association (the "component" part) must not 
be component of another association (it can only be component of one
single composite table).

=item *

this association can be used for auto-expanding the composite object
(i.e. automatically fetching all component parts from the database)
-- see L<DBIx::DataModel::Source/expand>
and L<DBIx::DataModel::Source/auto_expand>

=item *

this association can be used for cascaded inserts like

  $source->insert({
    column1 => $val1,
    ...
    $component_name1 => [{$sub_object1}, ...],
    ...
   })

see L<DBIx::DataModel::Source/insert>


=back

=back


=head2 schema

returns the C<$meta_schema> to which this association belongs

=head2 A

hashref decribing the C<'A'> end of the association

=head2 B

hashref decribing the C<'B'> end of the association

=head2 path_AB

An instance of L<DBIx::DataModel::Meta::Path> for the path 
from C<A> to C<B> within this association (if any).

=head2 path_BA

An instance of L<DBIx::DataModel::Meta::Path> for the path 
from C<B> to C<A> within this association (if any).

=head2 name

The association name.

=head2 kind

The association kind.

=head1 PRIVATE METHODS

=head2 _parse_multiplicity

For multiplicities given as strings, parse into an arrayref 
C<< [$min, $max] >>, including the rules for shorthands
C<'*'> and C<'1'>, as described above.

=head2 _install_path

Implementation for regular associations (1-to-n or 1-to-1): 
create a L<DBIx::DataModel::Meta::Path> object from one side
to the other.

=head2 _install_many_to_many

Implementation for many-to-many associations : 
just create navigation methods from one side
to the other, relying on pre-existing paths through the 
intermediate table.

=head2 _check_composition

Checks that special conditions on compositions (described above)
are fullfilled.

=cut


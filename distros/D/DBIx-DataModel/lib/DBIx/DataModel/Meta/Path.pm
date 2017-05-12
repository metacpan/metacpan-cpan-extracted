package DBIx::DataModel::Meta::Path;
use strict;
use warnings;
use parent "DBIx::DataModel::Meta";
use DBIx::DataModel;
use DBIx::DataModel::Meta::Utils;

use Scalar::Util         qw/looks_like_number weaken/;
use Params::Validate     qw/validate SCALAR HASHREF ARRAYREF OBJECT/;
use Carp;
use namespace::clean;

{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

my $path_spec = {
  name         => {type => SCALAR},
  from         => {isa  => 'DBIx::DataModel::Meta::Source::Table'},
  to           => {isa  => 'DBIx::DataModel::Meta::Source::Table'},
  on           => {type => HASHREF}, # join condition
  multiplicity => {type => ARRAYREF},
  association  => {type => OBJECT,
                   isa  => "DBIx::DataModel::Meta::Association"},
  direction    => {type => SCALAR, regex => qr/^(AB|BA)$/},
};

sub new {
  my $class = shift;

  # parse arguments and create $self
  my $self = validate(@_, $path_spec);

  my $path = $self->{name};
  weaken $self->{$_} for qw/from to association/;

  # add this path into the 'from' metaclass
  not $self->{from}{path}{$path}
    or croak "$self->{from}{class} already has a path '$path'";
  $self->{from}{path}{$path} = $self;
  push @{$self->{from}{components}}, $path
    if $self->{association}{kind} eq 'Composition';

  # install a navigation method into the 'from' table class
  my @navigation_args = ($self->{name},  # method name
                         $self->{name}); # path to follow
  push @navigation_args, {-result_as => "firstrow"}
    if $self->{multiplicity}[1] == 1;
  $self->{from}->define_navigation_method(@navigation_args);

  bless $self, $class;
}

DBIx::DataModel::Meta::Utils->define_readonly_accessors(
  __PACKAGE__, keys %$path_spec
);


sub opposite {
  my $self = shift;
  my $opposite_direction = reverse $self->direction;
  my $opposite_path      = "path_".$opposite_direction;
  return $self->association->$opposite_path;
}


1;


__END__

=head1 NAME

DBIx::DataModel::Meta::Path - meta-information about a path

=head1 SYNOPSIS

  # create the path; best called through $assoc->_install_path(...)
  my $path = new (
    name         => $role_name,
    from         => $source_meta_table,
    to           => $destination_meta_table,
    on           => \%condition,         # in SQL::Abstract::More format
    multiplicity => [$min, $max],
    association  => $association,
    direction    => $direction,          # either 'AB' or 'BA'
  );

=head1 DESCRIPTION

This class is closely related to L<DBIx::DataModel::Meta::Association>.
A I<path> corresponds to one possible database join between
two tables.

=head1 PUBLIC METHODS

=head2 new

Constructor method. Normally this will be called indirectly
through 

  $association->_install_path(%args)

because the L<DBIx::DataModel::Meta::Association/_install_path>
method automatically adds its own invocant (the C<$association>)
into C<%args>.

Named arguments to C<new()> are :

=over

=item name

The name of this path (must be unique within the source table).
That name is used for defining
a Perl method in the class associated to the source table,
and for interpreting multi-steps joins in calls like

  $schema->join(qw/FirstTable role1 role2 .../)

=item from

The L<DBIx::DataModel::Meta::Source::Table> instance
which is the source for this path.

=item to

The L<DBIx::DataModel::Meta::Source::Table> instance
which is the target for this path.

=item on

A hashref that describes the database join condition : the keys
are names of columns for the left-hand side, and values
are names of columns for the right-hand side.
For example 

  on => {foreign_1 => 'primary_1', foreign_2 => 'primary_2'}

will generate SQL clauses of shape

  .. JOIN ON <left>.foreign_1 = <right>.primary_1
         AND <left>.foreign_2 = <right>.primary_2

=item multiplicity

An arrayref C<< [$min, $max] >>; 
see explanations in L<DBIx::DataModel::Meta::Association>.

=item association

The association to which this path belongs.

=item direction

A string that describes the direction of this path within
the association : must be either C<'AB'> or C<'BA'>.

=back

=head2 name

Name of this path

=head2 from

Source of this path 
(an instance of L<DBIx::DataModel::Meta::Source::Table>).

=head2 to

Target of this path 
(an instance of L<DBIx::DataModel::Meta::Source::Table>).

=head2 on

Copy of the hash for the join condition

=head2 multiplicity

Array C<($min, $max)> describing the multiplicity.

=head2 association

Instance of L<DBIx::DataModel::Meta::Association> to which this
path belongs.

=head2 direction

Direction of the path within the association; 
a string containing either C<'AB'> or C<'BA'>.

=head2 opposite

Returns the path object representing the opposite direction.


=cut



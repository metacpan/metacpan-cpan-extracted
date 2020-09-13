# This class exists to represent a relationship between two ::Source's within
# the Sims. It will have a link back to two ::Source's.

package DBIx::Class::Sims::Relationship;

use 5.010_001;

use strictures 2;

use DDP;

use DBIx::Class::Sims::Util qw( reftype );

# Requires the following attributes:
# * source
# * name
# * info
# * constraints
sub new {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->initialize;
  return $self;
}

# Possible TODO:
# 1. Identify source / target and parent / child

sub initialize {
  my $self = shift;

  return;
}

sub name   { shift->{name} }
sub source { shift->{source} }

sub constraints { shift->{constraints} }

sub full_name {
  my $self = shift;
  return $self->source->name . '->' . $self->name;
}

# Yes, this method breaks ::Runner's encapsulation, but this (should) be
# temporary until someone else sets this for ::Relationship or maybe ::Source
# builds its relationships after ::Runner has built all ::Source objects first.
sub target {
  my $self = shift;
  return $self->source->runner->{sources}{$self->short_fk_source};
}

sub is_fk {
  my $self = shift;
  return exists $self->{info}{attrs}{is_foreign_key_constraint};
}
sub short_fk_source {
  my $self = shift;
  (my $x = $self->{info}{source}) =~ s/.*:://;
  return $x;
}

sub is_multi_col {
  my $self = shift;
  keys %{$self->cond(@_)} > 1;
}

sub cond {
  my $self = shift;
  my $x = $self->{info}{cond};
  if (reftype($x) eq 'CODE') {
    $x = $x->({
      foreign_alias => 'foreign',
      self_alias => 'self',
    });
  }
  if (reftype($x) ne 'HASH') {
    die "cond is not a HASH\n" . np($self->{info});
  }
  return $x;
}

sub self_fk_cols {
  my $self = shift;
  return map {/^self\.(.*)/; $1} values %{$self->cond(@_)};
}
sub self_fk_col  {
  my $self = shift;
  return ($self->self_fk_cols(@_))[0];
}
sub foreign_fk_cols {
  my $self = shift;
  return map {/^foreign\.(.*)/; $1} keys %{$self->cond(@_)};
}
sub foreign_fk_col  {
  my $self = shift;
  return ($self->foreign_fk_cols(@_))[0];
}

sub foreign_class {
  my $self = shift;
  return $self->{info}{class};
}

sub is_single_accessor {
  my $self = shift;
  return $self->{info}{attrs}{accessor} eq 'single';
}
sub is_multi_accessor {
  return ! $_[0]->is_single_accessor;
}

1;
__END__

=head1 NAME

DBIx::Class::Sims::Relationship - The Sims wrapper of a L<DBIx::Class::Relationship/>

=head1 PURPOSE

This object wraps a L<DBIx::Class::Relationship/> and provides a set of useful
methods around it.

=head1 METHODS

=head2 name()

Returns the name of this relationship.

=head2 source()

Returns the L<DBIx::Class::Sims::Source/> this relationships is defined in.

=head2 target()

Returns the L<DBIx::Class::Sims::Source/> this relationships connects to.

=head2 is_fk()

Returns a boolean indicating if this is a parent relationship or not.

=head1 AUTHOR

Rob Kinyon <rob.kinyon@gmail.com>

=head1 LICENSE

Copyright (c) 2013 Rob Kinyon. All Rights Reserved.
This is free software, you may use it and distribute it under the same terms
as Perl itself.

=cut

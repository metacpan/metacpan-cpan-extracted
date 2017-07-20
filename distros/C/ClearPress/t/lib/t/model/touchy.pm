package t::model::touchy;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(fields());

sub fields {
  return qw(id_touchy created last_modified);
}

sub create {
  my $self               = shift;
  $self->{created}       = $self->isodate;
  $self->{last_modified} = $self->isodate;
  return $self->SUPER::create;
}

sub update {
  my $self               = shift;
  $self->{last_modified} = $self->isodate;
  return $self->SUPER::update;
}

1;

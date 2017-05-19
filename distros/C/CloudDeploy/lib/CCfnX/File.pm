package CCfnX::File {
  use Moose;
  has mode => (isa => 'Str', is => 'ro', required => 1);
  has owner => (isa => 'Str', is => 'ro', required => 1);
  has group => (isa => 'Str', is => 'ro', required => 1);
  has content => (isa => 'CCfnX::UserData', is => 'ro', required => 1);

  sub as_hashref {
    my $self = shift;
    return { mode => $self->mode, owner => $self->owner, group => $self->group, content => $self->content->as_hashref_joins };
  }
}

1;

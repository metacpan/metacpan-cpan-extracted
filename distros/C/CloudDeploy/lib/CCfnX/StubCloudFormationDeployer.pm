package CCfnX::StubCloudFormationDeployer {
  use Moose::Role;
  has region  => (is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub { $_[0]->origin->params->region });

  around get_params_from_origin => sub {
    my ($orig, $self) = @_;

    return { } if (not defined $self->origin);
    return $self->$orig();
  };
}

1;

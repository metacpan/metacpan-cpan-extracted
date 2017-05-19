package CCfnX::ConsoleDeployer {
  use Moose::Role;

  after deploy => sub {
    my $self = shift;
    print $self->origin->as_json;
  }
}

1;

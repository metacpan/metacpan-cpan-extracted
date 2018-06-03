package MyRegistry;

use Moo;
extends 'Data::MuFormX::Registry';

sub config {
  'NewNodes' => sub {
    my ($self) = @_;
    return +{
      example1 => 1,
      example2 => 1,
    };
  },
}

1;

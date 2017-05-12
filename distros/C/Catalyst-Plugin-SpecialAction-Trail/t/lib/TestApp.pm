package TestApp;

use Moose;
use namespace::autoclean;

extends 'Catalyst';

with 'ActionLogging';

sub trail_retval {
  my ($c) = @_;

  my $params = $c->req->params;

  (my $controller = caller) =~ s/^.*::Controller:://;

  return exists $params->{$controller} ? $params->{$controller} : 1;
}

__PACKAGE__->setup();

__PACKAGE__->meta->make_immutable;

1;

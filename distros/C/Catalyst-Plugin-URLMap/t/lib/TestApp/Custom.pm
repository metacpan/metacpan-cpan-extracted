package TestApp::Custom;

use strict;
use warnings;

use parent qw/Plack::Component/;

sub call {
  my ($self, $env) = @_;
  return [ 200,
    ['Content-Type' => 'text/plain'], ['custom']];
}

1;

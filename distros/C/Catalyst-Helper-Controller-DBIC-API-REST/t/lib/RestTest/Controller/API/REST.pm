package RestTest::Controller::API::REST;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

sub rest_base : Chained('/api/api_base') PathPart('rest') CaptureArgs(0) {
    my ($self, $c) = @_;
}

1;

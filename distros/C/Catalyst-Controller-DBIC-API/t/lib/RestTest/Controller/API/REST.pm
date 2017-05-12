package RestTest::Controller::API::REST;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

sub rest_base : Chained('/api/api_base') PathPart('rest') CaptureArgs(0) {
    my ( $self, $c ) = @_;

}

sub end :Private {
	my ( $self, $c ) = @_;

}

1;

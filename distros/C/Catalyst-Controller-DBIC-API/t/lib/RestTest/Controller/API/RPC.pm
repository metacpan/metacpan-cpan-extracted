package RestTest::Controller::API::RPC;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

sub rpc_base : Chained('/api/api_base') PathPart('rpc') CaptureArgs(0) {
    my ( $self, $c ) = @_;

}

sub end :Private {
	my ( $self, $c ) = @_;

}

1;

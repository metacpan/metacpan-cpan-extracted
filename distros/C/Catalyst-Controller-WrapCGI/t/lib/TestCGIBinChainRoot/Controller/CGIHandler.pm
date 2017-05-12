package TestCGIBinChainRoot::Controller::CGIHandler;

use parent 'Catalyst::Controller::CGIBin';

sub chain_root : Chained('/') PathPart('cgi') CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->req->body_parameters->{from_chain} = 'from_chain';
}

1;

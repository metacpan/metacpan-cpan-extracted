package TestApp::C::Begin;
use warnings;
use strict;

use base qw/Catalyst::Base/;

sub begin : Private {
    my ($self, $c) = @_;
    $c->forward('/i_die');
}

sub action : Regex('^begin_dies') {
    my ($self, $c) = @_;
    $c->res->header('X-Test' => 'not run');
}

1;

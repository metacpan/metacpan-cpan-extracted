package TestApp::C::Auto;
use warnings;
use strict;

use base qw/Catalyst::Base/;

sub auto : Private {
    my ($self, $c) = @_;
    $c->forward('/i_die');
}

sub action : Regex('^auto_dies') {
    my ($self, $c) = @_;
    $c->res->header('X-Test' => 'not run');
}

1;

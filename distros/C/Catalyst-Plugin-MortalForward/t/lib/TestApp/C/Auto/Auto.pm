package TestApp::C::Auto::Auto;
use warnings;
use strict;

use base qw/Catalyst::Base/;

sub auto : Private {
    my ($self, $c) = @_;
    1;
}

sub hello : Local {
    my ($self, $c) = @_;
    $c->res->header('X-Test' => 'not run');
}

1;

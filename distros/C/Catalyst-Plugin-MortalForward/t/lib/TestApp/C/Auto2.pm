package TestApp::C::Auto2;
use warnings;
use strict;

use base qw/Catalyst::Base/;

sub auto : Private {
    my ($self, $c) = @_;
    die "Die die die"; 
}

sub action : Regex('^auto_dies_directly') {
    my ($self, $c) = @_;
    $c->res->header('X-Test' => 'not run');
}

1;

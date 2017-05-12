package TestApp::C::Begin2;
use warnings;
use strict;

use base qw/Catalyst::Base/;

sub begin : Private {
    my ($self, $c) = @_;
    die "Die die die"; 
}

sub auto : Private {
    my ($self, $c) = @_;

}

sub action : Regex('^begin_dies_directly') {
    my ($self, $c) = @_;
    $c->res->header('X-Test' => 'not run');
}

sub end : Private {
    my ($self, $c) = @_;
}

1;

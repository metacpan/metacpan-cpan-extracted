package TestApp::C::Elsewhere;
use strict;

use base qw< Catalyst::Base >;

sub test : Private {
    my ($self, $c) = @_;    
    die 'I die too, sorry';
}

1;

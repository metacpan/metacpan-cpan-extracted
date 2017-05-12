package TestApp::Logic::Boin;

use strict;
use warnings;


sub new {
    my $class = shift;
    my $self = shift ;
    
    bless $self, $class;
    return $self;
}

sub boin {
    my $self = shift;
    'boin';
}


1;

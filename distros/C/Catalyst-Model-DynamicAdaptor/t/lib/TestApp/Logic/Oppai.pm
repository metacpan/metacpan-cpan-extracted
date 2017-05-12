package TestApp::Logic::Oppai;

use strict;
use warnings;


sub new {
    my $class = shift;
    my $self = shift ;
    
    bless $self, $class;
    return $self;
}

sub porn {
    my $self = shift;
    return 'no porn! ' . $self->{who} .'!';
}


1;

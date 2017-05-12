package Ttitle;
use strict;
use warnings;

use Class::Trait qw(base);

sub title { 'Mgr.' }

sub name  {        
    my $this = shift;   
    $this->title . ' '. $this->SUPER::name;
}

1;

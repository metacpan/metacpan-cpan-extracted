use 5.020;

use strict;
use warnings;
package Acme::MyFirstModule::MALLEN;

# ABSTRACT: turns baubles into trinkets

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    return $self;
}

sub ping {
    my $self = shift;

    say "You have to use perl 5.20 to run this.";

    1;
}

'beer';

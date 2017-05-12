package Catalyst::Controller::LeakTracker::Test::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller::LeakTracker';

__PACKAGE__->config->{namespace} = '';

sub leak_something : Local {
    my ( $self, $c ) = @_;

    my $obj = bless {}, "LeakedClass";
    $obj->{self} = $obj;
}

1;

package Author::Daemon::Enviroment::Absorb;

use v5.28;
use warnings;
use strict;
use experimental 'signatures';

sub new ( $class, $env, @args ) {
    my $self = {};
    bless $self, $class;
    return $self;
}

1;

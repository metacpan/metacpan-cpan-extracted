package DNS::Unbound::X::BadDebugFD;

use strict;
use warnings;

use parent qw( DNS::Unbound::X::Base );

sub _new {
    my ($class, $fd, $errno_num) = @_;

    local $! = $errno_num;

    return $class->SUPER::_new( "Bad file descriptor ($fd: $!, $errno_num) given to debugout()", fd => $fd, error => $! );
}

1;


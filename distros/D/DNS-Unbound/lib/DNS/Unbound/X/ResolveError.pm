package DNS::Unbound::X::ResolveError;

use strict;
use warnings;

use parent qw( DNS::Unbound::X::Base );

sub _new {
    my ($class, @args_kv) = @_;

    return $class->SUPER::_new( 'DNS query resolution failure', @args_kv );
}

1;

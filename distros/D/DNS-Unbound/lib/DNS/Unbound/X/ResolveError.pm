package DNS::Unbound::X::ResolveError;

use strict;
use warnings;

use parent qw( DNS::Unbound::X::Unbound );

=encoding utf-8

=head1 NAME

DNS::Unbound::X::ResolveError

=head1 DESCRIPTION

This class subclasses L<DNS::Unbound::X::Unbound> and represents a
libunbound DNS resolution failure.

=cut

sub _new {
    my ($class, %args_kv) = @_;

    return $class->SUPER::_new( "DNS query resolution failure ($args_kv{'string'}", %args_kv );
}

1;

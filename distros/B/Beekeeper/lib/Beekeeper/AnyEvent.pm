package Beekeeper::AnyEvent;

use strict;
use warnings;

our $VERSION = '0.10';

use AnyEvent;
use AnyEvent::Socket;


USE_PERL_BACKEND: {

    # Prefer AnyEvent perl backend over default EV, as it is fast enough
    # and it does not ignore exceptions thrown from within callbacks

    $ENV{'PERL_ANYEVENT_MODEL'} ||= 'Perl' unless $AnyEvent::MODEL;
}

UNTAINT_IP_ADDR: {

    no strict 'refs';
    no warnings 'redefine';

    # Addresses resolved by AnyEvent::DNS are tainted, causing an "Insecure
    # dependency in connect" error when running with taint mode enabled.
    # These addresses can be blindly untainted before being passed to parse_ipv4
    # and parse_ipv6 because these functions validate addresses properly

    my $parse_ipv4 = \&{'AnyEvent::Socket::parse_ipv4'};
    *{'AnyEvent::Socket::parse_ipv4'} = sub ($) {
        ($_[0]) = $_[0] =~ m/(.*)/s; # untaint addr
        $parse_ipv4->(@_);
    };

    my $parse_ipv6 = \&{'AnyEvent::Socket::parse_ipv6'};
    *{'AnyEvent::Socket::parse_ipv6'} = sub ($) {
        ($_[0]) = $_[0] =~ m/(.*)/s; # untaint addr
        $parse_ipv6->(@_);
    };
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::AnyEvent - AnyEvent customizations

=head1 VERSION

Version 0.09

=head1 DESCRIPTION

This module alters the default behavior of AnyEvent as follows:

=over

=item *

Prefer the pure perl backend over default EV, as it is fast enough and
it does not ignore exceptions thrown from within callbacks.

=item *

Addresses resolved by AnyEvent::DNS are tainted, causing an "Insecure
dependency in connect" error as Beekeeper runs with taint mode enabled.
This module untaints resolved addresses, which can be done safely because
AnyEvent validates these addresses properly before using them.

=back

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2023 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut

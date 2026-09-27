package Alien::ngtcp2;

use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Alien::ngtcp2 - Find or build the ngtcp2 QUIC transport library

=head1 SYNOPSIS

    use Alien::ngtcp2;

    my $cflags = Alien::ngtcp2->cflags;
    my $libs   = Alien::ngtcp2->libs;

=head1 DESCRIPTION

Alien::ngtcp2 provides the C<libngtcp2> native library for Perl distributions
that need to compile or link against ngtcp2.

If a suitable system installation of C<libngtcp2> is available through
pkg-config, it is used. Otherwise Alien::ngtcp2 downloads and builds a private
copy of ngtcp2.

The fallback build contains the core C<libngtcp2> transport library only. It
does not provide ngtcp2 TLS crypto helper libraries, HTTP/3, or an event loop.

The fallback build is static so that XS consumers can link the native library
into their extension without depending on a private shared library remaining
at the same path after installation.

=head1 UPSTREAM VERSION

This release accepts system installations of C<libngtcp2> version 1.25.0 or
newer. Its fallback source build uses ngtcp2 1.25.0.

=head1 PERL VERSION

Alien::ngtcp2 requires Perl 5.20 or newer.

=head1 METHODS

Alien::ngtcp2 inherits the standard L<Alien::Base> interface, including
C<cflags>, C<libs>, C<dynamic_libs>, C<install_type>, and C<version>.

=head1 SEE ALSO

L<Alien::Base>

L<https://github.com/ngtcp2/ngtcp2>

=head1 AUTHOR

Joshua S. Day

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Joshua S. Day.

This is free software, licensed under:

    The MIT (X11) License

The full license text is included in the LICENSE file.

=cut

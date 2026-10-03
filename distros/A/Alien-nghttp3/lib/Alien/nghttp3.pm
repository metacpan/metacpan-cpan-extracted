package Alien::nghttp3;

use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Alien::nghttp3 - Find or build libnghttp3

=head1 SYNOPSIS

    use Alien::nghttp3;

    my $cflags  = Alien::nghttp3->cflags;
    my $libs    = Alien::nghttp3->libs;
    my $version = Alien::nghttp3->version;

=head1 DESCRIPTION

Alien::nghttp3 makes the native libnghttp3 library available to Perl modules.

nghttp3 is a C library for HTTP/3 and QPACK. It does not provide QUIC
transport.

Alien::nghttp3 only supplies the native library. It does not choose a QUIC
implementation, event loop, TLS library, or Perl HTTP framework.

=head1 INSTALLATION

Alien::nghttp3 first looks for libnghttp3 1.18.0 or newer on the system.

If a suitable system library is found, it is used.

If not, Alien::nghttp3 builds the vendored nghttp3 1.18.0 source included in
this distribution. The fallback build does not need to download nghttp3 from
the network.

The fallback builds only the static libnghttp3 library.

=head1 METHODS

Alien::nghttp3 inherits the normal methods from L<Alien::Base>.

=head2 cflags

Returns compiler flags for libnghttp3.

=head2 libs

Returns linker flags for libnghttp3.

=head2 version

Returns the libnghttp3 version.

=head1 SCOPE

Alien::nghttp3 does not provide a Perl HTTP/3 API, QUIC transport, TLS, UDP
socket handling, an event loop, or a web framework.

It does not depend on Net::QUIC, Linux::Event, ngtcp2, or another QUIC
implementation.

A higher-level Perl module can combine libnghttp3 with any suitable QUIC
transport.

=head1 REQUIREMENTS

Alien::nghttp3 requires Perl 5.20 or newer and Alien::Build 2.84 or newer.

A C11 compiler is needed when the vendored library must be built.

The vendored fallback source is nghttp3 1.18.0.

=head1 SEE ALSO

L<Alien::Base>

L<https://github.com/ngtcp2/nghttp3>

=head1 AUTHOR

Joshua S. Day

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Joshua S. Day.

This is free software, licensed under:

    The MIT (X11) License

=cut

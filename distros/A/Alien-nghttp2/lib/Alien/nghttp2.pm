package Alien::nghttp2;

use strict;
use warnings;
use base qw(Alien::Base);

our $VERSION = '0.001';

1;

__END__

=head1 NAME

Alien::nghttp2 - Find or build the nghttp2 HTTP/2 C library

=head1 SYNOPSIS

    use Alien::nghttp2;
    use ExtUtils::MakeMaker;

    WriteMakefile(
        ...
        CONFIGURE_REQUIRES => {
            'Alien::nghttp2' => '0',
        },
        LIBS   => [ Alien::nghttp2->libs ],
        CCFLAGS => Alien::nghttp2->cflags,
    );

Or with L<Alien::Build::MM>:

    use Alien::Build::MM;
    my $abmm = Alien::Build::MM->new;

    WriteMakefile($abmm->mm_args(
        ...
        BUILD_REQUIRES => {
            'Alien::nghttp2' => '0',
        },
    ));

=head1 DESCRIPTION

This L<Alien> module provides the nghttp2 HTTP/2 C library. It will
either detect the library installed on your system, or download and
build it from source.

nghttp2 is an implementation of the HTTP/2 protocol (RFC 9113) and
HPACK header compression (RFC 7541), used by curl, Apache httpd,
Firefox, and many other projects.

=head1 METHODS

All methods are inherited from L<Alien::Base>:

=head2 cflags

    my $cflags = Alien::nghttp2->cflags;

Returns compiler flags needed to compile against nghttp2.

=head2 libs

    my $libs = Alien::nghttp2->libs;

Returns linker flags needed to link against nghttp2.

=head2 dynamic_libs

    my @libs = Alien::nghttp2->dynamic_libs;

Returns list of dynamic library paths.

=head2 install_type

    my $type = Alien::nghttp2->install_type;

Returns 'system' or 'share' depending on how nghttp2 was installed.

=head1 SEE ALSO

L<Alien::Base>, L<Alien::Build>, L<Net::HTTP2::nghttp2>

L<https://nghttp2.org/> - nghttp2 project homepage

=head1 AUTHOR

Your Name <your@email.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

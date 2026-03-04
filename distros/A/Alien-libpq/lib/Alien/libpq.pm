package Alien::libpq;
use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.04';

sub _add_rpath {
    my ($self, $libs) = @_;
    if ($^O eq 'darwin' && $self->install_type eq 'share' && $libs =~ /-L(\S+)/) {
        return "-Wl,-rpath,$1 $libs";
    }
    return $libs;
}

# On macOS share installs, the dylib uses @rpath in its install_name.
# Inject -rpath so the loader can find it at runtime.
sub libs        { $_[0]->_add_rpath($_[0]->SUPER::libs) }
sub libs_static { $_[0]->_add_rpath($_[0]->SUPER::libs_static) }

1;

__END__

=head1 NAME

Alien::libpq - Find or build libpq PostgreSQL client library

=head1 SYNOPSIS

    use Alien::libpq;
    use ExtUtils::MakeMaker;

    WriteMakefile(
        ...
        CONFIGURE_REQUIRES => {
            'Alien::libpq' => 0,
        },
        CCFLAGS => Alien::libpq->cflags,
        LIBS    => Alien::libpq->libs,
    );

=head1 DESCRIPTION

This module provides the libpq C library (PostgreSQL client library).
It will use the system library if available, or download and build
from source if necessary.

The source build is configured without OpenSSL, readline, zlib, and ICU
for a minimal footprint.  SSL/TLS connections require system-provided libpq.

=head1 METHODS

=head2 libs

=head2 libs_static

On macOS with a share install, appends C<-Wl,-rpath> so the dynamic
linker can find C<libpq.dylib> after Alien::Build DESTDIR relocation.

All other methods are inherited from L<Alien::Base>.

=head1 SEE ALSO

L<Alien::Base>, L<https://www.postgresql.org/docs/current/libpq.html>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

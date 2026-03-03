package Alien::libpq;
use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.02';

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

=head1 METHODS

All methods are inherited from L<Alien::Base>.

=head1 SEE ALSO

L<Alien::Base>, L<https://www.postgresql.org/docs/current/libpq.html>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

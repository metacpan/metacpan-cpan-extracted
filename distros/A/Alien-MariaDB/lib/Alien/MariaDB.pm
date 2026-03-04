package Alien::MariaDB;
use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.01';

sub _add_rpath {
    my ($self, $libs) = @_;
    if ($^O eq 'darwin' && $self->install_type eq 'share') {
        my @rpath = map { "-Wl,-rpath,$_" } $libs =~ /-L(\S+)/g;
        return "@rpath $libs" if @rpath;
    }
    return $libs;
}

sub libs { $_[0]->_add_rpath($_[0]->SUPER::libs) }

1;

__END__

=head1 NAME

Alien::MariaDB - Find or build libmariadb client library

=head1 SYNOPSIS

    use Alien::MariaDB;
    use ExtUtils::MakeMaker;

    WriteMakefile(
        ...
        CONFIGURE_REQUIRES => {
            'Alien::MariaDB' => 0,
        },
        CCFLAGS => Alien::MariaDB->cflags,
        LIBS    => Alien::MariaDB->libs,
    );

=head1 DESCRIPTION

This module provides the MariaDB Connector/C client library (libmariadb).
It will use the system library if available, or download and build
from source if necessary.

=head1 METHODS

Inherits all methods from L<Alien::Base>.

=head2 libs

Overridden to add C<-Wl,-rpath> flags on macOS share installs so the
dynamic linker can find the bundled libmariadb at runtime.

=head1 SEE ALSO

L<Alien::Base>, L<https://mariadb.com/kb/en/mariadb-connector-c/>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

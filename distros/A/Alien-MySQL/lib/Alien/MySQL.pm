package Alien::MySQL;
use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.01';

sub _add_rpath {
    my ($self, $libs) = @_;
    if ($^O ne 'MSWin32' && $self->install_type eq 'share') {
        my @rpath = map { "-Wl,-rpath,$_" } $libs =~ /-L(\S+)/g;
        return "@rpath $libs" if @rpath;
    }
    return $libs;
}

sub libs        { $_[0]->_add_rpath($_[0]->SUPER::libs) }
sub libs_static { $_[0]->_add_rpath($_[0]->SUPER::libs_static) }

1;

__END__

=head1 NAME

Alien::MySQL - Find or build libmysqlclient client library

=head1 SYNOPSIS

    use Alien::MySQL;
    use ExtUtils::MakeMaker;

    WriteMakefile(
        ...
        CONFIGURE_REQUIRES => {
            'Alien::MySQL' => 0,
        },
        CCFLAGS => Alien::MySQL->cflags,
        LIBS    => Alien::MySQL->libs,
    );

=head1 DESCRIPTION

This module provides the MySQL C client library (libmysqlclient).
It will use the system library if available, or download and build
from source if necessary.

=head1 INSTALLING DBD::mysql

For C<share> installs, C<Alien::MySQL> bundles C<mysql_config> in
C<< Alien::MySQL->bin_dir >>. Prepend it to C<PATH> when installing
L<DBD::mysql>:

    PATH="$(perl -MAlien::MySQL -e 'print join(":", Alien::MySQL->bin_dir, $ENV{PATH})')" \
        cpanm DBD::mysql

Alternatively, point C<DBD_MYSQL_CONFIG> directly to the bundled
C<mysql_config> (on C<share> installs):

    DBD_MYSQL_CONFIG="$(perl -MAlien::MySQL -e 'print Alien::MySQL->dist_dir')/bin/mysql_config" \
        cpanm DBD::mysql

Note: L<DBD::mysql>'s F<Makefile.PL> validates C<--libs> with
L<Devel::CheckLib>, which rejects C<-Wl,-rpath> flags returned by
C<< Alien::MySQL->libs >> on C<share> installs; using C<mysql_config>
via C<PATH> or C<DBD_MYSQL_CONFIG> avoids this issue.

=head1 METHODS

Inherits all methods from L<Alien::Base>.

=head2 libs, libs_static

Overridden to add C<-Wl,-rpath> flags on share installs so the dynamic
linker can find the bundled libmysqlclient at runtime.

=head1 SEE ALSO

L<Alien::Base>, L<https://dev.mysql.com/doc/c-api/en/>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

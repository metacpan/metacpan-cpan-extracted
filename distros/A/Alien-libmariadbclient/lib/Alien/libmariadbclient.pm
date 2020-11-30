package Alien::libmariadbclient;

use 5.006;
use strict;
use warnings;
use File::Spec;

use parent 'Alien::Base';

sub bin_path {
    my $class = shift;
    return File::Spec->catdir($class->dist_dir, 'bin');
}

sub mariadb_config_bin {
    my $class    = shift;
    my $bin_path = $class->bin_path;
    return File::Spec->catfile($bin_path, 'mariadb_config');
}

=head1 NAME

Alien::libmariadbclient - libmariadbclient, with alien

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Alien::libmariadbclient;

    Alien::libmariadbclient->libs;
    Alien::libmariadbclient->libs_static;
    Alien::libmariadbclient->cflags;

=head1 DESCRIPTION

C<Alien::libmariadbclient> is an C<Alien> interface to L<libmariadbclient|...>.

=head1 AUTHOR

B Fraser, C<< <fraserbn at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-libmariadbclient at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-libmariadbclient>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by B Fraser.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Alien::libmariadbclient

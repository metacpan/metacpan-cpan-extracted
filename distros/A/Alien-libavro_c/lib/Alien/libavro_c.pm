package Alien::libavro_c;

use 5.006;
use strict;
use warnings;

use parent 'Alien::Base';

=head1 NAME

Alien::libavro_c - libavro_c, with alien

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use Alien::libavro_c;

    Alien::libavro_c->libs;
    Alien::libavro_c->libs_static;
    Alien::libavro_c->cflags;

=head1 DESCRIPTION

C<Alien::libavro_c> is an C<Alien> interface to C<libavro-c>.

=head1 AUTHOR

B Fraser, C<< <fraserbn at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-libavro_c at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-libavro_c>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by B Fraser.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Alien::libavro_c

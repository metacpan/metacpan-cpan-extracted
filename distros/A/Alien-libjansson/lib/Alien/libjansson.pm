package Alien::libjansson;

use 5.006;
use strict;
use warnings;

use parent 'Alien::Base';

=head1 NAME

Alien::libjansson - libjansson, with alien

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Alien::libjansson;

    Alien::libjansson->libs;
    Alien::libjansson->libs_static;
    Alien::libjansson->cflags;

=head1 DESCRIPTION

C<Alien::libjansson> is an C<Alien> interface to L<libjansson|https://digip.org/jansson/>,
a JSON encoder/decoder in C.

=head1 AUTHOR

B Fraser, C<< <fraserbn at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-libjansson at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-libjansson>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by B Fraser.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Alien::libjansson

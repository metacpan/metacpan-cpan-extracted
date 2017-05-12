package Alien::Libgcrypt;

our $VERSION = '0.02';

use 5.006;
use strict;
use warnings;

use parent 'Alien::Base';

1;

=head1 NAME

Alien::Libgcrypt - Download, configure, build and install libgcrypt.

=head1 SYNOPSIS

    use Alien::Libgcrypt;
    my $cflags = Alien::Libgcrypt->cflags;
    ...

=head1 SEE ALSO

L<Alien::Base>, L<Alien::Libssh2>.

=head1 SUPPORT

For support go to the GitHub repository at
L<https://github.com/salva/p5-Alien-Libgcrypt>.

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2016 by Salvador Fandiño
(sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut


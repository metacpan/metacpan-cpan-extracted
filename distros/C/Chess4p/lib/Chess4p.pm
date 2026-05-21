=head1 NAME

Chess4p, a library for chess related functionality.

=head1 SYNOPSIS

The functionality is split into these modules:


=over 4

=item L<Chess4p::Perft>

Perft calculation.

=item L<Chess4p::Pgn::Reader>

Read PGN files.

=item L<Chess4p::Board>

Essential board position functionality.

=item L<Chess4p::Move>

Small and simple Move class.

=item L<Chess4p::Common>

Constants needed by other modules.

=back



=head1 DESCRIPTION

Features include legal move generation, perft testing,
UCI move input/output, SAN move input/output and PGN parsing.

Planned features include EPD's, support for the Fischer Random variant,
binary encoding of position and move.

For details, see the docs for the different sub-modules.


=head1 LIMITATIONS

Only 64-bit systems are supported.


=head1 SEE ALSO

The code is hosted here:
https://codeberg.org/ejner/chess4p


=head1 AUTHOR

Ejner Borgbjerg <ejner@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2026 Ejner Borgbjerg. All rights reserved. This module is
Free Software. It may be modified and redistributed under the same terms as
Perl itself.

=cut
package Chess4p;

use v5.36;

use Config;
use Carp;

BEGIN {
    # only 64 bit systems are supported, because bitboard operations would need special code otherwise.
    croak "64-bit Perl is required (ptrsize = 8). Current perl is not supported.\n" unless $Config{ptrsize} && $Config{ptrsize} == 8;
}

use lib '.';

our $VERSION = '0.0.4';

use Chess4p::Move;
use Chess4p::Board;

1;

=head1 NAME

Chess4p, a library for chess related functionality.

=head1 SYNOPSIS

use Chess4p;

use Chess4p::Common qw(...);

$board = Chess4p::Board->fromFen();

$board->push_move(Chess4p::Move->new(E2, E4);

$board->fen();

$board->ascii();

$board->pop_move();

...

=head1 DESCRIPTION

Features include legal move generation, perft testing, UCI move input/output.

Planned features include SAN move input/output and PGN parsing.

Only 64-bit systems are supported.

=head1 SEE ALSO

=over 4

=item L<Chess4p::Board>

=item L<Chess4p::Move>

=item L<Chess4p::Common>

=back

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

our $VERSION = '0.0.2';

use Chess4p::Common;
use Chess4p::Move;
use Chess4p::Board;

1;

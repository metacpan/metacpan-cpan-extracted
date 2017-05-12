=head1 NAME

Chess - a framework for writing chess programs with Perl

=head1 SYNOPSIS

use Chess;

$game = Chess::Game->new();
$board = $game->get_board();
...

=head1 DESCRIPTION

This package is provided as shorthand for L<Chess::Game>. It provided no
functionality not contained within the other packages in this module.

=head1 SEE ALSO

=over 4

=item L<Chess::Game>

=item L<Chess::Board>

=item L<Chess::Piece>

=item L<Chess::Game::MoveList>

=item L<Chess::Game::MoveListEntry>

=back

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2007 Brian Richardson. All rights reserved. This module is
Free Software. It may be modified and redistributed under the same terms as
Perl itself.

=cut
package Chess;

our $VERSION = '0.6.2';

use Chess::Game;

1;

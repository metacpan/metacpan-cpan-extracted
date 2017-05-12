#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Chess::Rep::Coverage') }

my $g = eval { Chess::Rep::Coverage->new() };
print $@ if $@;
isa_ok $g, 'Chess::Rep::Coverage';

my $fen = Chess::Rep::FEN_STANDARD; # Default starting position
diag($fen);
my $c = $g->coverage();
isa_ok $c, 'HASH';
is $c->{H8}{occupant}, 'r', 'H8 occupant';
is $c->{H8}{piece}, 16, 'H8 piece';
is $c->{H8}{color}, 0, 'H8 color';
is $c->{H8}{index}, 119, 'H8 index';
ok $c->{H8}{move}[0] == 103 || $c->{H8}{move}[0] == 118, 'H8 move';
ok $c->{H8}{protects}[0] == 103 || $c->{H8}{protects}[0] == 118, 'H8 protects';

#$fen = 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'; # after the move 1. e4
#$fen = 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2'; # after 1. ... c5
#$fen = 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2'; # after 2. Nf3

$fen = '8/8/8/3pr3/4P3/8/8/8 w ---- - 0 1'; # 3 pieces, w/b pawn mutual threat, black rook threat
diag($fen);
$g->set_from_fen($fen);
$c = $g->coverage();
ok $c->{D5}{move}[0] == 51 || $c->{D5}{move}[0] == 52, 'D5 move';
ok $c->{D5}{threatens}[0] == 52, 'D5 threatens';
ok $c->{D5}{is_protected_by}[0] == 68, 'D5 is_protected_by';
ok $c->{D5}{is_threatened_by}[0] == 52, 'D5 is_threatened_by';
ok $c->{E4}{move}[0] == 67, 'E4 move';
ok $c->{E4}{threatens}[0] == 67, 'E4 threatens';
ok not(@{ $c->{E4}{is_protected_by} }), 'E4 is_protected_by';
ok $c->{E4}{is_threatened_by}[0] == 67 || $c->{E4}{is_threatened_by}[0] == 68, 'E4 is_threatened_by';
#ok $c->{E5}{move}, [qw(69 70 71 84 100 116 52 67)], 'E5 move';
ok $c->{E5}{protects}[0] == 67, 'E5 protects';
ok $c->{E5}{threatens}[0] == 52, 'E5 threatens';
ok not(@{ $c->{E5}{is_protected_by} }), 'E5 is_protected_by';
ok not(@{ $c->{E5}{is_threatened_by} }), 'E5 is_threatened_by';

my $w = q{     A     B     C     D     E     F     G     H
  +-----+-----+-----+-----+-----+-----+-----+-----+
8 |     |     |     |     | 0:1 |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
7 |     |     |     |     | 0:1 |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
6 |     |     |     |     | 0:1 |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
5 |     |     |     | 1/1 | 0/0 | 0:1 | 0:1 | 0:1 |
  +-----+-----+-----+-----+-----+-----+-----+-----+
4 |     |     | 0:1 |     | 0/2 |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
3 |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
2 |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
1 |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
};
my $b = $g->board();
is $b, $w, 'board';
#use Data::Dumper;warn Data::Dumper->new([$c])->Indent(1)->Terse(1)->Sortkeys(1)->Dump;

#$fen = '8/8/8/8/8/8/8/8 w ---- - 0 1'; # No pieces
#$fen = '8/8/8/3p4/8/8/8/8 w ---- - 0 1'; # 1 black piece
#$fen = '8/8/8/8/4P3/8/8/8 w ---- - 0 1'; # 1 white piece
#$fen = 'pppppppp/pppppppp/pppppppp/pppppppp/pppppppp/pppppppp/pppppppp/pppppppp b ---- - 0 1';
#$fen = 'r6R/8/8/8/8/8/8/8 w ---- - 0 1'; # Opposing rooks
#$fen = 'r7/P7/8/8/8/8/8/8 w ---- - 0 1'; # black rook threatens white pawn
#$fen = '1p6/P7/8/8/8/8/8/8 w ---- - 0 1'; # black pawn vs white pawn
#$fen = '8/8/8/3p4/4P3/8/8/8 w ---- - 0 1'; # 2 pieces, w/b pawn mutual threat
#$fen = '8/8/8/3Pr3/8/8/8/8 w ---- - 0 1'; # 2 pieces, single black threat
#$fen = '8/8/8/3pr3/8/8/8/8 w ---- - 0 1'; # 2 pieces, single black protection
#$fen = 'rp6/P7/8/8/8/8/8/8 w ---- - 0 1'; # 3 pieces, w/b pawn mutual threat, black rook threat

$fen = '8/8/3p4/4k3/8/8/8/8 w ---- - 0 1'; # Black pawn & king - king protects but pawn doesn't
diag($fen);
$g->set_from_fen($fen);
$c = $g->coverage();

$w = q{     A     B     C     D     E     F     G     H
  +-----+-----+-----+-----+-----+-----+-----+-----+
8 |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
7 |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
6 |     |     |     | 1/0 | 0:1 | 0:1 |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
5 |     |     |     | 0:2 | 0/0 | 0:1 |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
4 |     |     |     | 0:1 | 0:1 | 0:1 |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
3 |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
2 |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
1 |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+
};
$b = $g->board();
is $b, $w, 'board';

done_testing();

#!/usr/bin/perl -T

use Test::Simple tests => 6;
use Chess::Rep;
use Data::Dumper;


my $pos = Chess::Rep->new();

# Disambiguation rules

$pos->set_from_fen('k7/3q1q2/8/8/8/8/8/K7 b - -');
my $h = $pos->go_move('d7e6');

ok($h->{'san'} eq 'Qde6', 'Disambiguation file only');

$pos->set_from_fen('k7/3q4/8/3q4/8/8/8/K7 b - -');
$h = $pos->go_move('d7e6');

ok($h->{'san'} eq 'Q7e6', 'Disambiguation rank only');

$pos->set_from_fen('k7/3q1q2/8/3q4/8/8/8/K7 b - -');
$h = $pos->go_move('d7e6');

ok($h->{'san'} eq 'Qd7e6', 'Disambiguation file+rank');

$pos->set_from_fen('k7/3qq3/8/8/8/8/8/K7 b - -');
$h = $pos->go_move('d7e6');

ok($h->{'san'} eq 'Qde6', 'Disambiguation file gets priority');

# When a pawn makes a capture, the file from which the pawn departed is used
# in place of a piece initial

$pos->set_from_fen('k7/8/8/3p4/4P3/8/8/K7 b - -');
$h = $pos->go_move('d5e4');

ok($h->{'san'} eq 'dxe4', 'Pawn capturing');

$pos->set_from_fen('r1q1r2k/6pp/pp6/2pQp3/3B4/6N1/PPP3PP/3R1RK1 b - -');
$h = $pos->go_move('c5d4');

ok($h->{'san'} eq 'cxd4', 'Pawn capturing(2)');

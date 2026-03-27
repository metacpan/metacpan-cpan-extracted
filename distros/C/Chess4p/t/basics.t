# -*- mode: cperl -*-

use v5.36;

use Test::More;

use utf8;

use Config;

plan skip_all => 'Only 64 bit systems are supported.'  unless $Config{ptrsize} && $Config{ptrsize} == 8;


require Chess4p;

use Chess4p::Common qw(FILE_A FILE_B FILE_C FILE_D
                     FILE_E FILE_F FILE_G FILE_H
                     RANK_1 RANK_2 RANK_3 RANK_4
                     RANK_5 RANK_6 RANK_7 RANK_8
                     A1 B1 C1 D1 E1 F1 G1 H1
                     A2 B2 C2 D2 E2 F2 G2 H2
                     A3 B3 C3 D3 E3 F3 G3 H3
                     A4 B4 C4 D4 E4 F4 G4 H4
                     A5 B5 C5 D5 E5 F5 G5 H5
                     A6 B6 C6 D6 E6 F6 G6 H6
                     A7 B7 C7 D7 E7 F7 G7 H7
                     A8 B8 C8 D8 E8 F8 G8 H8
                     EMPTY WP WN WB WR WQ WK
                     BP BN BB BR BQ BK
                     %square_names
                     %square_numbers
                   );


is(Chess4p::Board::_square_file(A1), FILE_A, 'a1 is on the a-file');
is(Chess4p::Board::_square_file(B1), FILE_B, 'b1 is on the b-file');
is(Chess4p::Board::_square_file(H1), FILE_H, 'h1 is on the h-file');
is(Chess4p::Board::_square_file(H8), FILE_H, 'h8 is on the h-file');

is(Chess4p::Board::_square_rank(A1), RANK_1, 'a1 is on the 1st rank');
is(Chess4p::Board::_square_rank(A8), RANK_8, 'a8 is on the 8th rank');
is(Chess4p::Board::_square_rank(E3), RANK_3, 'e3 is on the 3rd rank');
is(Chess4p::Board::_square_rank(H1), RANK_1, 'h1 is on the 1st rank');

is(Chess4p::Board::_square_distance(A1, A2), 1, 'A1 is 1 square from A2');
is(Chess4p::Board::_square_distance(A1, A8), 7, 'A1 is 7 squares from A8');

is(Chess4p::Board::_square_mirror(A1), A8, 'A1 mirrors in A8');
is(Chess4p::Board::_square_mirror(A8), A1, 'A8 mirrors in A1');
is(Chess4p::Board::_square_mirror(H1), H8, 'H1 mirrors in H8');
is(Chess4p::Board::_square_mirror(H8), H1, 'H8 mirrors in H1');


my $expected =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".  
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".  
  "1 1 1 1 1 1 1 1";

my $bb = 0 | 0b11111111;

is(Chess4p::Board::_print_bb($bb), $expected, 'bitboard written as string');


$expected =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".  
  ". . . . . . . .\n".
  ". . . . . . . .\n".  
  "1 1 1 1 1 1 1 1\n".
  ". . . . . . . .";

$bb = Chess4p::Board::_shift_up($bb);
is(Chess4p::Board::_print_bb($bb), $expected, 'bitboard shifted up');

$expected =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".  
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".  
  "1 1 1 1 1 1 1 1";

is(Chess4p::Board::_print_bb(Chess4p::Board::_shift_down($bb)), $expected, 'bitboard shifted down');


$expected =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . 1 . 1 . .\n".  
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .";  

$bb = Chess4p::Board::_step_attacks(E4, [7, 9]);
is(Chess4p::Board::_print_bb($bb), $expected, 'bitboard for squares attacked by white Pe4');


$expected =
  "1 1 1 1 1 1 1 1\n".
  "1 . . . . . . 1\n".
  "1 . . . . . . 1\n".
  "1 . . . . . . 1\n".  
  "1 . . . . . . 1\n".
  "1 . . . . . . 1\n".
  "1 . . . . . . 1\n".
  "1 1 1 1 1 1 1 1";  

$bb = Chess4p::Board::_edges(E4);
is(Chess4p::Board::_print_bb($bb), $expected, 'edges from E4');


$expected =
  "1 1 1 1 1 1 1 1\n".
  "1 . . . . . . 1\n".
  "1 . . . . . . 1\n".
  "1 . . . . . . 1\n".  
  "1 . . . . . . 1\n".
  "1 . . . . . . 1\n".
  "1 . . . . . . 1\n".
  "1 . . . . . . 1";  


$bb = Chess4p::Board::_edges(E1);
is(Chess4p::Board::_print_bb($bb), $expected, 'edges from E1');



$expected =
  "1 1 1 1 1 1 1 1\n".
  ". . . . . . . 1\n".
  ". . . . . . . 1\n".
  ". . . . . . . 1\n".  
  ". . . . . . . 1\n".
  ". . . . . . . 1\n".
  ". . . . . . . 1\n".
  "1 1 1 1 1 1 1 1";  


$bb = Chess4p::Board::_edges(A4);
is(Chess4p::Board::_print_bb($bb), $expected, 'edges from A4');



$expected =
  "1 1 1 1 1 1 1 1\n".
  ". . . . . . . 1\n".
  ". . . . . . . 1\n".
  ". . . . . . . 1\n".  
  ". . . . . . . 1\n".
  ". . . . . . . 1\n".
  ". . . . . . . 1\n".
  ". . . . . . . 1";  


$bb = Chess4p::Board::_edges(A1);
is(Chess4p::Board::_print_bb($bb), $expected, 'edges from A1');


$bb = Chess4p::Board::_make_bb(A1, A2);
$expected =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".  
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  "1 . . . . . . .\n".
  "1 . . . . . . .";  
is(Chess4p::Board::_print_bb($bb), $expected, 'bitboard of A1, A2');


my $str;
my $iter = Chess4p::Board::_carry_rippler_iter($bb);
while (defined(my $s = $iter->())) {
    $str .= sprintf ("%016x\n", $s);
}

is($str, "0000000000000000\n0000000000000001\n0000000000000100\n0000000000000101\n", 'iterated subsets of {A1, A2}');


my ($BB_FILE_MASKS, $BB_FILE_ATTACKS) = Chess4p::Board::_attack_table([-8, 8]);

is(@$BB_FILE_MASKS, 64, '64 bitboards in file-masks');
is($$BB_FILE_MASKS[0],  Chess4p::Board::_make_bb(A2, A3, A4, A5, A6, A7), 'File mask A2-A7');
is($$BB_FILE_MASKS[1],  Chess4p::Board::_make_bb(B2, B3, B4, B5, B6, B7), 'File mask B2-B7');
is($$BB_FILE_MASKS[2],  Chess4p::Board::_make_bb(C2, C3, C4, C5, C6, C7), 'File mask C2-C7');
is($$BB_FILE_MASKS[7],  Chess4p::Board::_make_bb(H2, H3, H4, H5, H6, H7), 'File mask H2-H7');
is($$BB_FILE_MASKS[8],  Chess4p::Board::_make_bb(A3, A4, A5, A6, A7), 'File mask A3-A7');
is($$BB_FILE_MASKS[15], Chess4p::Board::_make_bb(H3, H4, H5, H6, H7), 'File mask H3-H7');
is($$BB_FILE_MASKS[16], Chess4p::Board::_make_bb(A2, A4, A5, A6, A7), 'File mask A2-A7 minus A3');
is($$BB_FILE_MASKS[23], Chess4p::Board::_make_bb(H2, H4, H5, H6, H7), 'File mask H2-H7 minus H3');
is($$BB_FILE_MASKS[24], Chess4p::Board::_make_bb(A2, A3, A5, A6, A7), 'File mask A2-A7 minus A4');
is($$BB_FILE_MASKS[31], Chess4p::Board::_make_bb(H2, H3, H5, H6, H7), 'File mask H2-H7 minus H4');
is($$BB_FILE_MASKS[32], Chess4p::Board::_make_bb(A2, A3, A4, A6, A7), 'File mask A2-A7 minus A5');
is($$BB_FILE_MASKS[39], Chess4p::Board::_make_bb(H2, H3, H4, H6, H7), 'File mask H2-H7 minus H5');
is($$BB_FILE_MASKS[40], Chess4p::Board::_make_bb(A2, A3, A4, A5, A7), 'File mask A2-A7 minus A6');
is($$BB_FILE_MASKS[47], Chess4p::Board::_make_bb(H2, H3, H4, H5, H7), 'File mask H2-H7 minus H6');
is($$BB_FILE_MASKS[48], Chess4p::Board::_make_bb(A2, A3, A4, A5, A6), 'File mask A2-A6');
is($$BB_FILE_MASKS[55], Chess4p::Board::_make_bb(H2, H3, H4, H5, H6), 'File mask H2-H6');
is($$BB_FILE_MASKS[56], $$BB_FILE_MASKS[0], 'same');
is($$BB_FILE_MASKS[57], $$BB_FILE_MASKS[1], 'same');
is($$BB_FILE_MASKS[58], $$BB_FILE_MASKS[2], 'same');
is($$BB_FILE_MASKS[59], $$BB_FILE_MASKS[3], 'same');
is($$BB_FILE_MASKS[60], $$BB_FILE_MASKS[4], 'same');
is($$BB_FILE_MASKS[61], $$BB_FILE_MASKS[5], 'same');
is($$BB_FILE_MASKS[62], $$BB_FILE_MASKS[6], 'same');
is($$BB_FILE_MASKS[63], $$BB_FILE_MASKS[7], 'same');

is(@$BB_FILE_ATTACKS, 64, '64 hash references in file-attacks');
my $href = $$BB_FILE_ATTACKS[0];

my $count = keys %$href;
is($count, 64, '64 keys in the hash');

is($href->{0}, Chess4p::Board::_make_bb(A2, A3, A4, A5, A6, A7, A8), '');
is($href->{Chess4p::Board::_make_bb(A2)}, Chess4p::Board::_make_bb(A2), '');


my $BB_RAYS = Chess4p::Board::_rays(); # 64 x 64 bitboards

is(@$BB_RAYS, 64, '64 arrays of arrays');

my $aref = $$BB_RAYS[0];
is(@$aref, 64, '64 arrays');
my $expected_values = "0, 255, 255, 255, 255, 255, 255, 255, 72340172838076673, 9241421688590303745, 0, 0, 0, 0, 0, 0, 72340172838076673, 0, 9241421688590303745, 0, 0, 0, 0, 0, 72340172838076673, 0, 0, 9241421688590303745, 0, 0, 0, 0, 72340172838076673, 0, 0, 0, 9241421688590303745, 0, 0, 0, 72340172838076673, 0, 0, 0, 0, 9241421688590303745, 0, 0, 72340172838076673, 0, 0, 0, 0, 0, 9241421688590303745, 0, 72340172838076673, 0, 0, 0, 0, 0, 0, 9241421688590303745";
is(join (', ', @$aref), $expected_values, 'BB_RAYS[0]');

$aref = $$BB_RAYS[1];
is(@$aref, 64, '64 arrays');
$expected_values = "255, 0, 255, 255, 255, 255, 255, 255, 258, 144680345676153346, 36099303471055874, 0, 0, 0, 0, 0, 0, 144680345676153346, 0, 36099303471055874, 0, 0, 0, 0, 0, 144680345676153346, 0, 0, 36099303471055874, 0, 0, 0, 0, 144680345676153346, 0, 0, 0, 36099303471055874, 0, 0, 0, 144680345676153346, 0, 0, 0, 0, 36099303471055874, 0, 0, 144680345676153346, 0, 0, 0, 0, 0, 36099303471055874, 0, 144680345676153346, 0, 0, 0, 0, 0, 0";
is(join (', ', @$aref), $expected_values, 'BB_RAYS[1]');

$aref = $$BB_RAYS[2];
is(@$aref, 64, '64 arrays');
$expected_values = "255, 255, 0, 255, 255, 255, 255, 255, 0, 66052, 289360691352306692, 141012904183812, 0, 0, 0, 0, 66052, 0, 289360691352306692, 0, 141012904183812, 0, 0, 0, 0, 0, 289360691352306692, 0, 0, 141012904183812, 0, 0, 0, 0, 289360691352306692, 0, 0, 0, 141012904183812, 0, 0, 0, 289360691352306692, 0, 0, 0, 0, 141012904183812, 0, 0, 289360691352306692, 0, 0, 0, 0, 0, 0, 0, 289360691352306692, 0, 0, 0, 0, 0";
is(join (', ', @$aref), $expected_values, 'BB_RAYS[2]');

$aref = $$BB_RAYS[3];
is(@$aref, 64, '64 arrays');
$expected_values = "255, 255, 255, 0, 255, 255, 255, 255, 0, 0, 16909320, 578721382704613384, 550831656968, 0, 0, 0, 0, 16909320, 0, 578721382704613384, 0, 550831656968, 0, 0, 16909320, 0, 0, 578721382704613384, 0, 0, 550831656968, 0, 0, 0, 0, 578721382704613384, 0, 0, 0, 550831656968, 0, 0, 0, 578721382704613384, 0, 0, 0, 0, 0, 0, 0, 578721382704613384, 0, 0, 0, 0, 0, 0, 0, 578721382704613384, 0, 0, 0, 0";
is(join (', ', @$aref), $expected_values, 'BB_RAYS[3]');

## ...

$aref = $$BB_RAYS[63];
is(@$aref, 64, '64 arrays');
$expected_values = "9241421688590303745, 0, 0, 0, 0, 0, 0, 9259542123273814144, 0, 9241421688590303745, 0, 0, 0, 0, 0, 9259542123273814144, 0, 0, 9241421688590303745, 0, 0, 0, 0, 9259542123273814144, 0, 0, 0, 9241421688590303745, 0, 0, 0, 9259542123273814144, 0, 0, 0, 0, 9241421688590303745, 0, 0, 9259542123273814144, 0, 0, 0, 0, 0, 9241421688590303745, 0, 9259542123273814144, 0, 0, 0, 0, 0, 0, 9241421688590303745, 9259542123273814144, 18374686479671623680, 18374686479671623680, 18374686479671623680, 18374686479671623680, 18374686479671623680, 18374686479671623680, 18374686479671623680, 0";
is(join (', ', @$aref), $expected_values, 'BB_RAYS[63]');


is(Chess4p::Board::_between(A1, H8), Chess4p::Board::_make_bb(B2, C3, D4, E5, F6, G7), 'between A1 and H8');
is(Chess4p::Board::_between(H8, A1), Chess4p::Board::_make_bb(B2, C3, D4, E5, F6, G7), 'between H8 and A1');
is(Chess4p::Board::_between(A1, A8), Chess4p::Board::_make_bb(A2, A3, A4, A5, A6, A7), 'between A1 and A8');
is(Chess4p::Board::_between(A1, A1), Chess4p::Board::_make_bb(), 'between A1 and A1');
is(Chess4p::Board::_between(A1, A2), Chess4p::Board::_make_bb(), 'between A1 and A2');
is(Chess4p::Board::_between(A1, A3), Chess4p::Board::_make_bb(A2), 'between A1 and A3');
is(Chess4p::Board::_between(A1, C2), Chess4p::Board::_make_bb(), 'between A1 and C2');


is(Chess4p::Board::_msb(0), -1, 'msb(0)');
is(Chess4p::Board::_msb(1),  0, 'msb(1)');
is(Chess4p::Board::_msb(0b100101), 5, 'msb(0b100101)');
is(Chess4p::Board::_msb(0b111111), 5, 'msb(0b111111)');

is(Chess4p::Board::_lsb(0b100101), 0, 'lsb(0b100101)');
is(Chess4p::Board::_lsb(0b100100), 2, 'lsb(0b100100)');
is(Chess4p::Board::_lsb(0b100000), 5, 'lsb(0b100000)');


my $a1_h8_bb =
  ". . . . . . . 1\n".
  ". . . . . . 1 .\n".
  ". . . . . 1 . .\n".
  ". . . . 1 . . .\n".
  ". . . 1 . . . .\n".
  ". . 1 . . . . .\n".
  ". 1 . . . . . .\n".
  "1 . . . . . . .";

my $a1_a8_bb =
  "1 . . . . . . .\n".
  "1 . . . . . . .\n".
  "1 . . . . . . .\n".
  "1 . . . . . . .\n".
  "1 . . . . . . .\n".
  "1 . . . . . . .\n".
  "1 . . . . . . .\n".
  "1 . . . . . . .";

my $empty_bb =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .";

is(Chess4p::Board::_print_bb(Chess4p::Board::_ray(A1, H8)), $a1_h8_bb, 'Ray from A1 to H8');
is(Chess4p::Board::_print_bb(Chess4p::Board::_ray(A1, G7)), $a1_h8_bb, 'Ray from A1 to G7');
is(Chess4p::Board::_print_bb(Chess4p::Board::_ray(A1, D4)), $a1_h8_bb, 'Ray from A1 to D4');
is(Chess4p::Board::_print_bb(Chess4p::Board::_ray(A1, B2)), $a1_h8_bb, 'Ray from A1 to B2');
is(Chess4p::Board::_print_bb(Chess4p::Board::_ray(A1, A1)), $empty_bb, 'Ray from A1 to A1');

is(Chess4p::Board::_print_bb(Chess4p::Board::_ray(A1, A8)), $a1_a8_bb, 'Ray from A1 to A8');
is(Chess4p::Board::_print_bb(Chess4p::Board::_ray(A1, A4)), $a1_a8_bb, 'Ray from A1 to A4');


# *** mirroring

$bb = Chess4p::Board::_flip_vertical(Chess4p::Board::_make_bb(A2, H2));
is(Chess4p::Board::_make_bb(A7, H7), $bb, 'A2, H2 flipped vertically is A7, H7');





done_testing;

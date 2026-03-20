# -*- mode: cperl -*-
package Chess4p::Common;

use v5.36;

use Exporter 'import';

our @EXPORT_OK = qw(
    EMPTY WP WN WB WR WQ WK
    BP BN BB BR BQ BK

    A1 B1 C1 D1 E1 F1 G1 H1
    A2 B2 C2 D2 E2 F2 G2 H2
    A3 B3 C3 D3 E3 F3 G3 H3
    A4 B4 C4 D4 E4 F4 G4 H4
    A5 B5 C5 D5 E5 F5 G5 H5
    A6 B6 C6 D6 E6 F6 G6 H6
    A7 B7 C7 D7 E7 F7 G7 H7
    A8 B8 C8 D8 E8 F8 G8 H8

    FILE_A FILE_B FILE_C FILE_D
    FILE_E FILE_F FILE_G FILE_H

    RANK_1 RANK_2 RANK_3 RANK_4
    RANK_5 RANK_6 RANK_7 RANK_8

    %square_names
    %square_numbers
);

use constant {
    EMPTY => 0,
    WP => 1, WN => 2, WB => 3, WR => 4,  WQ => 5,  WK => 6,
    BP => 7, BN => 8, BB => 9, BR => 10, BQ => 11, BK => 12,

    A1 => 0,  B1 => 1,  C1 => 2,  D1 => 3,  E1 => 4,  F1 => 5,  G1 => 6,  H1 => 7,
    A2 => 8,  B2 => 9,  C2 => 10, D2 => 11, E2 => 12, F2 => 13, G2 => 14, H2 => 15,
    A3 => 16, B3 => 17, C3 => 18, D3 => 19, E3 => 20, F3 => 21, G3 => 22, H3 => 23,
    A4 => 24, B4 => 25, C4 => 26, D4 => 27, E4 => 28, F4 => 29, G4 => 30, H4 => 31,
    A5 => 32, B5 => 33, C5 => 34, D5 => 35, E5 => 36, F5 => 37, G5 => 38, H5 => 39,
    A6 => 40, B6 => 41, C6 => 42, D6 => 43, E6 => 44, F6 => 45, G6 => 46, H6 => 47,
    A7 => 48, B7 => 49, C7 => 50, D7 => 51, E7 => 52, F7 => 53, G7 => 54, H7 => 55,
    A8 => 56, B8 => 57, C8 => 58, D8 => 59, E8 => 60, F8 => 61, G8 => 62, H8 => 63,

    FILE_A => 0, FILE_B => 1, FILE_C => 2, FILE_D => 3,
    FILE_E => 4, FILE_F => 5, FILE_G => 6, FILE_H => 7,

    RANK_1 => 0, RANK_2 => 1, RANK_3 => 2, RANK_4 => 3,
    RANK_5 => 4, RANK_6 => 5, RANK_7 => 6, RANK_8 => 7,
};

our %square_numbers = (
    'a1' => A1, 'b1' => B1, 'c1' => C1, 'd1' => D1, 'e1' => E1, 'f1' => F1, 'g1' => G1, 'h1' => H1,
    'a2' => A2, 'b2' => B2, 'c2' => C2, 'd2' => D2, 'e2' => E2, 'f2' => F2, 'g2' => G2, 'h2' => H2,
    'a3' => A3, 'b3' => B3, 'c3' => C3, 'd3' => D3, 'e3' => E3, 'f3' => F3, 'g3' => G3, 'h3' => H3,
    'a4' => A4, 'b4' => B4, 'c4' => C4, 'd4' => D4, 'e4' => E4, 'f4' => F4, 'g4' => G4, 'h4' => H4,
    'a5' => A5, 'b5' => B5, 'c5' => C5, 'd5' => D5, 'e5' => E5, 'f5' => F5, 'g5' => G5, 'h5' => H5,
    'a6' => A6, 'b6' => B6, 'c6' => C6, 'd6' => D6, 'e6' => E6, 'f6' => F6, 'g6' => G6, 'h6' => H6,
    'a7' => A7, 'b7' => B7, 'c7' => C7, 'd7' => D7, 'e7' => E7, 'f7' => F7, 'g7' => G7, 'h7' => H7,
    'a8' => A8, 'b8' => B8, 'c8' => C8, 'd8' => D8, 'e8' => E8, 'f8' => F8, 'g8' => G8, 'h8' => H8,
);

our %square_names = reverse %square_numbers;


1;

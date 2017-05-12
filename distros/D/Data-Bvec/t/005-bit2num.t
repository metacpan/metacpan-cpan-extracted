use Test::More;

use Data::Bvec qw( bit2num str2bit );

POD: {

    #                   0----+----1----+----2----+----3-
    my $vec  = str2bit '01110011110001111100001111110001';

    my $set1 = bit2num $vec,  1, 5;  # [  1,  2,  3,  6,  7 ]
    my $set2 = bit2num $vec,  6, 5;  # [  8,  9, 13, 14, 15 ]
    my $set3 = bit2num $vec, 11, 5;  # [ 16, 17, 22, 23, 24 ]
    my $set4 = bit2num $vec, 16, 5;  # [ 25, 26, 27, 31     ]


is( "@$set1", '1 2 3 6 7',      'bit2num() $set1 POD' );
is( "@$set2", '8 9 13 14 15',   'bit2num() $set2 POD' );
is( "@$set3", '16 17 22 23 24', 'bit2num() $set3 POD' );
is( "@$set4", '25 26 27 31',    'bit2num() $set4 POD' );

}

use Test::More tests => 4;

use warnings;
use Test::More;
use Data::Dumper;

BEGIN { use_ok( 'Bio::Gonzales::Range::Util', 'cluster_overlapping_ranges', 'overlaps' ); }

ok( overlaps( [ 3, 5 ], [ 2, 4 ] ), "with overlap" );
ok( overlaps( [ 3, 5 ], [ 6, 8 ], { book_ended => 1 } ), "book ended, q after r" );
ok( overlaps( [ 6, 8 ], [ 3, 5 ], { book_ended => 1 } ), "book ended, r after q" );

ok( !overlaps( [ 3, 3 ], [ 4, 4 ] ), "no overlap 1" );
ok( overlaps( [ 3, 3 ], [ 4, 4 ], { book_ended => 1 } ), "overlap 2" );
ok( overlaps( [ 4, 4 ], [ 3, 3 ], { book_ended => 1 } ), "overlap 3" );
ok( overlaps( [ 2, 3 ], [ 4, 5 ], { book_ended => 1 } ), "overlap 4" );

ok( !overlaps( [ 3, 5 ], [ 6, 8 ] ), "no overlap, book ended, q after r" );
ok( !overlaps( [ 6, 8 ], [ 3, 5 ] ), "no overlap, book ended, r after q" );
ok( !overlaps( [ 6, 8 ], [ 3, 5 ] ), "no overlap, book ended, r after q" );

ok( overlaps( [ 6, 8 ], [ 8, 19 ], { offset => 4} ), "offset 4a, q after r" );
ok( overlaps( [ 6, 8 ], [ 9, 19 ], { offset => 4} ), "offset 4b, q after r" );
ok( overlaps( [ 6, 8 ], [ 10, 19 ], { offset => 4} ), "offset 4c, q after r" );
ok( overlaps( [ 6, 8 ], [ 11, 19 ], { offset => 4} ), "offset 4d, q after r" );
ok( overlaps( [ 6, 8 ], [ 12, 19 ], { offset => 4} ), "offset 4e, q after r" );
ok( !overlaps( [ 6, 8 ], [ 13, 19 ], { offset => 4} ), "offset 4f, q after r" );
ok( !overlaps( [ 6, 8 ], [ 14, 19 ], { offset => 4} ), "offset 4g, q after r" );

ok( overlaps( [ 6, 8 ], [ 3, 5 ], { offset => 4} ), "offset 4a, r after q" );
ok( overlaps( [ 7,9 ], [ 3, 5 ], { offset => 4} ), "offset 4b, r after q" );
ok( overlaps( [ 8,10 ], [ 3, 5 ], { offset => 4} ), "offset 4c, r after q" );
ok( overlaps( [ 9,11 ], [ 3, 5 ], { offset => 4} ), "offset 4d, r after q" );
ok( !overlaps( [ 10,12 ], [ 3, 5 ], { offset => 4} ), "offset 4e, r after q" );
ok( !overlaps( [ 11,13 ], [ 3, 5 ], { offset => 4} ), "offset 4f, r after q" );

my $ranges = cluster_overlapping_ranges(
    [

        [ 417,  '575',  7991 ],
        [ 537,  '829',  7992 ],
        [ 839,  '901',  7993 ],
        [ 1103, '1232', 8322 ],
        [ 1187, '1476', 8323 ],
        [ 1485, '1601', 8324 ],
        [ 1353, '1476', 8871 ],
        [ 1485, '1741', 8872 ],
        [ 304,  '387',  10029 ],
        [ 321,  '626',  10030 ],
        [ 639,  '801',  10031 ],
        [ 1249, '1474', 10695 ],
        [ 1485, '1698', 10696 ],
        [ 117,  '230',  10733 ],
        [ 239,  '513',  10734 ],
        [ 1485, '1730', 13110 ],
        [ 217,  '429',  13964 ],
        [ 439,  '683',  13965 ],
        [ 39,   '289',  14126 ]
    ]
);

is_deeply(
    $ranges,
    [
        [
            [ 39,  '289', 14126 ],
            [ 117, '230', 10733 ],
            [ 217, '429', 13964 ],
            [ 239, '513', 10734 ],
            [ 304, '387', 10029 ],
            [ 321, '626', 10030 ],
            [ 417, '575', 7991 ],
            [ 439, '683', 13965 ],
            [ 537, '829', 7992 ],
            [ 639, '801', 10031 ],
        ],

        [ [ 839, '901', 7993 ], ],
        [

            [ 1103, '1232', 8322 ],
            [ 1187, '1476', 8323 ],
            [ 1249, '1474', 10695 ],
            [ 1353, '1476', 8871 ],
        ],

        [

            [ 1485, '1601', 8324 ],
            [ 1485, '1698', 10696 ],
            [ 1485, '1730', 13110 ],
            [ 1485, '1741', 8872 ],
        ],
    ],
    "ranges"
);

$ranges = cluster_overlapping_ranges();
ok( !defined($ranges) );

$ranges = cluster_overlapping_ranges( [] );
ok( !defined($ranges) );

$ranges = cluster_overlapping_ranges( [ [ 1, 3 ] ] );
is_deeply( $ranges, [ [ [ 1, 3 ] ] ] );

#ok(!defined($ranges));

done_testing();



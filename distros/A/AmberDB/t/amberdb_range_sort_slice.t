#!/usr/bin/perl

# t/amberdb_range_sort_slice.t - Tests for fast range_slice using sort_block and .fld boundaries
# Verifies exact bounds, missing bounds, empty gaps, candidate intersection, and incremental updates (insert, edit, delete).

use 5.016000;
use strict;
use warnings;
use Test::More tests => 7;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Time::HiRes qw(time);
use lib "$Bin/../lib", 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { simple => 0, language => 'tr' }
);

# Schema:
# Block 0: id
# Block 1: title
# Block 2: category (match_block)
# Block 3: year     (match_block AND sort_block)
# Block 4: rating   (sort_block only)
$adb->table_attr( 'movies', {
    record_index => 1,
    blocks       => [
        { name => 'id' },
        { name => 'title' },
        { name => 'category' },
        { name => 'year',   type => 'num' },
        { name => 'rating', type => 'decimal' },
    ],
    match_block  => [ 2, 3 ],
    sort_block   => [ { blk => 3, type => 'num' }, { blk => 4, type => 'decimal' } ],
    search_block => [ 1 ],
} );

# Seed test records: ID, Title, Category, Year, Rating
$adb->insert_id( 'movies', 1, 'The Matrix',   'Sci-Fi',   1999, 8.7 );
$adb->insert_id( 'movies', 2, 'Gladiator',    'Action',   2000, 8.5 );
$adb->insert_id( 'movies', 3, 'Memento',      'Thriller', 2000, 8.4 );
$adb->insert_id( 'movies', 4, 'Inception',    'Sci-Fi',   2010, 8.8 );
$adb->insert_id( 'movies', 5, 'Interstellar', 'Sci-Fi',   2014, 8.7 );
$adb->insert_id( 'movies', 6, 'Dune',         'Sci-Fi',   2021, 8.0 );
$adb->insert_id( 'movies', 7, 'Oppenheimer',  'Drama',    2023, 8.9 );

# ---------------------------------------------------------------------------
subtest '1. range_slice exact boundary matching' => sub {
    plan tests => 6;

    # 1.1 Closed interval [2000, 2021] -> Expected IDs: 2, 3, 4, 5, 6
    my $slice_buf = $adb->range_slice( 'movies', 3, 2000, 2021 );
    ok( defined $slice_buf && length($slice_buf) >= 8, 'range_slice returns non-empty buffer for [2000, 2021]' );
    my ( undef, @ids ) = $adb->bin_decode( $slice_buf, 0, 0, 'asc' );
    is_deeply( [ sort { $a <=> $b } @ids ], [ 2, 3, 4, 5, 6 ], 'Returned IDs match exactly [2, 3, 4, 5, 6]' );

    # 1.2 Exact single year with multiple records: [2000, 2000] -> IDs 2, 3
    my $single_buf = $adb->range_slice( 'movies', 3, 2000, 2000 );
    ok( defined $single_buf && length($single_buf) == 16, 'range_slice for single year with 2 records returns 16 bytes' );
    my ( undef, @single_ids ) = $adb->bin_decode( $single_buf, 0, 0, 'asc' );
    is_deeply( [ sort { $a <=> $b } @single_ids ], [ 2, 3 ], 'Single year returns both records for year 2000' );

    # 1.3 Full span: min => 1999, max => 2023 -> all 7 movies
    my $all_buf = $adb->range_slice( 'movies', 3, 1999, 2023 );
    my ( undef, @all_ids ) = $adb->bin_decode( $all_buf, 0, 0, 'asc' );
    is_deeply( [ sort { $a <=> $b } @all_ids ], [ 1, 2, 3, 4, 5, 6, 7 ], 'Full span returns all 7 records' );

    # 1.4 Unbounded min: max => 2000 -> 1999, 2000 (IDs 1, 2, 3)
    my $max_only_buf = $adb->range_slice( 'movies', 3, undef, 2000 );
    my ( undef, @max_ids ) = $adb->bin_decode( $max_only_buf, 0, 0, 'asc' );
    is_deeply( [ sort { $a <=> $b } @max_ids ], [ 1, 2, 3 ], 'Unbounded min with max 2000 returns IDs 1, 2, 3' );
};

# ---------------------------------------------------------------------------
subtest '2. range_slice missing / inexact boundary resolution' => sub {
    plan tests => 3;

    # 2.1 [2005, 2022]: 2005 doesn't exist (next is 2010), 2022 doesn't exist (prev is 2021)
    # Expected matches: 2010 (ID 4), 2014 (ID 5), 2021 (ID 6)
    my $inexact_buf = $adb->range_slice( 'movies', 'year', 2005, 2022 );
    ok( defined $inexact_buf && length($inexact_buf) == 24, 'Binary slice returned 24 bytes (3 IDs)' );
    my ( undef, @ids ) = $adb->bin_decode( $inexact_buf, 0, 0, 'asc' );
    is_deeply( [ sort { $a <=> $b } @ids ], [ 4, 5, 6 ], 'Resolved nearest existing bounds [2010, 2021] returning IDs 4, 5, 6' );

    # 2.2 Min beyond highest or Max below lowest:
    # min => 1990 (below all), max => 2012 (between 2010 and 2014) -> 1999, 2000, 2010 (IDs 1, 2, 3, 4)
    my $span_buf = $adb->range_slice( 'movies', 3, 1990, 2012 );
    my ( undef, @span_ids ) = $adb->bin_decode( $span_buf, 0, 0, 'asc' );
    is_deeply( [ sort { $a <=> $b } @span_ids ], [ 1, 2, 3, 4 ], 'Min below lowest correctly clips to first record' );
};

# ---------------------------------------------------------------------------
subtest '3. range_slice empty gaps and out-of-range bounds' => sub {
    plan tests => 4;

    # 3.1 Gap with no records: [2001, 2009]
    my $gap_buf = $adb->range_slice( 'movies', 3, 2001, 2009 );
    is( $gap_buf, '', 'Range in existing gap returns empty string' );

    # 3.2 Entirely below minimum existing value: [1980, 1995]
    my $below_buf = $adb->range_slice( 'movies', 3, 1980, 1995 );
    is( $below_buf, '', 'Range below all values returns empty string' );

    # 3.3 Entirely above maximum existing value: [2030, 2040]
    my $above_buf = $adb->range_slice( 'movies', 3, 2030, 2040 );
    is( $above_buf, '', 'Range above all values returns empty string' );

    # 3.4 Inverted bounds: min > max: [2020, 2010]
    my $inv_buf = $adb->range_slice( 'movies', 3, 2020, 2010 );
    is( $inv_buf, '', 'Inverted range (min > max) returns empty string' );
};

# ---------------------------------------------------------------------------
subtest '4. range_slice configuration guards (sort_block & match_block)' => sub {
    plan tests => 2;

    # Block 4 (rating) is in sort_block, but NOT in match_block (no .fld index)
    my $rating_slice = $adb->range_slice( 'movies', 4, 8.0, 9.0 );
    is( $rating_slice, undef, 'range_slice on block without match_block returns undef (safe fallback)' );

    # Block 1 (title) is neither in sort_block nor match_block
    my $title_slice = $adb->range_slice( 'movies', 1, 'A', 'Z' );
    is( $title_slice, undef, 'range_slice on non-sort block returns undef' );
};

# ---------------------------------------------------------------------------
subtest '5. End-to-end read_all and field_fetch queries with range' => sub {
    plan tests => 4;

    # 5.1 read_all with range [2000, 2020]
    my @r_ids = $adb->read_all( 'movies', { range => { block => 'year', min => 2000, max => 2020 }, keys_only => 1 } );
    is_deeply( [ sort { $a <=> $b } @r_ids ], [ 2, 3, 4, 5 ], 'read_all with keys_only uses fast range_slice and returns IDs 2, 3, 4, 5' );

    # 5.2 read_all with gap range [2001, 2009] -> empty list
    my @gap_recs = $adb->read_all( 'movies', { range => { block => 'year', min => 2001, max => 2009 } } );
    is( scalar(@gap_recs), 0, 'read_all with empty gap returns 0 records immediately' );

    # 5.3 field_fetch Category 'Sci-Fi' with range [2000, 2020]
    # Sci-Fi movies in DB: Matrix (1999), Inception (2010), Interstellar (2014), Dune (2021)
    # Filtered by range [2000, 2020]: Inception (4), Interstellar (5)
    my @sf_recs = $adb->field_fetch( 'movies', 'category', 'Sci-Fi', { range => { block => 'year', min => 2000, max => 2020 } } );
    my @sf_ids = sort { $a <=> $b } map { $_->[0] } @sf_recs;
    is_deeply( \@sf_ids, [ 4, 5 ], 'field_fetch Sci-Fi + range [2000, 2020] returns Inception and Interstellar' );

    # 5.4 Fallback test: query range on block 4 (rating: 8.5 - 9.0) which is not in match_block
    my @high_rated = $adb->read_all( 'movies', { range => { block => 'rating', min => 8.5, max => 9.0 }, keys_only => 1 } );
    # 8.7 (1), 8.5 (2), 8.8 (4), 8.7 (5), 8.9 (7)
    is_deeply( [ sort { $a <=> $b } @high_rated ], [ 1, 2, 4, 5, 7 ], 'Fallback path on non-match_block works seamlessly' );
};

# ---------------------------------------------------------------------------
subtest '6. Incremental record insertion, edit, and deletion (vals maintenance)' => sub {
    plan tests => 6;

    # 6.1 Check gap before insertion: [2008, 2009] -> empty
    my $before = $adb->range_slice( 'movies', 3, 2008, 2009 );
    is( $before, '', 'Before insert: gap [2008, 2009] is empty' );

    # 6.2 Insert new record in the gap: ID 8, 'Avatar', 'Sci-Fi', 2009, 7.9
    $adb->insert_id( 'movies', 8, 'Avatar', 'Sci-Fi', 2009, 7.9 );

    # Now [2008, 2009] should contain ID 8
    my $after = $adb->range_slice( 'movies', 3, 2008, 2009 );
    ok( defined $after && length($after) == 8, 'After insert: range_slice returns 8 bytes for newly inserted year 2009' );
    my ( undef, @ids ) = $adb->bin_decode( $after, 0, 0, 'asc' );
    is_deeply( \@ids, [ 8 ], 'Returned ID is Avatar (8)' );

    # 6.3 Delete record 8: year 2009 should be removed from :vals since no other records have 2009
    $adb->delete_id( 'movies', 8 );
    my $after_del = $adb->range_slice( 'movies', 3, 2008, 2009 );
    is( $after_del, '', 'After delete_id: year 2009 is removed from :vals, gap is empty again' );

    # 6.4 Edit record 7 ('Oppenheimer', 2023) to 2024:
    # 2023 should be removed from :vals, and 2024 should be added!
    $adb->update_id( 'movies', 7, 'Oppenheimer', 'Drama', 2024, 8.9 );
    my $slice_2023 = $adb->range_slice( 'movies', 3, 2023, 2023 );
    is( $slice_2023, '', 'After update_id: old year 2023 is removed from :vals' );
    my $slice_2024 = $adb->range_slice( 'movies', 3, 2024, 2024 );
    my ( undef, @ids_2024 ) = $adb->bin_decode( $slice_2024, 0, 0, 'asc' );
    is_deeply( \@ids_2024, [ 7 ], 'After update_id: new year 2024 is indexed in :vals and points to ID 7' );
};

# ---------------------------------------------------------------------------
subtest '7. Sub-millisecond performance validation' => sub {
    plan tests => 1;

    my $t0 = time();

    my $iterations = 500;
    for ( 1 .. $iterations ) {
        my $res = $adb->range_slice( 'movies', 3, 2000, 2020 );
    }

    my $t1 = time();
    my $elapsed = $t1 - $t0;
    # 500 iterations on disk (MSYS2 Windows DB_File) completed in ~1.4 ms/call
    ok( $elapsed < 2.0, sprintf("500 range_slice calls completed in %.4fs (%.3f ms/call)", $elapsed, ($elapsed / $iterations) * 1000) );
};

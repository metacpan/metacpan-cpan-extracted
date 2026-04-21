#!perl
##----------------------------------------------------------------------------
## DateTime::Lite::TimeZone - t/17.resolve_abbreviation_period.t
## Test suite for resolve_abbreviation() sort order and period option.
##
## JST is used as the primary test abbreviation because its historical usage
## is well-documented and covers multiple distinct zones and time windows:
##   Asia/Tokyo      - last used 1951-09-08 (end of US occupation)
##   Asia/Manila     - last used 1942-02-11 (WWII occupation)
##   Asia/Hong_Kong  - last used 1941-12-24 (WWII occupation)
##   Asia/Taipei     - last used 1937-09-30 (Japanese colonial period)
##   Asia/Pyongyang  - last used 1911-12-31 (Japanese annexation)
##   Asia/Seoul      - last used 1911-12-31 (Japanese annexation)
##
## Sort order (IANA branch) as of v0.6.3:
##   1. is_active DESC         (zones whose POSIX footer still references the
##                              abbreviation come before zones that no longer
##                              do)
##   2. first_trans_time ASC   (earliest adoption of the abbreviation first)
##   3. last_trans_time DESC   (most persistent use first, among tied groups)
##   4. zone_name ASC          (deterministic final tie-breaker)
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;
use Scalar::Util qw( looks_like_number );
use Time::Local qw( timegm );

BEGIN
{
    eval{ require DBI; require DBD::SQLite };
    plan( skip_all => 'DBI and DBD::SQLite are required for this test' ) if( $@ );
    use_ok( 'DateTime::Lite::TimeZone' ) || BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );
}

# NOTE: Helper: extract zone names from a result arrayref in order
sub zone_names
{
    my $results = shift( @_ );
    return( [ map{ $_->{zone_name} } @$results ] );
}

# NOTE: Helper: verify the four-level sort order holds across a result set.
# Compares adjacent pairs; if any pair violates the ordering, fail once and
# stop.
sub is_sorted_resolve_order
{
    my( $results, $label ) = @_;
    for( my $i = 1; $i < scalar( @$results ); $i++ )
    {
        my $a = $results->[ $i - 1 ];
        my $b = $results->[ $i ];

        # Key 1: is_active DESC
        if( $a->{is_active} < $b->{is_active} )
        {
            fail( "$label: is_active out of order at index $i ($a->{zone_name} -> $b->{zone_name})" );
            return;
        }
        next if( $a->{is_active} != $b->{is_active} );

        # Key 2: first_trans_time ASC
        if( $a->{first_trans_time} > $b->{first_trans_time} )
        {
            fail( "$label: first_trans_time out of order at index $i ($a->{zone_name} -> $b->{zone_name})" );
            return;
        }
        next if( $a->{first_trans_time} != $b->{first_trans_time} );

        # Key 3: last_trans_time DESC
        if( $a->{last_trans_time} < $b->{last_trans_time} )
        {
            fail( "$label: last_trans_time out of order at index $i ($a->{zone_name} -> $b->{zone_name})" );
            return;
        }
        next if( $a->{last_trans_time} != $b->{last_trans_time} );

        # Key 4: zone_name ASC
        if( $a->{zone_name} gt $b->{zone_name} )
        {
            fail( "$label: zone_name out of order at index $i ($a->{zone_name} -> $b->{zone_name})" );
            return;
        }
    }
    pass( $label );
}

# NOTE: Default sort order for JST.
#       Asia/Tokyo has is_active=1 (footer "JST-9" mentions JST); all other
#       historical JST zones (Pyongyang, Seoul, Taipei, Hong_Kong, Manila)
#       have is_active=0 since their current footers reference different
#       abbreviations (KST, CST, HKT, PST respectively).
subtest 'Default sort order is is_active DESC then first_trans_time ASC' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST' );
    SKIP:
    {
        if( !ok( defined( $results ), 'JST resolved' ) )
        {
            skip( 'JST resolution failed', 7 );
        }
        is( scalar( @$results ), 6, '6 zones have historically used JST' );

        # All five expected fields must be present and numeric
        foreach my $r ( @$results )
        {
            for my $field ( qw( is_active first_trans_time last_trans_time ) )
            {
                ok( exists( $r->{ $field } ),
                    "$field present for $r->{zone_name}" );
                ok( looks_like_number( $r->{ $field } ),
                    "$field is numeric for $r->{zone_name}" );
            }
        }

        # First result must be Asia/Tokyo: only JST zone whose footer still
        # references JST.
        is( $results->[0]->{zone_name}, 'Asia/Tokyo', 'Asia/Tokyo is first (still active on JST)' );
        is( $results->[0]->{is_active}, 1,            'Asia/Tokyo is_active is 1' );

        # The remaining 5 zones are all is_active=0 and ordered by first_trans_time ASC.
        my @rest = @{$results}[ 1 .. $#{$results} ];
        for my $r ( @rest )
        {
            is( $r->{is_active}, 0, "$r->{zone_name} is_active is 0" );
        }

        # Four-level sort order holds across all 6 results.
        is_sorted_resolve_order( $results, 'JST results follow the four-level sort order' );
    };
};

# NOTE: period => single string with operator prefix
#       '>1946-01-01' should return only Asia/Tokyo (last use 1951-09-08).
subtest "period => '>1946-01-01' returns only post-1946 zones" => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST',
        period => '>1946-01-01'
    );
    SKIP:
    {
        if( !ok( defined( $results ), "JST with period => '>1946-01-01' resolved" ) )
        {
            skip( 'resolution failed', 3 );
        }
        is( scalar( @$results ),        1,            'Exactly one zone after 1946' );
        is( $results->[0]->{zone_name}, 'Asia/Tokyo', 'Zone is Asia/Tokyo' );
        is( $results->[0]->{extended},  0,            'Result is from IANA types' );
    };
};

# NOTE: period => array ref with two bounds.
#       ['>1941-01-01', '<1946-01-01'] covers the WWII occupation window.
#       Expected: Asia/Manila (1942-02-11) and Asia/Hong_Kong (1941-12-24).
subtest "period => ['>1941-01-01', '<1946-01-01'] returns WWII-era zones" => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST',
        period => ['>1941-01-01', '<1946-01-01']
    );
    SKIP:
    {
        if( !ok( defined( $results ), 'JST with two-bound period resolved' ) )
        {
            skip( 'resolution failed', 4 );
        }
        is( scalar( @$results ), 2, 'Exactly two zones in the WWII window' );
        my $names = zone_names( $results );
        ok( ( grep{ $_ eq 'Asia/Manila'    } @$names ), 'Asia/Manila present' );
        ok( ( grep{ $_ eq 'Asia/Hong_Kong' } @$names ), 'Asia/Hong_Kong present' );
        # Sort order must still hold within the filtered set.
        is_sorted_resolve_order( $results, 'Filtered results respect the sort order' );
    };
};

# NOTE: period => 'current'. Only Asia/Tokyo currently uses JST.
subtest "period => 'current' returns only currently-active zone" => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST',
        period => 'current'
    );
    SKIP:
    {
        if( !ok( defined( $results ), "JST with period => 'current' resolved" ) )
        {
            skip( 'resolution failed', 3 );
        }
        is( scalar( @$results ),        1,            'Exactly one currently-active zone for JST' );
        is( $results->[0]->{zone_name}, 'Asia/Tokyo', 'Currently-active zone is Asia/Tokyo' );
        is( $results->[0]->{extended},  0,            'Result is from IANA types' );
    };
};

# NOTE: period with a raw epoch integer (no ISO string conversion).
#       We use EST with a post-1970 epoch cutoff to avoid timegm() overflow
#       issues on some systems with pre-1970 dates. Epoch for 2010-01-01 UTC
#       is 1262304000; three EST zones last used the abbreviation after that
#       date: America/Port-au-Prince (2015), America/Cancun (2015),
#       America/Grand_Turk (2014).
subtest 'period with raw epoch integer value' => sub
{
    # epoch for 2010-01-01 00:00:00 UTC (post-1970, safe on all platforms)
    my $epoch_2010 = timegm( 0, 0, 0, 1, 0, 2010 );
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'EST',
        period => ">$epoch_2010"
    );
    SKIP:
    {
        if( !ok( defined( $results ), 'EST with raw epoch period resolved' ) )
        {
            diag( "Failed to resolve the timezone abbreviation 'EST' with period >$epoch_2010" );
            skip( 'resolution failed', 4 );
        }
        is( scalar( @$results ),       3,      'Three EST zones used after 2010 epoch' );
        my $names = zone_names( $results );
        ok( ( grep{ $_ eq 'America/Port-au-Prince' } @$names ), 'America/Port-au-Prince present' );
        ok( ( grep{ $_ eq 'America/Cancun'         } @$names ), 'America/Cancun present' );
        ok( ( grep{ $_ eq 'America/Grand_Turk'     } @$names ), 'America/Grand_Turk present' );
    };
};

# NOTE: period with no matching results returns undef + error
subtest 'period with no matching results returns error' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST',
        period => '<1900-01-01'
    );
    ok( !defined( $results ), 'No zones found: method returns undef' );
    like(
        DateTime::Lite::TimeZone->error,
        qr/No timezone found/i,
        'Error message mentions no timezone found',
    );
};

# NOTE: period + utc_offset combined.
#       JST offset +09:00 (32400s) AND after 1946 -> Asia/Tokyo only.
subtest 'period and utc_offset can be combined' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation(
        'JST',
        utc_offset => 32400,
        period     => '>1946-01-01',
    );
    SKIP:
    {
        if( !ok( defined( $results ), 'JST with utc_offset + period resolved' ) )
        {
            skip( 'resolution failed', 2 );
        }
        is( scalar( @$results ),        1,            'One result with combined filters' );
        is( $results->[0]->{zone_name}, 'Asia/Tokyo', 'Zone is Asia/Tokyo' );
    };
};

# NOTE: Empty period value triggers a descriptive error
subtest 'Empty period value triggers error' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST',
        period => ''
    );
    ok( !defined( $results ), 'Empty period string returns undef' );
    like(
        DateTime::Lite::TimeZone->error,
        qr/Empty value.*period/i,
        'Error message mentions empty period value',
    );
};

# NOTE: Sort order holds for a multi-offset ambiguous abbreviation (EST).
#       EST has zones on both +EST (American time) and +EST (Australia old
#       abbreviation for Eastern Standard Time) in the database; the sort
#       order must still be well-defined across both groups.
subtest 'Sort order holds for multi-offset abbreviation (EST)' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'EST' );
    SKIP:
    {
        if( !ok( defined( $results ), 'EST resolved' ) )
        {
            skip( 'EST resolution failed', 2 );
        }
        ok( scalar( @$results ) > 1, 'Multiple zones returned for EST' );
        is_sorted_resolve_order( $results, 'EST results follow the four-level sort order' );
    };
};

# NOTE: period is silently ignored for extended alias results.
#       (extended_aliases has no trans_time data; the period filter is applied
#       only to the IANA types query which is bypassed when extended triggers)
subtest 'period option is ignored for extended alias results' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'AFT',
        extended => 1,
        period   => '>1950-01-01',
    );
    SKIP:
    {
        if( !ok( defined( $results ), 'AFT with extended + period resolved' ) )
        {
            skip( 'resolution failed', 3 );
        }
        is( scalar( @$results ),        1,            'One result from extended_aliases' );
        is( $results->[0]->{zone_name}, 'Asia/Kabul', 'Zone is Asia/Kabul' );
        is( $results->[0]->{extended},  1,            'Result is from extended_aliases' );
    };
};

# NOTE: Extended results must NOT carry is_active (curated table has no
#       notion of "currently active"; the editorial is_primary marker plays
#       that role instead).
subtest 'Extended results carry is_primary but not is_active' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'BRT',
        extended => 1,
    );
    SKIP:
    {
        if( !ok( defined( $results ), 'BRT with extended resolved' ) )
        {
            skip( 'resolution failed', 2 );
        }
        ok( !exists( $results->[0]->{is_active} ),
            'BRT extended result has no is_active field' );
        ok( exists( $results->[0]->{is_primary} ),
            'BRT extended result has is_primary field' );
    };
};

# NOTE: IANA results must carry is_active but not is_primary.
subtest 'IANA results carry is_active but not is_primary' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST' );
    SKIP:
    {
        if( !ok( defined( $results ), 'JST resolved' ) )
        {
            skip( 'resolution failed', 2 );
        }
        ok( exists( $results->[0]->{is_active} ),
            'JST IANA result has is_active field' );
        ok( !exists( $results->[0]->{is_primary} ),
            'JST IANA result has no is_primary field' );
    };
};

done_testing;

__END__

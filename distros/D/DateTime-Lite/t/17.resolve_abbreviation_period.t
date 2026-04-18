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

# NOTE: Helper: check that a list of epoch values is monotonically non-increasing
sub is_sorted_desc
{
    my( $list, $label ) = @_;
    for( my $i = 1; $i < scalar( @$list ); $i++ )
    {
        if( $list->[$i] > $list->[$i - 1] )
        {
            fail( "$label: not sorted DESC at index $i ($list->[$i] > $list->[$i-1])" );
            return;
        }
    }
    pass( $label );
}

# NOTE: Default sort order: last_trans_time DESC
#       JST has 6 zones historically; Asia/Tokyo (last use 1951) must come first.
subtest 'Default sort order is last_trans_time DESC' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST' );
    SKIP:
    {
        if( !ok( defined( $results ), 'JST resolved' ) )
        {
            skip( 'JST resolution failed', 5 );
        }
        is( scalar( @$results ), 6, '6 zones have historically used JST' );

        # last_trans_time must be present and numeric in every result
        foreach my $r ( @$results )
        {
            ok( exists( $r->{last_trans_time} ),
                "last_trans_time present for $r->{zone_name}" );
            ok( looks_like_number( $r->{last_trans_time} ),
                "last_trans_time is numeric for $r->{zone_name}" );
        }

        # First result must be Asia/Tokyo (last used JST in 1951)
        is( $results->[0]->{zone_name}, 'Asia/Tokyo', 'Asia/Tokyo is first (most recent)' );

        # Verify DESC order holds across all results
        my $epochs = [ map{ $_->{last_trans_time} } @$results ];
        is_sorted_desc( $epochs, 'last_trans_time values are in DESC order' );
    };
};

# NOTE: period => single string with operator prefix
#       '>1946-01-01' should return only Asia/Tokyo (last use 1951-09-08)
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

# NOTE: period => array ref with two bounds
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
            skip( 'resolution failed', 5 );
        }
        is( scalar( @$results ), 2, 'Exactly two zones in the WWII window' );
        my $names = zone_names( $results );
        ok( ( grep{ $_ eq 'Asia/Manila'    } @$names ), 'Asia/Manila present' );
        ok( ( grep{ $_ eq 'Asia/Hong_Kong' } @$names ), 'Asia/Hong_Kong present' );
        # Results must still be sorted DESC within the filtered set
        my $epochs = [ map{ $_->{last_trans_time} } @$results ];
        is_sorted_desc( $epochs, 'Filtered results are in DESC order' );
    };
};

# NOTE: period => 'current'
#       Only Asia/Tokyo currently uses JST.
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
#       issues on some systems with pre-1970 dates. epoch for 2010-01-01 UTC
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

# NOTE: period + utc_offset combined
#       JST offset +09:00 (32400s) AND after 1946 -> Asia/Tokyo only
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

# NOTE: Sort order holds for a multi-offset ambiguous abbreviation (EST)
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
        my $epochs = [ map{ $_->{last_trans_time} } @$results ];
        is_sorted_desc( $epochs, 'EST results are in DESC order by last_trans_time' );
    };
};

# NOTE: period is silently ignored for extended alias results
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

done_testing;

__END__

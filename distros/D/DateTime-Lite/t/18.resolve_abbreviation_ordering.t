#!perl
##----------------------------------------------------------------------------
## DateTime::Lite::TimeZone - t/18.resolve_abbreviation_ordering.t
## Test suite for the is_active-based sort order (v0.6.3).
##
## This complements t/17.resolve_abbreviation_period.t with abbreviations where
## the ordering has a clear, verifiable expected top result.
##
## Each subtest picks an abbreviation where:
##   - V0.6.2 (sorted by MAX(trans_time) DESC) produced a surprising or
##     counter-intuitive top zone.
##   - V0.6.3 (sorted by is_active DESC, first_trans_time ASC, ...) produces
##     the expected zone on top.
##
## These are the cases that motivated the redesign:
##
##   CEST: v0.6.2 returned Africa/Tripoli (last CEST in 2013) first. That was
##         surprising because the Central European zones are where CEST actually
##         means something. v0.6.3 puts Europe/Berlin first.
##
##   PST:  v0.6.2 returned America/Dawson first (used PST until 1973).
##         v0.6.3 puts America/Los_Angeles first, which is the natural
##         association for PST.
##
##   WET:  v0.6.2 returned Atlantic/Canary first because of MAX trans_time
##         ordering. v0.6.3 puts Atlantic/Faroe first (earliest adopter still
##         active). Also relevant: Europe/Brussels, which once used WET but
##         stopped long ago, must appear after the still-active zones.
##
##   EEST: v0.6.2 returned Asia/Gaza first. v0.6.3 puts Asia/Beirut first
##         (earliest adopter still active on EEST).
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

BEGIN
{
    eval{ require DBI; require DBD::SQLite };
    plan( skip_all => 'DBI and DBD::SQLite are required for this test' ) if( $@ );
    use_ok( 'DateTime::Lite::TimeZone' ) || BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );
}

# NOTE: CEST - Central European Summer Time.
#       30 zones have historically used CEST. Among those still active,
#       Europe/Berlin, Europe/Budapest, Europe/Prague, Europe/Vienna and
#       Europe/Warsaw adopted CEST on the same day (1916-04-30, the first
#       German-Austro-Hungarian summer time during WWI). Alphabetic
#       tie-breaker puts Berlin first.
subtest 'CEST puts a Central European active zone first, not Africa' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'CEST' );
    SKIP:
    {
        if( !ok( defined( $results ), 'CEST resolved' ) )
        {
            skip( 'CEST resolution failed', 4 );
        }
        is( $results->[0]->{zone_name}, 'Europe/Berlin',
            'Europe/Berlin is first for CEST (earliest still-active adopter, alpha-first)' );
        is( $results->[0]->{is_active}, 1,
            'Europe/Berlin is_active=1 for CEST' );
        ok( $results->[0]->{first_trans_time} < $results->[0]->{last_trans_time},
            'Europe/Berlin has a span of CEST usage' );

        # Tripoli (last CEST use in 2013) must NOT be first.
        isnt( $results->[0]->{zone_name}, 'Africa/Tripoli',
            'Africa/Tripoli is no longer first for CEST' );
    };
};

# NOTE: PST - Pacific Standard Time.
#       Active zones include America/Los_Angeles and America/Vancouver.
#       LA adopted PST in 1883 (US Standard Time Act), same as Boise, but
#       Boise left PST for MST in 1974, so LA comes first (alpha tie-break
#       only among *still-active* zones).
subtest 'PST puts America/Los_Angeles first, not a historically-abandoning zone' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'PST' );
    SKIP:
    {
        if( !ok( defined( $results ), 'PST resolved' ) )
        {
            skip( 'PST resolution failed', 3 );
        }
        is( $results->[0]->{zone_name}, 'America/Los_Angeles',
            'America/Los_Angeles is first for PST' );
        is( $results->[0]->{is_active}, 1,
            'America/Los_Angeles is_active=1 for PST' );

        # Boise abandoned PST in 1974 and must appear AFTER the still-active
        # zones even though it adopted PST on the same day as LA.
        my( $boise_idx ) = grep{ $results->[ $_ ]->{zone_name} eq 'America/Boise' }
                               0 .. $#{ $results };
        if( defined( $boise_idx ) )
        {
            cmp_ok( $results->[ $boise_idx ]->{is_active}, '==', 0,
                'America/Boise has is_active=0 (abandoned PST in 1974)' );
        }
        else
        {
            fail( 'America/Boise expected in PST results but not found' );
        }
    };
};

# NOTE: WET - Western European Time.
#       Active zones: Atlantic/Faroe, Europe/Lisbon, Atlantic/Canary,
#       Atlantic/Madeira. Europe/Brussels, Europe/Andorra and others once
#       used WET but stopped long ago, so they must appear after the still
#       active zones.
subtest 'WET puts still-active zones before abandoned zones' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'WET' );
    SKIP:
    {
        if( !ok( defined( $results ), 'WET resolved' ) )
        {
            skip( 'WET resolution failed', 3 );
        }

        my @active   = grep{ $_->{is_active} } @$results;
        my @inactive = grep{ !$_->{is_active} } @$results;

        ok( scalar( @active ) > 0,   'At least one still-active WET zone' );
        ok( scalar( @inactive ) > 0, 'At least one WET zone marked inactive' );

        # The last active must come before the first inactive.
        if( @active && @inactive )
        {
            my $last_active_idx  = -1;
            my $first_inactive_idx = scalar( @$results );
            for my $i ( 0 .. $#{ $results } )
            {
                $last_active_idx    = $i if( $results->[ $i ]->{is_active} );
                $first_inactive_idx = $i if( !$results->[ $i ]->{is_active}
                                          && $first_inactive_idx == scalar( @$results ) );
            }
            cmp_ok( $last_active_idx, '<', $first_inactive_idx,
                'All active WET zones appear before any inactive WET zone' );
        }
        else
        {
            pass( 'No mixed active/inactive case to check' );
        }
    };
};

# NOTE: EEST - Eastern European Summer Time.
#       Among still-active zones, Asia/Beirut adopted EEST earliest (1920).
#       v0.6.2 returned Asia/Gaza first because of MAX(trans_time).
subtest 'EEST puts earliest still-active adopter first' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'EEST' );
    SKIP:
    {
        if( !ok( defined( $results ), 'EEST resolved' ) )
        {
            skip( 'EEST resolution failed', 2 );
        }
        is( $results->[0]->{zone_name}, 'Asia/Beirut',
            'Asia/Beirut is first for EEST (earliest still-active adopter)' );
        is( $results->[0]->{is_active}, 1,
            'Asia/Beirut is_active=1 for EEST' );
    };
};

# NOTE: is_active regex correctness - the word-boundary must not trigger
#       false positives. EST must NOT match because of the EEST substring,
#       and CST must NOT match because of the CEST substring.
subtest 'is_active regex avoids substring false positives' => sub
{
    # A zone that has CET and CEST but not CST in its footer
    # (e.g. Europe/Paris: "CET-1CEST,M3.5.0,M10.5.0/3")
    # should have is_active=1 for CEST but is_active=0 for any substring
    # that isn't a proper token of the footer.
    #
    # We verify indirectly: for CEST we expect most Central European zones
    # to be is_active=1; for a nonsense abbreviation like "ZZZ" we expect
    # no results at all (method returns undef).
    my $cest = DateTime::Lite::TimeZone->resolve_abbreviation( 'CEST' );
    ok( defined( $cest ), 'CEST resolved' );
    my @active = grep{ $_->{is_active} } @$cest;
    ok( scalar( @active ) >= 10,
        'CEST has at least 10 still-active zones (Europe + pockets)' );

    # Non-existent abbreviation: no match at all.
    my $zzz = DateTime::Lite::TimeZone->resolve_abbreviation( 'ZZZ' );
    ok( !defined( $zzz ), 'ZZZ returns undef (no match)' );
};

# NOTE: Numeric abbreviations must also work. "-03" is a real abbreviation
#       for several South American zones that wraps as "<-03>" in the
#       POSIX footer.
subtest 'Numeric abbreviations (-03) are handled correctly' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( '-03' );
    SKIP:
    {
        if( !ok( defined( $results ), '-03 resolved' ) )
        {
            skip( '-03 resolution failed', 2 );
        }
        ok( scalar( @$results ) > 5, 'Multiple zones on -03' );

        # At least one zone (e.g. America/Sao_Paulo) must be is_active=1 for -03,
        # since their footer is "<-03>3".
        my @active = grep{ $_->{is_active} } @$results;
        ok( scalar( @active ) > 0,
            'At least one -03 zone is still active (footer contains <-03>)' );
    };
};

done_testing;

__END__

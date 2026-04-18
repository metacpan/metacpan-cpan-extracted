#!perl
##----------------------------------------------------------------------------
## DateTime::Lite::TimeZone - t/16.extended_aliases.t
## Test suite for resolve_abbreviation() with extended => 1
##----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( looks_like_number );

BEGIN
{
    use_ok( 'DateTime::Lite::TimeZone' ) || BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );
}

# NOTE: Helpers
sub result_zones
{
    my $results = shift( @_ );
    return( [ map{ $_->{zone_name} } @$results ] );
}

sub find_zone
{
    my( $results, $zone_name ) = @_;
    return( ( grep{ $_->{zone_name} eq $zone_name } @$results )[0] );
}

# NOTE:  Abbreviation present in IANA types: extended flag must be ignored
#        CEST is a well-known IANA abbreviation; extended_aliases should never
#        be consulted even when the option 'extended' is passed.
subtest 'IANA abbreviation; extended flag is a no-op' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'CEST', extended => 1 );
    SKIP:
    {
        if( !ok( defined( $results ), 'CEST resolved' ) )
        {
            skip( "Failed resolving abbreviated timezone 'CEST'", 6 );
        }
        ok( scalar( @$results ) > 0,                   'At least one CEST candidate returned' );
        my $first = $results->[0];
        is( $first->{extended}, 0,                     "option 'extended' disabled for IANA result" );
        ok( defined( $first->{utc_offset} ),           'utc_offset defined for IANA result' );
        ok( looks_like_number( $first->{utc_offset} ), 'utc_offset is numeric' );
        ok( defined( $first->{is_dst} ),               'is_dst defined for IANA result' );
        ok( !exists( $first->{is_primary} ),           'is_primary absent from IANA result' );
    };
};

# NOTE: Abbreviation absent from IANA types, unambiguous in extended_aliases
#       AFT (Afghanistan Time) -> Asia/Kabul only; not present in IANA types.
#       (BDT is unsuitable: it exists in IANA types as Bering Daylight Time
#        for America/Adak and America/Nome, so extended is never triggered.)
subtest 'Extended alias; unambiguous single zone (AFT)' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    # Without extended: should fail because AFT is not in IANA types
    my $no_ext = DateTime::Lite::TimeZone->resolve_abbreviation( 'AFT' );
    ok( !defined( $no_ext ), 'AFT fails without option extended enabled' );
    like( DateTime::Lite::TimeZone->error,
          qr/No timezone found/i,
          'Error message mentions no timezone found' );

    # With extended: should return Asia/Kabul
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'AFT', extended => 1 );
    SKIP:
    {
        if( !ok( defined( $results ), "AFT resolved with option 'extended' enabled" ) )
        {
            skip( "Failed resolving abbreviated timezone 'AFT'", 7 );
        }
        is( scalar( @$results ), 1, 'Exactly one candidate for AFT' );
        my $r = $results->[0];
        is( $r->{zone_name},  'Asia/Kabul', 'zone_name is Asia/Kabul' );
        is( $r->{extended},   1,            'extended => 1' );
        is( $r->{is_primary}, 1,            'is_primary => 1' );
        is( $r->{ambiguous},  0,            'ambiguous => 0' );
        ok( !defined( $r->{utc_offset} ),   'utc_offset is undef for extended result' );
        ok( !defined( $r->{is_dst} ),       'is_dst is undef for extended result' );
    };
};

# NOTE: Abbreviation absent from IANA types, ambiguous in extended_aliases
#       IST in extended_aliases has three zones with exactly one is_primary.
#       Depending on the data, ambiguous may be 0 (one primary) or 1 (none).
#       We verify the structural contract rather than hard-coding the value.
subtest 'Extended alias; multi-zone with is_primary (IST check via extended)' => sub
{
    # IST is present in IANA types so extended is not used; verify that first.
    my $iana = DateTime::Lite::TimeZone->resolve_abbreviation( 'IST' );
    ok( defined( $iana ), 'IST present in IANA types' );
    is( $iana->[0]->{extended}, 0, 'IST IANA result has extended => 0' );

    # Use an abbreviation that IS only in extended_aliases and has multiple
    # zones. AMST has America/Manaus and America/Boa_Vista in extended_aliases.
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'AMST', extended => 1 );
    SKIP:
    {
        if( !ok( defined( $results ), "AMST resolved with option 'extended' enabled" ) )
        {
            skip( "Failed resolving abbreviated timezone 'AMST'", 5 );
        }
        ok( scalar( @$results ) >= 1, 'At least one AMST candidate' );
        foreach my $r ( @$results )
        {
            is( $r->{extended},               1, "option 'extended' enabled for $r->{zone_name}" );
            ok( exists( $r->{is_primary} ),      "is_primary key present for $r->{zone_name}" );
            ok( !defined( $r->{utc_offset} ),    "utc_offset undef for $r->{zone_name}" );
        }
        # Exactly one is_primary across all rows
        my $primaries = grep{ $_->{is_primary} } @$results;
        is( $primaries,                 1, 'Exactly one is_primary among AMST candidates' );
        # With one primary and multiple rows: ambiguous => 0
        is( $results->[0]->{ambiguous}, 0, 'ambiguous => 0 when exactly one is_primary' );
    };
};

# NOTE: Abbreviation absent from both IANA types and extended_aliases
subtest 'Unknown abbreviation; error with and without extended' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $r1 = DateTime::Lite::TimeZone->resolve_abbreviation( 'XYZZY' );
    ok( !defined( $r1 ), 'Unknown abbreviation fails without extended' );

    my $r2 = DateTime::Lite::TimeZone->resolve_abbreviation( 'XYZZY', extended => 1 );
    ok( !defined( $r2 ), "Unknown abbreviation fails with option 'extended' enabled" );
    like( DateTime::Lite::TimeZone->error, qr/including extended aliases/i,
          'Error message mentions extended aliases' );
};

# NOTE: JST: present in IANA types; extended result should NOT be returned
subtest 'JST present in IANA types; no extended fallback' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST', extended => 1 );
    ok( defined( $results ),                         'JST resolved' );
    ok( scalar( @$results ) > 0,                     'At least one JST candidate' );
    is( $results->[0]->{extended},            0,     'extended => 0 (came from IANA types)' );
    ok( defined( $results->[0]->{utc_offset} ),      'utc_offset defined' );
    is( $results->[0]->{utc_offset},          32400, 'utc_offset is +09:00 (32400 seconds)' );
};

# NOTE: Structural contract: extended result can be used to build a TimeZone object
subtest 'Extended result zone_name is a valid TimeZone name' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'AFT', extended => 1 );
    SKIP:
    {
        if( !ok( defined( $results ), 'AFT resolved' ) )
        {
            skip( "Failed resolving abbreviated timezone 'AFT'", 2 );
        }
        my $zone_name = $results->[0]{zone_name};
        my $tz = DateTime::Lite::TimeZone->new( name => $zone_name );
        ok( defined( $tz ), "DateTime::Lite::TimeZone->new( name => '$zone_name' ) succeeds" );
        isa_ok( $tz,        'DateTime::Lite::TimeZone' );
    };
};

done_testing;

__END__

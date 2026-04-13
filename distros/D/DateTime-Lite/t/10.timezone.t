#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/10.timezone.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;
use Scalar::Util ();
use Time::Local qw( timegm );

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
use_ok( 'DateTime::Lite::TimeZone' ) or BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );

# NOTE: Constructor - special zones
subtest 'Constructor - special zones' => sub
{
    my $utc = DateTime::Lite::TimeZone->new( name => 'UTC' );
    ok( defined( $utc ),            'UTC: new() succeeds' );
    is( $utc->name,        'UTC',   'UTC: name' );
    is( $utc->is_utc,      1,       'UTC: is_utc' );
    is( $utc->is_floating, 0,       'UTC: not floating' );
    is( $utc->has_dst_changes, 0,   'UTC: no DST' );
    ok( !defined( $utc->country_codes ), 'UTC: country_codes undef' );
    ok( !defined( $utc->coordinates ),   'UTC: zone_coordinates undef' );

    my $fl = DateTime::Lite::TimeZone->new( name => 'floating' );
    ok( defined( $fl ),             'floating: new() succeeds' );
    is( $fl->is_floating,  1,       'floating: is_floating' );
    is( $fl->is_utc,       0,       'floating: not UTC' );
};

# NOTE: Constructor - fixed offset
subtest 'Constructor - fixed offset' => sub
{
    my $tz = DateTime::Lite::TimeZone->new( name => '+09:00' );
    ok( defined( $tz ),   'fixed +09:00: new() succeeds' );
    is( $tz->is_olson, 0, 'fixed: not olson' );
    is( $tz->is_utc,   0, 'fixed: not UTC' );
    ok( !defined( $tz->country_codes ), 'fixed: country_codes undef' );
};

# NOTE: Constructor - named zone and alias
subtest 'Constructor - named zone and alias' => sub
{
    my $tok = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' );
    ok( defined( $tok ),            'Tokyo: new() succeeds' );
    is( $tok->name,   'Asia/Tokyo', 'Tokyo: name' );
    is( $tok->is_olson,         1,  'Tokyo: is_olson' );
    is( $tok->has_dst_changes,  1,  'Tokyo: has DST history' );

    my $east = DateTime::Lite::TimeZone->new( name => 'US/Eastern' );
    ok( defined( $east ),                   'US/Eastern: new() succeeds' );
    is( $east->name, 'America/New_York',    'US/Eastern: resolves alias' );

    # coordinates from zones.coordinates
    my $coords = $tok->coordinates;
    ok( defined( $coords ) && length( $coords ), 'Tokyo: coordinates defined' );
    like( $coords, qr/^[+-]\d+[+-]\d+$/, 'Tokyo: coordinates format' );

    # tz_version from metadata table
    my $ver = $tok->tz_version;
    ok( defined( $ver ) && $ver =~ /^\d{4}[a-z]/, 'tz_version looks like tzdata release' );

    # New schema: datafile
    ok( -e( $tok->datafile ), 'datafile exists' );
};

# NOTE: Constructor - alias resolution (new schema: aliases JOIN zones)
subtest 'Constructor - alias resolution (new schema: aliases JOIN zones)' => sub
{
    my $east = DateTime::Lite::TimeZone->new( name => 'US/Eastern' );
    ok( defined( $east ),                    'US/Eastern: new() succeeds' );
    is( $east->name, 'America/New_York',     'US/Eastern: resolves alias via aliases table' );
    is( $east->is_olson, 1,                  'US/Eastern: resolved zone is_olson' );
};

# NOTE: Constructor - 'local' timezone name
subtest "Constructor - 'local' timezone name" => sub
{
    local $ENV{TZ} = 'Asia/Tokyo';
    my $tz = DateTime::Lite::TimeZone->new( name => 'local' );
    ok( defined( $tz ),          "'local' with TZ=Asia/Tokyo: new() succeeds" );
    is( $tz->name, 'Asia/Tokyo', "'local' resolves to Asia/Tokyo via \$ENV{TZ}" );
    ok( $tz->is_olson,           "'local' resolved zone is_olson" );
    ok( !$tz->is_floating,       "'local' resolved zone is not floating" );

    my $dt = DateTime::Lite->now( time_zone => 'local' );
    ok( defined( $dt ),           "DateTime::Lite->now( time_zone => 'local' ) succeeds" );
    is( $dt->time_zone_long_name, 'Asia/Tokyo',
        "datetime with time_zone => 'local' has correct zone" );
};

# NOTE: country_codes (new schema: zones.countries JSON array)
subtest 'ountry_codes (new schema: zones.countries JSON array)' => sub
{
    my $tok = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' );
    my $cc  = $tok->country_codes;
    # Only test if the production DB has this data; test DBs may omit it
    SKIP:
    {
        skip( 'country_codes not in test DB', 2 ) unless( defined( $cc ) );
        isa_ok( $cc, 'ARRAY', 'country_codes returns arrayref' );
        ok( scalar( grep { $_ eq 'JP' } @$cc ), 'Tokyo country_codes contains JP' );
    }
};

# NOTE: Core lookups - offset, is_dst, short_name
# (new schema: NULL span boundaries, Unix seconds in DB)
subtest 'Core lookups' => sub
{
    # 2026-07-04T15:00Z = summer in New York (EDT)
    my $dt_sum = DateTime::Lite->new(
        year      => 2026,
        month     => 7,
        day       => 4,
        hour      => 15,
        time_zone => 'UTC'
    );
    # 2026-01-15T12:00Z = winter in New York (EST)
    my $dt_win = DateTime::Lite->new(
        year      => 2026,
        month     => 1,
        day       => 15,
        hour      => 12,
        time_zone => 'UTC'
    );

    my $ny = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    is( $ny->offset_for_datetime( $dt_sum ), -14400, 'NY summer offset (EDT=-14400)' );
    is( $ny->is_dst_for_datetime( $dt_sum ),      1, 'NY summer is DST' );
    is( $ny->short_name_for_datetime( $dt_sum ), 'EDT', 'NY summer abbr' );

    is( $ny->offset_for_datetime( $dt_win ), -18000, 'NY winter offset (EST=-18000)' );
    is( $ny->is_dst_for_datetime( $dt_win ),      0, 'NY winter not DST' );
    is( $ny->short_name_for_datetime( $dt_win ), 'EST', 'NY winter abbr' );

    my $tok = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' );
    is( $tok->offset_for_datetime( $dt_sum ), 32400, 'Tokyo offset' );
    is( $tok->is_dst_for_datetime( $dt_sum ),     0, 'Tokyo no DST' );
    is( $tok->short_name_for_datetime( $dt_sum ), 'JST', 'Tokyo abbr' );
};

# NOTE: offset_as_string - class method
subtest 'offset_as_string' => sub
{
    is( DateTime::Lite::TimeZone->offset_as_string(32400),       '+0900',  '+0900' );
    is( DateTime::Lite::TimeZone->offset_as_string(-18000),      '-0500',  '-0500' );
    is( DateTime::Lite::TimeZone->offset_as_string(0),           '+0000',  '+0000' );
    is( DateTime::Lite::TimeZone->offset_as_string(32400, ':'),  '+09:00', '+09:00' );
    is( DateTime::Lite::TimeZone->offset_as_string(-18000, ':'), '-05:00', '-05:00' );
    is( DateTime::Lite::TimeZone->offset_as_string(19800, ':'),  '+05:30', '+05:30' );
};

# NOTE: offset_as_seconds - function, class method, instance method
subtest 'offset_as_seconds' => sub
{
    # Class method call
    is( DateTime::Lite::TimeZone->offset_as_seconds( '+09:00' ),  32400, 'class: +09:00' );
    is( DateTime::Lite::TimeZone->offset_as_seconds( '-05:30' ), -19800, 'class: -05:30' );
    {
        local $SIG{__WARN__} = sub{};
        ok( !defined( DateTime::Lite::TimeZone->offset_as_seconds( undef ) ), 'class: undef -> undef' );
    }

    # Instance method call
    my $tz = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    is( $tz->offset_as_seconds( '+09:00' ),  32400, 'instance: +09:00' );
    is( $tz->offset_as_seconds( '-0500'  ), -18000, 'instance: -0500'  );
    {
        local $SIG{__WARN__} = sub{};
        ok( !defined( $tz->offset_as_seconds( undef ) ), 'instance: undef -> undef' );
    }
};

# NOTE: offset_for_datetime / is_dst / short_name
subtest 'offset_for_datetime / is_dst / short_name' => sub
{
    my $dt_summer = DateTime::Lite->new(
        year        => 2026,
        month       => 7,
        day         => 4,
        hour        => 15,
        time_zone   => 'UTC',
    );
    my $dt_winter = DateTime::Lite->new(
        year        => 2026,
        month       => 1,
        day         => 15,
        hour        => 12,
        time_zone   => 'UTC',
    );

    my $ny = DateTime::Lite::TimeZone->new( name => 'America/New_York' );

    is( $ny->offset_for_datetime( $dt_summer ), -14400,    'NY summer offset (EDT)' );
    is( $ny->is_dst_for_datetime( $dt_summer ),      1,    'NY summer is DST' );
    is( $ny->short_name_for_datetime( $dt_summer ), 'EDT', 'NY summer abbr' );

    is( $ny->offset_for_datetime( $dt_winter ), -18000,    'NY winter offset (EST)' );
    is( $ny->is_dst_for_datetime( $dt_winter ),      0,    'NY winter not DST' );
    is( $ny->short_name_for_datetime( $dt_winter ), 'EST', 'NY winter abbr' );

    my $tok = DateTime::Lite::TimeZone->new( name =>        'Asia/Tokyo' );
    is( $tok->offset_for_datetime( $dt_summer ), 32400,     'Tokyo offset' );
    is( $tok->is_dst_for_datetime( $dt_summer ),     0,     'Tokyo no DST' );
    is( $tok->short_name_for_datetime( $dt_summer ), 'JST', 'Tokyo abbr' );
};

# NOTE: offset_for_local_datetime (new schema NULL local spans)
subtest 'offset_for_local_datetime' => sub
{
    # New York, summer: local 19:00 = UTC 23:00 (EDT, -4h)
    my $dt_local_sum = DateTime::Lite->new(
        year      => 2026,
        month     => 7,
        day       => 4,
        hour      => 19,
        time_zone => 'floating',
    );
    # New York, winter: local 12:00 = UTC 17:00 (EST, -5h)
    my $dt_local_win = DateTime::Lite->new(
        year      => 2026,
        month     => 1,
        day       => 15,
        hour      => 12,
        time_zone => 'floating',
    );

    my $ny = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    is( $ny->offset_for_local_datetime( $dt_local_sum ), -14400,
        'offset_for_local_datetime() summer EDT' );
    is( $ny->offset_for_local_datetime( $dt_local_win ), -18000,
        'offset_for_local_datetime() winter EST' );
};

# NOTE: Integration with DateTime::Lite
subtest 'Integration with DateTime::Lite' => sub
{
    my $tz_tok = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' );

    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 3,
        hour      => 9,
        minute    => 0,
        second    => 0,
        time_zone => $tz_tok,
    );
    ok( defined( $dt ),                     'DT::Lite with TZ obj: constructs' );
    is( $dt->hour,            9,           'DT::Lite with TZ obj: hour preserved' );
    is( $dt->time_zone->name, 'Asia/Tokyo', 'DT::Lite with TZ obj: TZ name' );
    is( $dt->epoch, 1775174400,             'DT::Lite with TZ obj: correct epoch' );

    my $dt2 = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 3,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC',
    );
    $dt2->set_time_zone( $tz_tok );
    is( $dt2->hour,  9,          'set_time_zone with TZ obj: hour shifted' );
    is( $dt2->epoch, 1775174400, 'set_time_zone with TZ obj: epoch unchanged' );
};

# comment (from zones.comment column)
subtest 'comment' => sub
{
    my $ny = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    SKIP:
    {
        skip( 'zone_comment not in test DB', 1 )
            unless defined( $ny->comment ) && length( $ny->comment );
        like( $ny->comment, qr/Eastern/i, 'comment() non-empty and plausible' );
    }

    my $utc = DateTime::Lite::TimeZone->new( name => 'UTC' );
    ok( !defined( $utc->comment ), 'comment() undef for UTC' );
};


# NOTE: Error handling
subtest 'Error handling' => sub
{
    local $SIG{__WARN__} = sub{};
    my $bad = DateTime::Lite::TimeZone->new( name => 'Mars/Olympus' );
    ok( !defined( $bad ),                                         'Unknown TZ: returns undef' );
    ok( defined( DateTime::Lite::TimeZone->error ),               'Unknown TZ: error set' );
    like( DateTime::Lite::TimeZone->error . '',
          qr/Unknown time zone/,                                  'Unknown TZ: error message' );
};

# NOTE: POSIX footer lookup for future dates beyond stored transitions
#
# The tz.sqlite3 DB has stored transitions only up to 2007 for NY and 1996 for
# Paris. Dates beyond those thresholds require the POSIX TZ string from the
# TZif footer (zones.footer_tz_string) to determine the correct offset and DST
# status.
subtest 'POSIX footer lookup' => sub
{
    # Unix-to-RD epoch offset used internally by DateTime::Lite
    my $U = 62_135_683_200;

    my $ny    = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    my $paris = DateTime::Lite::TimeZone->new( name => 'Europe/Paris'     );
    my $tok   = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo'       );
    my $syd   = DateTime::Lite::TimeZone->new( name => 'Australia/Sydney'  );

    # Helper: fake DT object with a fixed RD seconds value
    my $fake = sub
    {
        my $rd = shift( @_ );
        return( bless( { _rd => $rd }, 'FakeDTForFooter' ) );
    };

    # Future UTC offset lookups via _lookup_span -> POSIX footer
    is( $ny->offset_for_datetime( $fake->( timegm(0,0,12,15,0,126) + $U ) ),
        -18000, 'NY 2026-01-15: winter EST (footer UTC lookup)' );

    is( $ny->offset_for_datetime( $fake->( timegm(0,0,15,4,6,126) + $U ) ),
        -14400, 'NY 2026-07-04: summer EDT (footer UTC lookup)' );

    is( $ny->is_dst_for_datetime( $fake->( timegm(0,0,12,15,0,126) + $U ) ),
        0, 'NY 2026-01-15: is_dst=0 (footer)' );

    is( $ny->is_dst_for_datetime( $fake->( timegm(0,0,15,4,6,126) + $U ) ),
        1, 'NY 2026-07-04: is_dst=1 (footer)' );

    is( $ny->short_name_for_datetime( $fake->( timegm(0,0,12,15,0,126) + $U ) ),
        'EST', 'NY 2026-01-15: abbr=EST (footer)' );

    is( $ny->short_name_for_datetime( $fake->( timegm(0,0,15,4,6,126) + $U ) ),
        'EDT', 'NY 2026-07-04: abbr=EDT (footer)' );

    is( $paris->offset_for_datetime( $fake->( timegm(0,0,12,15,0,126) + $U ) ),
        3600, 'Paris 2026-01-15: winter CET (footer)' );

    is( $paris->offset_for_datetime( $fake->( timegm(0,0,15,4,6,126) + $U ) ),
        7200, 'Paris 2026-07-04: summer CEST (footer)' );

    is( $tok->offset_for_datetime( $fake->( timegm(0,0,12,15,0,126) + $U ) ),
        32400, 'Tokyo 2026: JST +9h, no DST (footer)' );

    is( $tok->is_dst_for_datetime( $fake->( timegm(0,0,12,15,0,126) + $U ) ),
        0, 'Tokyo 2026: is_dst=0 (footer)' );

    # DST boundary precision for NY 2026
    # DST start: 2026-03-08 02:00 EST = 07:00 UTC
    is( $ny->offset_for_datetime(
            $fake->( timegm(0,0,6,8,2,2026) + $U ) ),
        -18000, 'NY 2026-03-08 06:00Z: still EST (1h before DST start)' );

    is( $ny->offset_for_datetime(
            $fake->( timegm(0,0,7,8,2,2026) + $U ) ),
        -14400, 'NY 2026-03-08 07:00Z: EDT (exactly at DST start)' );

    # DST end: 2026-11-01 02:00 EDT = 06:00 UTC
    is( $ny->offset_for_datetime(
            $fake->( timegm(0,0,6,1,10,2026) + $U ) ),
        -18000, 'NY 2026-11-01 06:00Z: EST (at DST end)' );

    # Southern hemisphere: Australia/Sydney (DST in austral summer)
    # AEST-10AEDT,M10.1.0,M4.1.0/3
    is( $syd->offset_for_datetime( $fake->( timegm(0,0,12,15,0,126) + $U ) ),
        39600, 'Sydney 2026-01-15: AEDT +11h (austral summer, footer)' );

    is( $syd->is_dst_for_datetime( $fake->( timegm(0,0,12,15,0,126) + $U ) ),
        1, 'Sydney 2026-01-15: is_dst=1 (austral summer, footer)' );

    is( $syd->offset_for_datetime( $fake->( timegm(0,0,12,1,6,126) + $U ) ),
        36000, 'Sydney 2026-07-02: AEST +10h (austral winter, footer)' );

    is( $syd->is_dst_for_datetime( $fake->( timegm(0,0,12,1,6,126) + $U ) ),
        0, 'Sydney 2026-07-02: is_dst=0 (austral winter, footer)' );

    # Future local-time lookups via _lookup_span_local -> POSIX footer
    my $dt_local_win = DateTime::Lite->new(
        year      => 2026,
        month     => 1,
        day       => 15,
        hour      => 12,
        time_zone => 'floating',
    );
    my $dt_local_sum = DateTime::Lite->new(
        year      => 2026,
        month     => 7,
        day       => 4,
        hour      => 19,
        time_zone => 'floating',
    );

    is( $ny->offset_for_local_datetime( $dt_local_win ),
        -18000, 'NY 2026-01 local winter: EST (footer local lookup)' );

    is( $ny->offset_for_local_datetime( $dt_local_sum ),
        -14400, 'NY 2026-07 local summer: EDT (footer local lookup)' );
};

# Minimal fake DT package for footer tests above
package
    FakeDTForFooter;
sub utc_rd_as_seconds   { return $_[0]->{_rd} }
sub local_rd_as_seconds { return $_[0]->{_rd} }
package main;

# NOTE: Memory cache: use_cache_mem, enable_mem_cache, disable_mem_cache,
#                     clear_mem_cache
subtest 'Memory cache (use_cache_mem)' => sub
{
    # Default: no cache - each new() returns a distinct object
    my $tz1 = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' );
    my $tz2 = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' );
    isnt( Scalar::Util::refaddr( $tz1 ), Scalar::Util::refaddr( $tz2 ),
          'no cache (default): new() returns distinct objects' );

    # use_cache_mem => 1 on each call
    my $tz3 = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo', use_cache_mem => 1 );
    my $tz4 = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo', use_cache_mem => 1 );
    is( Scalar::Util::refaddr( $tz3 ), Scalar::Util::refaddr( $tz4 ),
        'use_cache_mem => 1: second call returns cached object' );
    is( $tz3->name, 'Asia/Tokyo', 'cached object has correct name' );

    # Alias also hits cache
    my $tz5 = DateTime::Lite::TimeZone->new( name => 'Japan', use_cache_mem => 1 );
    is( $tz5->name, 'Asia/Tokyo', 'alias resolves to canonical name' );
    my $tz6 = DateTime::Lite::TimeZone->new( name => 'Japan', use_cache_mem => 1 );
    is( Scalar::Util::refaddr( $tz5 ), Scalar::Util::refaddr( $tz6 ), 'alias also cached' );

    # enable_mem_cache class method - affects all subsequent new() calls
    DateTime::Lite::TimeZone->enable_mem_cache;
    my $tz7 = DateTime::Lite::TimeZone->new( name => 'Etc/UTC' );
    my $tz8 = DateTime::Lite::TimeZone->new( name => 'Etc/UTC' );
    is( Scalar::Util::refaddr( $tz7 ), Scalar::Util::refaddr( $tz8 ),
        'enable_mem_cache: class-level cache active' );

    # disable_mem_cache clears the cache and disables it
    DateTime::Lite::TimeZone->disable_mem_cache;
    my $tz9 = DateTime::Lite::TimeZone->new( name => 'Etc/UTC' );
    isnt( Scalar::Util::refaddr( $tz7 ), Scalar::Util::refaddr( $tz9 ),
          'disable_mem_cache: cache cleared, new object returned' );

    # clear_mem_cache leaves cache enabled but empties it
    DateTime::Lite::TimeZone->enable_mem_cache;
    my $tz10 = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' );
    DateTime::Lite::TimeZone->clear_mem_cache;
    my $tz11 = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' );
    isnt( Scalar::Util::refaddr( $tz10 ), Scalar::Util::refaddr( $tz11 ),
          'clear_mem_cache: cache emptied, new object constructed' );
    # But cache is still enabled, so tz11 is now cached
    my $tz12 = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' );
    is( Scalar::Util::refaddr( $tz11 ), Scalar::Util::refaddr( $tz12 ),
        'after clear_mem_cache: newly constructed object is re-cached' );

    # Clean up: disable for remaining tests
    DateTime::Lite::TimeZone->disable_mem_cache;
};

# Span cache: active when use_cache_mem => 1
# _span_cache and _span_cache_local are initialised as {} when
# the object is placed in the mem cache.
subtest 'Memory cache (use_cache_mem) -> spans cache' => sub
{
    my $tz = DateTime::Lite::TimeZone->new(
        name          => 'America/New_York',
        use_cache_mem => 1,
    );
    ok( defined( $tz->{_span_cache} ),
        'span cache slot exists when use_cache_mem => 1' );
    ok( defined( $tz->{_span_cache_local} ),
        'local span cache slot exists when use_cache_mem => 1' );

    # Without cache: no span cache slot
    DateTime::Lite::TimeZone->disable_mem_cache;
    my $tz2 = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    ok( !defined( $tz2->{_span_cache} ),
        'no span cache slot without use_cache_mem' );

    # Trigger a lookup to populate the cache
    my $rd_secs = 739715 * 86400 + 43200;  # 2026-04-09 12:00 UTC in RD secs
    my $span1 = $tz->_lookup_span( $rd_secs );
    ok( defined( $span1 ) && defined( $span1->{offset} ),
        '_lookup_span returns a span' );
    is( ref( $tz->{_span_cache} ), 'HASH',
        'span cache populated after _lookup_span' );

    # Second call must return the identical hashref (cache hit)
    my $span2 = $tz->_lookup_span( $rd_secs );
    is( $span1, $span2,
        '_lookup_span returns cached hashref on second call' );

    # Same span for a nearby timestamp (within same DST period)
    my $span3 = $tz->_lookup_span( $rd_secs + 3600 );
    is( $span1, $span3,
        'nearby timestamp within same span hits cache' );

    # Cache cleared when disable_mem_cache is called
    DateTime::Lite::TimeZone->disable_mem_cache;
};

done_testing;

__END__

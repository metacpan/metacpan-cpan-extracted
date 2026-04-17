# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime Format Lite - t/85.serialisation.t
## Tests for FREEZE/THAW (Sereal/CBOR), STORABLE_freeze/STORABLE_thaw, and
## TO_JSON serialisation.
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More qw( no_plan );

use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );

# NOTE: helper - builds a representative formatter object for round-trip tests
sub _make_fmt
{
    my %extra = @_;
    return( DateTime::Format::Lite->new(
        pattern   => '%Y-%m-%dT%H:%M:%S',
        locale    => 'fr',
        time_zone => 'Asia/Tokyo',
        on_error  => 'undef',
        strict    => 0,
        debug     => 0,
        zone_map  => { EST => '-0500' },
        %extra,
    ) || die( DateTime::Format::Lite->error ) );
}

# NOTE: helper; verifies that a thawed/restored object has the expected state
sub _check_state
{
    my( $orig, $restored, $label ) = @_;
    $label //= 'restored';
    is( $restored->pattern, $orig->pattern, "$label: pattern preserved" );
    is( $restored->strict,  $orig->strict,  "$label: strict preserved"  );
    is( $restored->debug,   $orig->debug,   "$label: debug preserved"   );

    if( defined( $orig->time_zone ) )
    {
        ok( defined( $restored->time_zone ), "$label: time_zone defined" );
        is( $restored->time_zone->name, $orig->time_zone->name,
            "$label: time_zone name preserved" );
    }

    if( $orig->locale )
    {
        ok( defined( $restored->locale ), "$label: locale defined" );
        my $orig_locale     = $orig->locale->as_string;
        my $restored_locale = $restored->locale->as_string;
        is( $restored_locale, $orig_locale, "$label: locale preserved" );
    }

    if( scalar( keys( %{$orig->zone_map} ) ) )
    {
        is_deeply( $restored->zone_map, $orig->zone_map, "$label: zone_map preserved" );
    }
}

# NOTE: TO_JSON returns a plain hashref
subtest 'TO_JSON returns hashref' => sub
{
    my $fmt = _make_fmt();
    my $json = $fmt->TO_JSON;
    ok( defined( $json ),             'TO_JSON returns defined value'  );
    ok( ref( $json ) eq 'HASH',       'TO_JSON returns hashref'        );
    is( $json->{pattern},   '%Y-%m-%dT%H:%M:%S',  'pattern in JSON'    );
    is( $json->{on_error},  'undef',              'on_error in JSON'   );
    is( $json->{strict},    0,                    'strict in JSON'     );
    is( $json->{debug},     0,                    'debug in JSON'      );
    is( $json->{time_zone}, 'Asia/Tokyo',         'time_zone in JSON'  );
    ok( defined( $json->{locale} ),               'locale in JSON'     );
    ok( ref( $json->{zone_map} ) eq 'HASH',       'zone_map in JSON'   );
};

# NOTE: TO_JSON zone_map content
subtest 'TO_JSON zone_map content' => sub
{
    my $fmt = _make_fmt();
    my $json = $fmt->TO_JSON;
    is( $json->{zone_map}{EST}, '-0500', 'zone_map entry preserved in TO_JSON' );
};

# NOTE: TO_JSON with no time_zone
subtest 'TO_JSON without time_zone' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d',
        on_error => 'undef',
    ) || die( DateTime::Format::Lite->error );
    my $json = $fmt->TO_JSON;
    ok( !defined( $json->{time_zone} ), 'time_zone is undef in JSON when not set' );
};

# NOTE: TO_JSON on_error coderef falls back to 'undef' with warning
subtest 'TO_JSON coderef on_error falls back gracefully' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y',
        on_error => sub{},
    ) || die( DateTime::Format::Lite->error );

    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $json;
    # Should not die; should return 'undef' string for on_error
    local $@;
    eval{ $json = $fmt->TO_JSON };
    ok( !$@, 'TO_JSON does not die with coderef on_error' );
    is( $json->{on_error}, 'undef', 'coderef on_error serialised as undef' );
};

# NOTE: FREEZE returns class and state
subtest 'FREEZE returns class and state' => sub
{
    my $fmt = _make_fmt();
    my( $class, $state ) = $fmt->FREEZE( 'CBOR' );
    is( $class, 'DateTime::Format::Lite', 'FREEZE first element is class name' );
    ok( ref( $state ) eq 'HASH',          'FREEZE second element is hashref'   );
    is( $state->{pattern}, '%Y-%m-%dT%H:%M:%S', 'pattern in FREEZE state'      );
};

# NOTE: THAW round-trip (CBOR style - class + hashref)
subtest 'THAW round-trip' => sub
{
    my $orig = _make_fmt();
    my( $class, $state ) = $orig->FREEZE( 'CBOR' );

    my $restored = DateTime::Format::Lite->THAW( 'CBOR', $class, $state );
    ok( defined( $restored ), 'THAW returns defined object' );
    isa_ok( $restored, 'DateTime::Format::Lite' );
    _check_state( $orig, $restored, 'THAW' );
};

# NOTE: THAW restores a working parser
subtest 'THAW produces working formatter' => sub
{
    my $orig = _make_fmt();
    my( $class, $state ) = $orig->FREEZE( 'CBOR' );
    my $restored = DateTime::Format::Lite->THAW( 'CBOR', $class, $state );
    ok( defined( $restored ), 'THAW returned object' );

    my $dt = $restored->parse_datetime( '2026-04-14T09:00:00' );
    ok( defined( $dt ), 'restored formatter can parse_datetime' );
    is( $dt->year,  2026, 'year correct after THAW' );
    is( $dt->month,    4, 'month correct after THAW' );
};

# NOTE: Storable round-trip
subtest 'Storable round-trip' => sub
{
    SKIP:
    {
        if( !eval{ require Storable; 1 } )
        {
            skip( 'Storable not available', 3 );
        }
        my $orig     = _make_fmt();
        my $frozen   = Storable::freeze( $orig );
        ok( defined( $frozen ), 'Storable::freeze succeeded' );
    
        my $restored = Storable::thaw( $frozen );
        ok( defined( $restored ), 'Storable::thaw returned object' );
        isa_ok( $restored, 'DateTime::Format::Lite' );
        _check_state( $orig, $restored, 'Storable' );
    };
};

# NOTE: Storable round-trip produces working formatter
subtest 'Storable round-trip produces working formatter' => sub
{
    SKIP:
    {
        if( !eval{ require Storable; 1 } )
        {
            skip( 'Storable not available', 3 );
        }

        my $orig     = _make_fmt();
        my $restored = Storable::thaw( Storable::freeze( $orig ) );
        ok( defined( $restored ), 'thawed object defined' );

        my $dt = $restored->parse_datetime( '2026-04-14T09:00:00' );
        ok( defined( $dt ), 'thawed formatter can parse_datetime' );
        is( $dt->year, 2026, 'year correct after Storable round-trip' );
    };
};

# NOTE: Storable::dclone (clone via freeze/thaw)
subtest 'Storable::dclone' => sub
{
    SKIP:
    {
        if( !eval{ require Storable; 1 } )
        {
            skip( 'Storable not available', 2 );
        }

        my $orig  = _make_fmt();
        my $clone = Storable::dclone( $orig );
        ok( defined( $clone ), 'dclone succeeded' );
        isnt( $clone, $orig,   'clone is a different reference' );
        _check_state( $orig, $clone, 'dclone' );
    };
};

# NOTE: Sereal round-trip (optional)
subtest 'Sereal round-trip' => sub
{
    SKIP:
    {
        if( !eval{ require Sereal::Encoder; require Sereal::Decoder; 1 } )
        {
            skip( 'Sereal not available', 3 );
        }

        my $orig    = _make_fmt();
        # freeze_callbacks => 1 tells Sereal to honour FREEZE/THAW hooks, which
        # avoids serialising internal objects (such as DBI handles buried inside
        # DateTime::Locale::FromCLDR) by introspection.
        my $encoder = Sereal::Encoder->new({ freeze_callbacks => 1 });
        my $decoder = Sereal::Decoder->new({ refuse_objects => 0 });
        my $frozen  = $encoder->encode( $orig );
        ok( defined( $frozen ), 'Sereal encode succeeded' );

        my $restored = $decoder->decode( $frozen );
        ok( defined( $restored ), 'Sereal decode returned object' );
        isa_ok( $restored, 'DateTime::Format::Lite' );
        _check_state( $orig, $restored, 'Sereal' );
    };
};

# NOTE: JSON serialisation round-trip via TO_JSON
subtest 'JSON round-trip via TO_JSON' => sub
{
    SKIP:
    {
        if( !eval{ require JSON; 1 } )
        {
            skip( 'JSON module not available', 3 );
        }

        my $orig    = _make_fmt();
        my $json_str = JSON::encode_json( $orig->TO_JSON );
        ok( defined( $json_str ), 'JSON encode succeeded' );

        my $state    = JSON::decode_json( $json_str );
        ok( ref( $state ) eq 'HASH', 'decoded JSON is a hashref' );

        # Reconstruct from the decoded state
        my $restored = DateTime::Format::Lite->new( %$state );
        ok( defined( $restored ), 'reconstruct from JSON state succeeded' );
        _check_state( $orig, $restored, 'JSON' );
    };
};

done_testing;

__END__

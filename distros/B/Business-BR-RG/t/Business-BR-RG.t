use Test::More tests => 8;

BEGIN { use_ok('Business::BR::RG') }

use Business::BR::RG qw /canon_rg test_rg random_rg format_rg parse_rg/;

ok( test_rg('48.391.390-x'), 'test_rg test' );
is( canon_rg('11.456.789-x'), '11456789X', 'canon_rg test' );

is( test_rg('48.190.390-X'), 0, 'invalid test_rg test' );

is( format_rg('48.19.0.3.9.0.X'), '48.190.390-X', 'format_rg test' );

my ( $base, $dv ) = parse_rg('48.19.0.3.9.0.X');
is( $base, '48190390', 'parsing RG works (base list context)' );
is( $dv,   'X',        'parsing RG works (DV list context)' );

my $info = parse_rg('48.19.0.3.9.0.X');
is_deeply(
    $info,
    { base => '48190390', dv => 'X' },
    'parsing RG works (scalar context)'
);


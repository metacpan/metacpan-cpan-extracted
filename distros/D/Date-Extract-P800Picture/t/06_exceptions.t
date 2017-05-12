use Test::More;

my %invalids = (
    '000Z0001.JPG' => [
        undef,
        q{No date found in filename '000Z0001.JPG'},
        'invalid hour caught'
    ],
    '00Z00001.JPG' => [
        undef,
        q{No date found in filename '00Z00001.JPG'},
        'invalid day caught'
    ],
    '0Z000001.JPG' => [
        undef,
        q{No date found in filename '0Z000001.JPG'},
        'invalid month caught'
    ],
    "Schwern.jpg" => [
        undef,
        q{No date found in filename 'Schwern.jpg'},
        'invalid filename caught'
    ],
    '31S60001.JPG' => [
        undef,
qr/^Invalid\ day\ of\ month\ \(day\ =\ 29\ -\ month\ =\ 2(\ -\ year\ =\ 2003)?\)/msx,
        'invalid date 2003-02-29 caught'
    ],
    '31T60001.JPG' => [
        undef,
qr/^Invalid\ day\ of\ month\ \(day\ =\ 30\ -\ month\ =\ 2(\ -\ year\ =\ 2003)?\)/msx,
        'Invalid day of month (day = 30 - month = 2 - year = 2003)',
        'invalid date 2003-02-30 caught'
    ],
    '31U60001.JPG' => [
        undef,
qr/^Invalid\ day\ of\ month\ \(day\ =\ 31\ -\ month\ =\ 2(\ -\ year\ =\ 2003)?\)/msx,
        'Invalid day of month (day = 31 - month = 2 - year = 2003)',
        'invalid date 2003-02-31 caught'
    ],
    '33U60001.JPG' => [
        undef,
qr/^Invalid\ day\ of\ month\ \(day\ =\ 31\ -\ month\ =\ 4(\ -\ year\ =\ 2003)?\)/msx,
        'Invalid day of month (day = 31 - month = 4 - year = 2003)',
        'invalid date 2003-04-31 caught'
    ],
    '35U60001.JPG' => [
        undef,
qr/^Invalid\ day\ of\ month\ \(day\ =\ 31\ -\ month\ =\ 6(\ -\ year\ =\ 2003)?\)/msx,
        'Invalid day of month (day = 31 - month = 6 - year = 2003)',
        'invalid date 2003-06-31 caught'
    ],
    '38U60001.JPG' => [
        undef,
qr/^Invalid\ day\ of\ month\ \(day\ =\ 31\ -\ month\ =\ 9(\ -\ year\ =\ 2003)?\)/msx,
        'Invalid day of month (day = 31 - month = 9 - year = 2003)',
        'invalid date 2003-09-31 caught'
    ],
    '3AU60001.JPG' => [
        undef,
qr/^Invalid\ day\ of\ month\ \(day\ =\ 31\ -\ month\ =\ 11(\ -\ year\ =\ 2003)?\)/msx,
        'invalid date 2003-11-31 caught'
    ],
);

plan tests => 2 * ( 0 + keys %invalids );

use Date::Extract::P800Picture;
my $parser = Date::Extract::P800Picture->new();
while ( my ( $filename, $expect ) = each %invalids ) {
    is( eval '$parser->extract($filename)', $expect->[0], $expect->[2] );
    if ( ref $expect->[1] eq 'Regexp' ) {
        like( $@, $expect->[1], 'error message for ' . $expect->[2] );
    }
    else {
        is( $@, $expect->[1], 'error message for ' . $expect->[2] );
    }
}

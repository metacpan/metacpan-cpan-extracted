use Test::More;

my %boundaries = (
    '00000000.JPG',
    [ '2000-01-01T00:00:00', 'lower boundary works' ],
    'ZBUN9999.JPG',
    [ '2035-12-31T23:00:00', 'upper boundary works' ],
    '01S00000.jpg',
    [ '2000-02-29T00:00:00', 'februari 29th 2000 works' ],
    '41S00000.jpg',
    [ '2004-02-29T00:00:00', 'februari 29th 2004 works' ],
    '81S00000.jpg',
    [ '2008-02-29T00:00:00', 'februari 29th 2008 works' ],
    'C1S00000.jpg',
    [ '2012-02-29T00:00:00', 'februari 29th 2012 works' ],
    'G1S00000.jpg',
    [ '2016-02-29T00:00:00', 'februari 29th 2016 works' ],
    'K1S00000.jpg',
    [ '2020-02-29T00:00:00', 'februari 29th 2020 works' ],
    'O1S00000.jpg',
    [ '2024-02-29T00:00:00', 'februari 29th 2024 works' ],
    'S1S00000.jpg',
    [ '2028-02-29T00:00:00', 'februari 29th 2028 works' ],
    'W1S00000.jpg',
    [ '2032-02-29T00:00:00', 'februari 29th 2032 works' ],
    '32UI0000.jpg',
    [ '2003-03-31T18:00:00', 'march 31st 2003 works' ],
    '330I0000.jpg',
    [ '2003-04-01T18:00:00', 'rollover to april 1st 2003 works' ],
    '3BUN0000.jpg',
    [ '2003-12-31T23:00:00', 'december 31st 2003 works' ],
    '40000000.jpg',
    [ '2004-01-01T00:00:00', 'rollover to januari 1st 2004 works' ],
);

plan tests => 0 + keys %boundaries;

use Date::Extract::P800Picture;
my $parser = Date::Extract::P800Picture->new();
while ( my ( $filename, $expect ) = each %boundaries ) {
    is( "@{[$parser->extract($filename)]}", $expect->[0], $expect->[1] );
}

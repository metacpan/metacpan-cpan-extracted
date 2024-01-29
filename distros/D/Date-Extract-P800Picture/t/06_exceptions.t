# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.014;
use strict;
use warnings;
use utf8;
use English qw(-no_match_vars);

use Test::More;

our $VERSION = v1.1.7;
my %invalids = (
    '000Z0001.JPG' => [
        undef,
        q{No date found in filename '000Z0001.JPG'},
        'invalid hour caught',
    ],
    '00Z00001.JPG' => [
        undef,
        q{No date found in filename '00Z00001.JPG'},
        'invalid day caught',
    ],
    '0Z000001.JPG' => [
        undef,
        q{No date found in filename '0Z000001.JPG'},
        'invalid month caught',
    ],
    'Schwern.jpg' => [
        undef,
        q{No date found in filename 'Schwern.jpg'},
        'invalid filename caught',
    ],
    '31S60001.JPG' => [
        undef,
## no critic (ProhibitComplexRegexes)
        qr{
    ^Invalid\sday\sof\smonth\s
    [(]day\s=\s29\s-\smonth\s=\s2(\s-\syear\s=\s2003)?[)]
}msx,
## use critic
        'invalid date 2003-02-29 caught',
    ],
    '31T60001.JPG' => [
        undef,
## no critic (ProhibitComplexRegexes)
        qr{
    ^Invalid\sday\sof\smonth\s
    [(]day\s=\s30\s-\smonth\s=\s2(\s-\syear\s=\s2003)?[)]
}msx,
## use critic
        'Invalid day of month (day = 30 - month = 2 - year = 2003)',
        'invalid date 2003-02-30 caught',
    ],
    '31U60001.JPG' => [
        undef,
## no critic (ProhibitComplexRegexes)
        qr{^Invalid\sday\sof\smonth\s
    [(]day\s=\s31\s-\smonth\s=\s2(\s-\syear\s=\s2003)?[)]
}msx,
## use critic
        'Invalid day of month (day = 31 - month = 2 - year = 2003)',
        'invalid date 2003-02-31 caught',
    ],
    '33U60001.JPG' => [
        undef,
## no critic (ProhibitComplexRegexes)
        qr{
    ^Invalid\sday\sof\smonth\s
    [(]day\s=\s31\s-\smonth\s=\s4(\s-\syear\s=\s2003)?[)]
}msx,
## use critic
        'Invalid day of month (day = 31 - month = 4 - year = 2003)',
        'invalid date 2003-04-31 caught',
    ],
    '35U60001.JPG' => [
        undef,
## no critic (ProhibitComplexRegexes)
        qr{
    ^Invalid\sday\sof\smonth\s
    [(]day\s=\s31\s-\smonth\s=\s6(\s-\syear\s=\s2003)?[)]
}msx,
## use critic
        'Invalid day of month (day = 31 - month = 6 - year = 2003)',
        'invalid date 2003-06-31 caught',
    ],
    '38U60001.JPG' => [
        undef,
## no critic (ProhibitComplexRegexes)
        qr{
    ^Invalid\sday\sof\smonth\s
    [(]day\s=\s31\s-\smonth\s=\s9(\s-\syear\s=\s2003)?[)]
}msx,
## use critic
        'Invalid day of month (day = 31 - month = 9 - year = 2003)',
        'invalid date 2003-09-31 caught',
    ],
    '3AU60001.JPG' => [
        undef,
## no critic (ProhibitComplexRegexes)
        qr{
    ^Invalid\sday\sof\smonth\s
    [(]day\s=\s31\s-\smonth\s=\s11(\s-\syear\s=\s2003)?[)]
}msx,
## use critic
        'invalid date 2003-11-31 caught',
    ],
);

Test::More::plan 'tests' => 2 * ( 0 + keys %invalids );

use Date::Extract::P800Picture;
my $parser = Date::Extract::P800Picture->new();
while ( my ( $filename, $expect ) = each %invalids ) {
    Test::More::is(
## no critic (RequireCheckingReturnValueOfEval)
        eval { $parser->extract($filename); },
## use critic
## no critic (ProhibitAccessOfPrivateData)
        $expect->[0], $expect->[2],
## use critic
    );
## no critic (ProhibitAccessOfPrivateData)
    if ( 'Regexp' eq ref $expect->[1] ) {
## use critic
        Test::More::like(
            $EVAL_ERROR,
## no critic (ProhibitAccessOfPrivateData)
            $expect->[1], 'error message for ' . $expect->[2],
## use critic
        );
    }
    else {
        Test::More::is(
            $EVAL_ERROR,
## no critic (ProhibitAccessOfPrivateData)
            $expect->[1], 'error message for ' . $expect->[2],
## use critic
        );
    }
}

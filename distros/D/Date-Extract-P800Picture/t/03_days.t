# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.014;
use strict;
use warnings;
use utf8;
use Readonly;

use Test::More;
our $VERSION = v1.1.7;

BEGIN {
## no critic (ProhibitCallsToUnexportedSubs)
    Readonly::Scalar my $BASE_TESTS => 31;
## use critic
    Test::More::plan 'tests' => $BASE_TESTS;
}

my %days = (
    '00000001.JPG' => [ '2000-01-01T00:00:00', '1st' ],
    '00100001.JPG' => [ '2000-01-02T00:00:00', '2nd' ],
    '00200001.JPG' => [ '2000-01-03T00:00:00', '3rd' ],
    '00300001.JPG' => [ '2000-01-04T00:00:00', '4th' ],
    '00400001.JPG' => [ '2000-01-05T00:00:00', '5th' ],
    '00500001.JPG' => [ '2000-01-06T00:00:00', '6th' ],
    '00600001.JPG' => [ '2000-01-07T00:00:00', '7th' ],
    '00700001.JPG' => [ '2000-01-08T00:00:00', '8th' ],
    '00800001.JPG' => [ '2000-01-09T00:00:00', '9th' ],
    '00900001.JPG' => [ '2000-01-10T00:00:00', '10th' ],
    '00A00001.JPG' => [ '2000-01-11T00:00:00', '11th' ],
    '00B00001.JPG' => [ '2000-01-12T00:00:00', '12th' ],
    '00C00001.JPG' => [ '2000-01-13T00:00:00', '13th' ],
    '00D00001.JPG' => [ '2000-01-14T00:00:00', '14th' ],
    '00E00001.JPG' => [ '2000-01-15T00:00:00', '15th' ],
    '00F00001.JPG' => [ '2000-01-16T00:00:00', '16th' ],
    '00G00001.JPG' => [ '2000-01-17T00:00:00', '17th' ],
    '00H00001.JPG' => [ '2000-01-18T00:00:00', '18th' ],
    '00I00001.JPG' => [ '2000-01-19T00:00:00', '19th' ],
    '00J00001.JPG' => [ '2000-01-20T00:00:00', '20th' ],
    '00K00001.JPG' => [ '2000-01-21T00:00:00', '21st' ],
    '00L00001.JPG' => [ '2000-01-22T00:00:00', '22nd' ],
    '00M00001.JPG' => [ '2000-01-23T00:00:00', '23rd' ],
    '00N00001.JPG' => [ '2000-01-24T00:00:00', '24th' ],
    '00O00001.JPG' => [ '2000-01-25T00:00:00', '25th' ],
    '00P00001.JPG' => [ '2000-01-26T00:00:00', '26th' ],
    '00Q00001.JPG' => [ '2000-01-27T00:00:00', '27th' ],
    '00R00001.JPG' => [ '2000-01-28T00:00:00', '28th' ],
    '00S00001.JPG' => [ '2000-01-29T00:00:00', '29th' ],
    '00T00001.JPG' => [ '2000-01-30T00:00:00', '30th' ],
    '00U00001.JPG' => [ '2000-01-31T00:00:00', '31st' ],
);

use Date::Extract::P800Picture;
my $parser = Date::Extract::P800Picture->new();
while ( my ( $filename, $expect ) = each %days ) {
    Test::More::is(
        "@{[$parser->extract($filename)]}",
## no critic (ProhibitAccessOfPrivateData)
        $expect->[0], $expect->[1],
## use critic
    );
}

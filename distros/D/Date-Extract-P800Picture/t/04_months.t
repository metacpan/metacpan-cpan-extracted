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
    Readonly::Scalar my $BASE_TESTS => 12;
## use critic
    Test::More::plan 'tests' => $BASE_TESTS;
}

my %months = (
    '00000001.JPG' => [ '2000-01-01T00:00:00', 'januari' ],
    '01000001.JPG' => [ '2000-02-01T00:00:00', 'februari' ],
    '02000001.JPG' => [ '2000-03-01T00:00:00', 'march' ],
    '03000001.JPG' => [ '2000-04-01T00:00:00', 'april' ],
    '04000001.JPG' => [ '2000-05-01T00:00:00', 'may' ],
    '05000001.JPG' => [ '2000-06-01T00:00:00', 'june' ],
    '06000001.JPG' => [ '2000-07-01T00:00:00', 'july' ],
    '07000001.JPG' => [ '2000-08-01T00:00:00', 'august' ],
    '08000001.JPG' => [ '2000-09-01T00:00:00', 'september' ],
    '09000001.JPG' => [ '2000-10-01T00:00:00', 'october' ],
    '0A000001.JPG' => [ '2000-11-01T00:00:00', 'november' ],
    '0B000001.JPG' => [ '2000-12-01T00:00:00', 'december' ],
);

use Date::Extract::P800Picture;
my $parser = Date::Extract::P800Picture->new();
while ( my ( $filename, $expect ) = each %months ) {
    Test::More::is(
        "@{[$parser->extract($filename)]}",
## no critic (ProhibitAccessOfPrivateData)
        $expect->[0], $expect->[1],
## use critic
    );
}

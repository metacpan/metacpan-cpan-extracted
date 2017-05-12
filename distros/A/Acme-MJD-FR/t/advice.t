#!perl

use strict;
use warnings;
use Test::More tests => 2;

use Acme::MJD::FR;

my $advice = Acme::MJD::FR::advice;
like( $advice, qr/^#\d+ / );
$advice = Acme::MJD::FR::advice(11932);
is( $advice, "#11932 Sapristi.\n" );

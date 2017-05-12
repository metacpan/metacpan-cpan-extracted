# $Id$

use strict;


use Test::More qw/no_plan/;
use CGI::Session;

my %tests = (
    '1m'     => '60',
    '+1m'    => '60',
    '-1m'    => '-60',
    '1h'    => '3600',
    '1h'    => '3600',
    '1s'      => 1,
    '1m'      => 60,
    '1h'      => 3600,
    '1d'      => 86400,
    '1w'      => 604800,
    '1M'      => 2592000,
    '1y'      => 31536000,
);

while (my ($in, $out) = each %tests) {
    is( CGI::Session::_str2seconds(undef,$in), $out, "got expected result when converting $in to seconds");
}



#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::RequiresInternet;

BEGIN { use_ok('CGI::Lingua') }

local $ENV{'REMOTE_ADDR'} = '45.128.139.41';

my $lingua = new_ok('CGI::Lingua' => [
	supported => ['en-gb']
]);

# Bypass the local geo databases, which can be stale: Debian's frozen
# geoip-database (GeoIP.dat, 2019-12-24) maps this IP to 'gp', and
# Geo::IPfree maps it to 'in'.  Exercise the online lookup path instead.
$lingua->{_have_ipcountry} = 0;
$lingua->{_have_geoip} = 0;
$lingua->{_have_geoipfree} = 0;

cmp_ok($lingua->country(), 'eq', 'gb');

done_testing();

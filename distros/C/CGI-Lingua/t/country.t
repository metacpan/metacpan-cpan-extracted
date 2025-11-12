#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::RequiresInternet;

use lib 't/lib';

BEGIN { use_ok('CGI::Lingua') }

local $ENV{'REMOTE_ADDR'} = '45.128.139.41';

my $lingua = new_ok('CGI::Lingua' => [
	supported => ['en-gb']
]);

cmp_ok($lingua->country(), 'eq', 'gb');

done_testing();

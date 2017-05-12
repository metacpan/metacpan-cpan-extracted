use strict;
use Config;

use Test::More tests => 2;


my $v = `$Config{perlpath} -I lib bin/session-token`;
chomp $v;

like($v, qr/^[A-Za-z0-9]{22}$/, "simple random token");


$v = `$Config{perlpath} -I lib bin/session-token --null-seed`;
chomp $v;

is($v, "8AgSJF8AQLroflWRXq3alI", "null-seed output");

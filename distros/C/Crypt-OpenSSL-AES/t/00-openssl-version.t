use strict;
use warnings;
use File::Which qw(which);
use Test::More tests => 1;

my $openssl = which('openssl');
like($openssl, qr/openssl/, "Found openssl");
print "$openssl version: ";

my $version = `$openssl version`;
diag($version);

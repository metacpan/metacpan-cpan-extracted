#!perl -w
use Devel::Confess;
use Data::Mirror qw(:all);
use Test;
use vars qw($result);
use strict;

BEGIN { plan tests => 6 }

#
# let's speed up repeated runs by caching everything for a day
#
$Data::Mirror::TTL_SECONDS = 86400;

#
# string mirror
#
$result = mirror_str('https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/README.md');
ok(length($result) > 0 ? 1 : 0);

#
# file mirror
#
$result = mirror_file('https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/README.md');
ok(-e $result ? 1 : 0);

#
# filehandle mirror
#
$result = mirror_fh('https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/README.md');
if ($result->isa('IO::File')) {
    $result->close;
    ok(1);

} else {
    ok(0);

}

#
# JSON mirror
#
$result = mirror_json('https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/example.json');
ok('HASH' eq ref($result) ? 1 : 0);

#
# YAML mirror
#
$result = mirror_yaml('https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/example.yaml');
ok('HASH' eq ref($result) ? 1 : 0);

#
# CSV mirror
#
$result = mirror_csv('https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/example.csv');
ok('ARRAY' eq ref($result) ? 1 : 0);

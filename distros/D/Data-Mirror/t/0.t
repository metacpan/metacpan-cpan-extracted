#!/usr/bin/perl
use LWP::Online qw(online);
use Test::More;
use LWP::Protocol::https; # ensure this is installed otherwise tests will fail.
use vars qw($result);
use warnings;
use strict;

BEGIN { use_ok(q{Data::Mirror}, qw(:all)) }

#
# speed up repeated runs by caching everything for a day
#
$Data::Mirror::TTL_SECONDS = 86400;

if (!online()) {
    done_testing();
    exit;
}

#
# string mirror
#
$result = mirror_str('https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/README.md');
ok(length($result) > 0 ? 1 : 0);

#
# file mirror
#
$result = mirror_file('https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/README.md');
ok(-e $result);

ok($result eq Data::Mirror::filename('https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/README.md'));

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
my $url = 'https://raw.githubusercontent.com/gbxyz/perl-data-mirror-test-files/main/example.csv?t='.time();

ok(!Data::Mirror::mirrored($url));

$result = mirror_csv($url);

ok('ARRAY' eq ref($result) ? 1 : 0);

ok(Data::Mirror::mirrored($url));

ok(!Data::Mirror::stale($url));

done_testing;

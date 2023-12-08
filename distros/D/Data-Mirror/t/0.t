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
$result = mirror_str('https://www.example.com/');
ok(length($result) > 0 ? 1 : 0);

#
# file mirror
#
$result = mirror_file('https://www.example.com/');
ok(-e $result ? 1 : 0);

#
# filehandle mirror
#
$result = mirror_fh('https://www.example.com/');
if ($result->isa('IO::File')) {
    $result->close;
    ok(1);

} else {
    ok(0);

}

#
# JSON mirror
#
$result = mirror_json('https://httpbin.org/ip');
ok('HASH' eq ref($result) ? 1 : 0);

#
# YAML mirror
#
$result = mirror_yaml('https://raw.githubusercontent.com/yaml/libyaml/master/examples/anchors.yaml');
ok('HASH' eq ref($result) ? 1 : 0);

#
# CSV mirror
#
$result = mirror_csv('https://media.githubusercontent.com/media/datablist/sample-csv-files/main/files/people/people-100.csv');
ok('ARRAY' eq ref($result) ? 1 : 0);

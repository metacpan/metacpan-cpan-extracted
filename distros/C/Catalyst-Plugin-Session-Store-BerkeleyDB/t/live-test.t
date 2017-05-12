#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 13;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Remove;

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

my ($id, $v) = p();
is $v, 0, 'got 0';
is_deeply [p()], [$id, 1], 'got id and 1';

$mech->get_ok('http://localhost/flash_set', 'set flash');
$mech->get_ok('http://localhost/flash_get', 'get flash');
$mech->content_like(qr/OH HAI/i, 'see if it has our text');
$mech->get_ok('http://localhost/flash_get', 'get flash');
$mech->content_like(qr/NOTHING/i, 'only once');

$mech->get_ok('http://localhost/cleanup', 'cleanup');

sub p {
    $mech->get_ok('http://localhost/session_test/', 'get session_test');
    return split /,/, $mech->content;
}

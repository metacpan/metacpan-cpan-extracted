#!perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 4;

use FindBin qw($Bin);
use lib "$Bin/lib";
use Catalyst::Test qw(TestApp);

is( get('/controller'), 'controller', 'got controller ok' );
is( get('/model'), 'model', 'model ok' );
is( get('/view'), 'view', 'view ok' );
is( get('/foo'), 'baz', 'got app at new() time' );

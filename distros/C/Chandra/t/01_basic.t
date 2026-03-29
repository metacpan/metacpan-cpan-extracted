#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra');

# Test object creation
my $app = Chandra->new(
    title  => 'Test',
    url    => 'about:blank',
    width  => 640,
    height => 480,
);

ok($app, 'Chandra object created');
is($app->title, 'Test', 'title accessor works');
is($app->url, 'about:blank', 'url accessor works');
is($app->width, 640, 'width accessor works');
is($app->height, 480, 'height accessor works');
is($app->resizable, 1, 'resizable defaults to 1');
is($app->debug, 0, 'debug defaults to 0');

done_testing();

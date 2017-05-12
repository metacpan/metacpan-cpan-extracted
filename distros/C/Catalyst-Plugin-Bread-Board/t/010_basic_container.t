#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Path::Class;

use Test::More;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('Catalyst::Plugin::Bread::Board::Container');
}

my $c = Catalyst::Plugin::Bread::Board::Container->new(
    name     => 'Test010',
    app_root => [ $FindBin::Bin ],
);
isa_ok($c, 'Catalyst::Plugin::Bread::Board::Container');

is($c->name, 'Test010', '... got the right name');
isa_ok($c->app_root, 'Path::Class::Dir');

is($c->app_root->stringify, dir( $FindBin::Bin )->stringify, '... got the right dir');

my $app_root = $c->fetch('app_root')->get;
is($c->app_root, $app_root, '... the service is the same as what we passed in');

done_testing;
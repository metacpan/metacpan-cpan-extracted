#!perl

use strict;
use warnings;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

my @apps = qw/TestApp TestApp2/;
use_ok($_) for @apps;

my @data_dirs = map {
    my $pkg = $_ . '::View::Mason';
    $pkg->config->{data_dir}
} @apps;

isnt($data_dirs[0], $data_dirs[1], 'different apps get different data_dir defaults');

use Test::More;
use File::Find;
use strict;

my @modules;
find( sub { push @modules, $File::Find::name if /\.pm$/ }, 'blib' );
    
plan tests => scalar @modules;
use_ok( $_ ) for map { s!/!::!g;s/\.pm$//;s/^blib::lib:://; $_ } sort @modules;

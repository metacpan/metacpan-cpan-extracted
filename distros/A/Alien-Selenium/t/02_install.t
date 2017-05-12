#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 2;
use File::Path qw(rmtree);

use Alien::Selenium;

my $dir = 't/sel';

rmtree $dir;
Alien::Selenium->install( $dir );
for (qw(selenium.css TestRunner-splash.html)) {
    ok( -e "$dir/$_", "$dir/$_ exists" );
}


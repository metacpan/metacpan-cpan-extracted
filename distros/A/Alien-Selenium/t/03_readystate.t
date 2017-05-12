#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use File::Path qw(rmtree);

use Alien::Selenium;

plan skip_all => "irrelevant for Selenium < 0.8"
    if (Alien::Selenium->version lt 0.8);

plan tests => 2;

ok(-f Alien::Selenium->path_readystate_xpi, "readystate.xpi is bundled");

rmtree('t/readystate');
my $target = 't/readystate/readystate.xpi';

Alien::Selenium->install_readystate_xpi($target);
ok(-f $target, "readystate.xpi successfully installed");


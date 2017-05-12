#!/usr/bin/perl

package My::Package;
use Sub::Attempts;

# total failing run should take 3*3 seconds = 9 sec
sub foo {  die  }
attempts("foo", tries => 4, delay => 3);

##########################################################

package main;

use Test::More tests => 2;
use Test::Exception;

use strict;
use warnings;

################################################

my $time = time;

eval { My::Package::foo(); };

cmp_ok(time, '>', $time+7, "time check 1/2");
cmp_ok(time, '<', $time+11, "time check 2/2");

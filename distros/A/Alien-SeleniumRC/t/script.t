#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

my $src = 'bin/selenium-rc';

Script_compiles: {
    like qx($^X -Ilib -c $src 2>&1), qr/OK/;
}


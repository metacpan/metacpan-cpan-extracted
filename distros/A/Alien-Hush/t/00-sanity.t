#!/usr/bin/perl

use strict;
use warnings;
use Config;
use Test::More;
use lib 'inc';

use_ok( 'Alien::Hush' );

my $hush_version= $Alien::Hush::HUSH_VERSION;
my $arch        = $Config{archname};
diag( "Testing Alien::Hush $Alien::Hush::VERSION with hush $hush_version on $arch, Perl ($^X) $]" );

ok($hush_version, "Hush version is defined");

done_testing;


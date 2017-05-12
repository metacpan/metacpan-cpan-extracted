#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Test::More tests => 1;

use Bessarabv::Sleep;

my $version = $Bessarabv::Sleep::VERSION;

$version = "(unknown version)" if not defined $version;

ok(1, "Testing Bessarabv::Sleep $version, Perl $], $^X" );

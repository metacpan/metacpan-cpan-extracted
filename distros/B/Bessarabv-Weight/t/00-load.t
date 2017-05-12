#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Test::More tests => 1;

use Bessarabv::Weight;

my $version = $Bessarabv::Weight::VERSION;

$version = "(unknown version)" if not defined $version;

ok(1, "Testing Bessarabv::Weight $version, Perl $], $^X" );

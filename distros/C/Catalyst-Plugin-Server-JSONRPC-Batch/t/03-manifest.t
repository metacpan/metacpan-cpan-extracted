#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More;


plan(skip_all => 'Author tests not required for installation')
	unless $ENV{RELEASE_TESTING};
plan(skip_all => 'Test::CheckManifest 0.9 required for this test')
	unless eval('use Test::CheckManifest 0.9; 1');

ok_manifest();

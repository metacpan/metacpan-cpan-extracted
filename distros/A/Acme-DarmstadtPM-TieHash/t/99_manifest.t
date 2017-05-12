#!/usr/bin/perl -T

use strict;
use warnings;
use Test::More;

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::Checkmanifest 0.9 required" if $@;
ok_manifest();

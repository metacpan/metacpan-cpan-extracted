#!/usr/bin/perl -w

use v5.14;
use utf8;

use Test::More;
use Test::MinimumVersion;

use strictures 2;
no warnings "experimental::signatures";

all_minimum_version_ok('5.020');

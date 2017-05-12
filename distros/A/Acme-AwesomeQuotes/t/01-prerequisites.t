#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use Test::More;

my @modules = qw(utf8 Exporter Carp Unicode::Normalize);

plan tests => (scalar @modules);

for (@modules) {
	use_ok $_;
}

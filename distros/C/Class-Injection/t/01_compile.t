#!/usr/bin/perl


use lib '../lib';

use strict;
use warnings;

use Test::More tests => 2;

my @modules = qw(
Class::Injection
Class::Inspector
);

foreach my $module (@modules) {
    eval " use $module ";
    ok(!$@, "$module compiles");
}

1;

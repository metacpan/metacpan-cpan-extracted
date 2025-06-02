#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 5;

use_ok('Data::IconText');

my $icontext = Data::IconText->new(unicode => 0x1F981);

isa_ok($icontext, 'Data::IconText');
is($icontext->unicode, 0x1F981);
is(length($icontext->as_string), 1);
ok(defined($icontext->ise));

exit 0;

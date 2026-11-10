#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 4;

use_ok('Data::TagListMatcher');

my $matcher = Data::TagListMatcher->new;
isa_ok($matcher, 'Data::TagListMatcher');

$matcher->add_metric(score => int => 'add');
$matcher->add_rule(yes => 1);

is($matcher->match(['yes'])->{score}, 1, 'positive');
is($matcher->match(['no'])->{score}, 0, 'negative');

exit 0;

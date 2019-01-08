#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Class::Superclasses;

my $code = q~package test_expression_parent;

use parent ("Expression","parent");~;

my $parser = Class::Superclasses->new();
isa_ok $parser, 'Class::Superclasses';

$parser->document(\$code);

my $check = [qw'Expression parent'];
my @superclasses = $parser->superclasses();

is_deeply \@superclasses, $check;

done_testing();

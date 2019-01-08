#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use_ok 'Class::Superclasses';

my $code = q~package test_norequire_expression;
  
use parent -norequire, "Expression","parent";
~;

my $parser = Class::Superclasses->new();
isa_ok $parser, 'Class::Superclasses';

$parser->document(\$code);

my $check = [qw'Expression parent'];
my @superclasses = $parser->superclasses();

is_deeply \@superclasses, $check;

done_testing();

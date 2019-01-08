#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use_ok 'Class::Superclasses';

my $code = q~package test_quote_base;
  
use base "Quote","base";
~;

my $parser = Class::Superclasses->new();
isa_ok $parser, 'Class::Superclasses';

$parser->document(\$code);

my $check = [qw'Quote base'];
my @superclasses = $parser->superclasses();

is_deeply \@superclasses, $check;

done_testing();

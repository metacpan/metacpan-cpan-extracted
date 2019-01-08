#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use_ok 'Class::Superclasses';


use Class::Superclasses;

my $code = qq~package test_expression_base;

use base ("Expression","base");~;

my $parser = Class::Superclasses->new();
ok ref $parser eq 'Class::Superclasses';

$parser->document(\$code);

my $check        = [qw'Expression base'];
my @superclasses = $parser->superclasses();

is_deeply \@superclasses, $check;

done_testing();

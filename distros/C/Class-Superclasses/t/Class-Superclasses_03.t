#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use_ok 'Class::Superclasses';

my $code = q~package test_quotelike_base;
  
use base qw(Tk::MainWindow Tk::Notebook);
~;

my $parser = Class::Superclasses->new();
isa_ok $parser, 'Class::Superclasses';

$parser->document(\$code);

my $check = [qw'Tk::MainWindow Tk::Notebook'];
my @superclasses = $parser->superclasses();

is_deeply \@superclasses, $check;

done_testing();

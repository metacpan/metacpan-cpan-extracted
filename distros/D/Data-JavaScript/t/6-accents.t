#!/usr/bin/env perl

use Modern::Perl;
use utf8;

use Test2::V0;
use Test2::Tools::Subtest qw/subtest_buffered/;

use Data::JavaScript qw(:all);

#<<<
my $input = q/«Hêllö» Thére!/;
my $expected = qq/var output = "\\u00ABH\\u00EAll\\u00F6\\u00BB Th\\u00E9re!";\n/;
#>>>

is
  jsdump( 'output', $input ),
  $expected,
  'Accented jsdump()';

done_testing;

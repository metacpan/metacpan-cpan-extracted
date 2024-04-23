# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on two examples of multiplications.
#
# In some actions, the level has been tweaked a little to display
# intermediate results that would not have been displayed normally.
#
# Copyright 2023, 2024 Jean Forget
#
# This programme is free software; you can redistribute it and modify it under the Artistic License 2.0.
#

use 5.38.0;
use utf8;
use strict;
use warnings;
use Test::More;
use Arithmetic::PaperAndPencil;
use feature qw/class/;
use open ':encoding(UTF-8)';

plan(tests => 5);

my $fname = 'xt/data/02-html.csv';
my $operation = Arithmetic::PaperAndPencil->new;
my $ref = slurp($fname);
$ref =~ s/\h//g;
$operation->from_csv($ref);
is($operation->csv, $ref);

my $html = $operation->html(lang => 'fr', silent => 0, level => 0);
$ref = slurp('xt/data/02-html-fr-talk.html');
is($html, $ref);

$html = $operation->html(lang => 'fr', silent => 1, level => 0);
$ref = slurp('xt/data/02-html-fr-silent.html');
is($html, $ref);

$html = $operation->html(lang => 'en', silent => 0, level => 0);
$ref = slurp('xt/data/02-html-en-talk.html');
is($html, $ref);

$html = $operation->html(lang => 'en', silent => 1, level => 0);
$ref = slurp('xt/data/02-html-en-silent.html');
is($html, $ref);

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}

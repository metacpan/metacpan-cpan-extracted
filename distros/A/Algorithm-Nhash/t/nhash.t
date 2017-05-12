#!/usr/bin/env perl
use warnings;
use strict;

# Test "sane" usage

use Test::More tests => 6;

use Algorithm::Nhash qw( nhash );

is(nhash('supercalifragilisticexpialidocious'), 228769,
   'no-value nhash');

is(nhash('supercalifragilisticexpialidocious', 512), 417,
   'one-value nhash');

is(nhash('supercalifragilisticexpialidocious', 8, 64), '6/33',
   'scalar two-value nhash');

is_deeply(
    [nhash('supercalifragilisticexpialidocious', 8, 64)],
    [6, 33],
    'list two-value nhash');

my $nhash = new Algorithm::Nhash 8, 64;

is($nhash->nhash('supercalifragilisticexpialidocious'), '6/33',
   'scalar two-value OO nhash');

is_deeply(
    [$nhash->nhash('supercalifragilisticexpialidocious')],
    [6, 33],
    'list two-value OO nhash');


#!/usr/bin/perl

use Test::More qw(no_plan);
use strict;
BEGIN {
use_ok 'Algorithm::Annotate';
}

my $ann = Algorithm::Annotate->new();

$ann->init ('a', [qw/a b c d g g g h h i f/]);
$ann->add  ('b', [qw/a b c d e f g g h h i j k/]);
ok(eq_array($ann->result, [qw/a a a a b b a a a a a b b/]));
$ann->add  ('c', [qw/c b c d f g g c c c h h i j k/]);
ok(eq_array($ann->result, [qw/c a a a b a a c c c a a a b b/]));

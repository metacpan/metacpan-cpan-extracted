#!perl

use strict;
use Test::More tests => 12;
BEGIN { use_ok('Class::Mutator'); }

package Princess;
sub new { return bless {}, $_[0] }
sub go_to_ball { return 'before midnight' }

package FancyFeet;
sub new { return bless {}, $_[0] }
sub slippers { return 'made of glass' }

package Potato;

package Frog;
use Class::Mutator qw( -isasubclass );
sub new { return bless {}, $_[0] }
sub ribbit { return 'ribbit' }


package main;

my $f = Frog->new();
my $p = Princess->new();

ok($f->can('ribbit'),'frog can ribbit at the start');
ok(!($f->can('go_to_ball')),'frog cannot go_to_ball at the start');

$f->mutate('Princess');
ok($f->can('ribbit'),'frog can ribbit still after mutating');
ok($f->can('go_to_ball'),'frog can go_to_ball after mutating');

$f->unmutate('Princess');
ok($f->can('ribbit'),'frog can ribbit after unmutating');
ok(!($f->can('go_to_ball')),'frog cannot go_to_ball after unmutating');

$f->mutate('Princess', 'FancyFeet');
ok($f->can('go_to_ball') && $f->can('slippers'),'double-mutation successful');

$f->unmutate('Princess');
ok($f->can('ribbit') && $f->can('slippers'),'frog still has glass slippers');

$f->mutate('Princess');

$f->unmutate('FancyFeet', 'Princess');
ok($f->can('ribbit'),'frog still can ribbit at the end');
ok(!($f->can('go_to_ball')),'frog cannot go_to_ball at the end');
ok(!($f->can('slippers')),'frog has no slippers at the end');

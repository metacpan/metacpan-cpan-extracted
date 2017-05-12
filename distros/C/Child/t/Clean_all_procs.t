#!/usr/bin/perl;
use strict;
use warnings;

use Test::More 0.88;
our $CLASS = 'Child';

require_ok( $CLASS );

my $spec = $CLASS->new( sub {
    my $self = shift;
    my $in = $self->read();
}, pipe => 1 );

my $child1 = $spec->start;
my $child2 = $spec->start;

sleep 1;

$child1->is_complete;
$child2->is_complete;
ok((grep {$child1 == $_} $CLASS->all_procs), "Found child 1, still active");
ok((grep {$child2 == $_} $CLASS->all_procs), "Found child 2, still active");

$child1->say("anything");

sleep 1;

$child1->is_complete;
$child2->is_complete;
ok(!(grep {$child1 == $_} $CLASS->all_procs), "child 1 not found");
ok((grep {$child2 == $_} $CLASS->all_procs), "Found child 2, still active");

$child2->say("anything");

sleep 1;

Child->wait_all;
ok(!(grep {$child1 == $_} $CLASS->all_procs), "child 1 not found");
ok(!(grep {$child2 == $_} $CLASS->all_procs), "child 2 not found");

done_testing;

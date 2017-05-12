#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "Class::Workflow";

isa_ok( my $w = Class::Workflow->new, "Class::Workflow" );

{
	package My::Custom::State;
	use Moose;

	extends "Class::Workflow::State::Simple";
}

my $new = $w->state(
	"new",
	class       => "My::Custom::State",
	transitions => [qw/reject/],
);

$w->transition(
	name     => "reject",
	to_state => "rejected",
);

isa_ok( $new, "Class::Workflow::State::Simple" );

my $accepted_items = 0;
my $accept = $w->transition( 'accept' =>
	to_state  => "open",
	body      => sub { ++$accepted_items },
);

isa_ok( $accept, "Class::Workflow::Transition::Simple" );

$new->add_transitions( $accept );

is( $accept->to_state, $w->state("open") );

isa_ok( $w->state("rejected"), "Class::Workflow::State::Simple" );

is_deeply(
	[ sort $w->state("new")->transitions ],
	[ sort map { $w->transition($_) } qw/accept reject/ ],
	"transitions from state 'new'",
);

my $hook = 0;
$w->state("open")->add_hook(sub { $hook++ });

$w->initial_state("new");

isa_ok( my $i = $w->new_instance, "Class::Workflow::Instance::Simple" );

is( $i->state, $new, "initial state" );

ok( $i->state->has_transition('accept'), 'state has accept transition' );
ok( $i->state->has_transitions, 'state has transitions');
ok( !$i->state->has_transition('notexist'), 'state does not have notexist transition');

is( $new->get_transition("accept"), $accept, "get_transition" );

isa_ok( my $i_accepted = $accept->apply( $i ), "Class::Workflow::Instance::Simple");

is( $i_accepted->state, $w->state("open"), "new state is correct" );
is( $accepted_items, 1, "callback called" );
is( $hook, 1, "state hook fired" );

is( $i_accepted->prev, $i, "prev pointer is right" );
is( $i->state, $new, "previous instance untouched" );


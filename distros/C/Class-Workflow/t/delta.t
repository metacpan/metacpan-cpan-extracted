#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Class::Workflow;

use ok "Class::Workflow::Util::Delta";

{
	package MyInstance;
	use Moose;

	extends qw/Class::Workflow::Instance::Simple/;

	has foo => (
		isa => "Str",
		is  => "ro",
		required => 1,
	);

	has bar => (
		isa => "ArrayRef",
		is  => "ro",
		required => 1,
	);
}

my $w = Class::Workflow->new;

$w->instance_class("MyInstance");

$w->state(
	name => "i",
	transitions => [qw/a/],
);

$w->initial_state("i");

my $t = $w->transition(
	name => "a",
	to_state => "j",
	set_fields => { foo => "oink" },
);

my $x = $w->new_instance(
	foo => "",
	bar => [ ],
);

my $y = $t->apply( $x );

my $d = Class::Workflow::Util::Delta->new(
	from => $x,
	to   => $y,
);

is_deeply( scalar($d->changes), { foo => { from => "", to => "oink" } }, "computed delta" );



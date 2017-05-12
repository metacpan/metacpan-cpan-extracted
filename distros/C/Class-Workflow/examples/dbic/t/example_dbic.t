#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
	plan skip_all => "This test requires DBIx::Class version 0.08009 or higher to be installed" unless eval { require DBIx::Class; die unless $DBIx::Class::VERSION >= 0.08009 };
	plan skip_all => "This test requires DBICx::TestDatabase to be installed" unless eval { require DBICx::TestDatabase };
	plan tests => 5;
}

use DBICx::TestDatabase;

my $schema = DBICx::TestDatabase->new('Foo::DB');

my $states = $schema->resultset("Workflow::State");

my $init = $states->create({ id => 1 });
my $blah = $states->create({ id => 2 });
my $gorch = $states->create({ id => 3 });

my $tns = $schema->resultset("Workflow::Transition");


my $blah_called = 0;

{
	package Foo::DB::Workflow::Transition::Blah;
	use Moose;

	extends qw(Foo::DB::Workflow::Transition);

	sub apply_body {
		$blah_called++;
		return {}, ();
	}
}

my $to_blah = $tns->create({
	state => $init,
	to_state => $blah,
	class => "Blah",
});

my $to_gorch = $tns->create({
	state => $init,
	to_state => $gorch,
	class => "Null",
});

my $instances = $schema->resultset("Workflow::Instance");

my $i = $instances->create({ state => $states->find({ id => 1 }) }); # $init

my $items = $schema->resultset("Item");

my $item = $items->create({ id => 1, workflow_instance => $i });

is( $blah_called, 0, "blah not called" );

$item->apply_transition($to_blah);

is( $blah_called, 1, "blah called" );

my $i2 = $item->workflow_instance;

is( $i2->state->id, $blah->id, "workflow instance ID is correct" );
is( $i2->prev->state->id, $init->id, "workflow history" );

is_deeply(
	[ sort map { $_->id } $instances->all ],
	[ sort map { $_->id } $i, $i2 ],
	"instances in DB",
);


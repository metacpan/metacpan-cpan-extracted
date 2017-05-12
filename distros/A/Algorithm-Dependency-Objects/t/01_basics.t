#!/usr/bin/perl

# Creating and using dependency trees

use strict;
use warnings;

use Test::More tests => 49;
use Test::Deep;

{
	package SomeObj;
	use Scalar::Util qw/refaddr/;

	use overload '""' => 'id', fallback => 1;

	my $id = 'A';
	my %id;
	
	sub id { $id{refaddr $_[0]} }
	sub new {
		my $pkg = shift;
		my $self = bless [ @_ ], $pkg;
		$id{refaddr $self} = $id++;
		$self;
	}
	sub depends {
		@{ $_[0] }
	}
}

use Set::Object;

my $objs = Set::Object->new(my ($a,$b,$c,$d,$e,$f) = map { SomeObj->new() } qw/A B C D E F/);
@$b = ($c);
@$d = ($e, $f);

my $m;
BEGIN { use_ok($m = "Algorithm::Dependency::Objects") };

# Load the data/basics.txt file in as a source file, and test it rigorously.

{
	# Try to create a basic unordered dependency
	isa_ok(my $dep = $m->new(objects => $objs), $m);

	is($dep->objects->size, 6, "six objects are registered");
	is($dep->selected->size, 0, "no objects are selected");

	verify_dep_and_sched($dep, [
		[$a],		[],				[$a] 			], [
		[$b],		[$c],			[$b, $c] 		], [
		[$c],		[], 			[$c]			], [
		[$d],		[$e, $f],		[$d, $e, $f]	], [
		[$e],		[],				[$e]			], [
		[$f],		[],				[$f]			], [
		[$a, $b],	[$c],			[$a, $b, $c]	], [
		[$b, $d],	[$c, $e, $f],	[$b, $c, $d, $e, $f]		]
	);
}


{
	# Create with one selected
	isa_ok(my $dep = $m->new( objects => $objs, selected => Set::Object->new($f) ), $m);

	cmp_deeply(
		[ $dep->schedule_all ],
		bag( $a, $b, $c, $d, $e ),  # no $f
		"schedule_all",
	);

	is($dep->objects->size, 6, "six objects registered" );
	is($dep->selected->size, 1, "one objects selected" );

	ok( !$dep->selected->contains($a), "a is not selected" );
	ok( $dep->selected->contains($f), "f is selected" );

	verify_dep_and_sched($dep, [
		[$a],		[],				[$a] 			], [
		[$b],		[$c],			[$b, $c] 		], [
		[$c],		[], 			[$c]			], [
		[$d],		[$e],			[$d, $e]		], [
		[$e],		[],				[$e]			], [
		[$f],		[],				[]				], [
		[$a, $b],	[$c],			[$a, $b, $c]	], [
		[$b, $d],	[$c, $e],	[$b, $c, $d, $e]	]
	);
}

sub verify_dep_and_sched {
	my $dep = shift;

	foreach my $data (@_){
		my $args = join( ', ', @{ $data->[0] } );
		my @deps = $dep->depends( @{ $data->[0] } );
		cmp_deeply(\@deps, bag(@{ $data->[1] }), "depends($args)" );
		my @sched = $dep->schedule( @{ $data->[0] } );
		cmp_deeply(\@sched, bag(@{ $data->[2] }), "schedule($args)" );
	}
}

BEGIN { use_ok("Algorithm::Dependency::Objects::Ordered") }

{
	my @objs = map { SomeObj->new } qw/G H I J K L M N O P/;
	
	@{ $objs[0] } = @objs[4, 5];

	@{ $objs[4] } = @objs[5, 2];

	@{ $objs[2] } = @objs[5, 7];

	@{ $objs[5] } = ( $objs[7] );

	@{ $objs[7] } = @objs[9, 8];

	@{ $objs[9] } = ( $objs[8] );

	{
		my $d = Algorithm::Dependency::Objects->new(
			objects => \@objs,
		);

		cmp_deeply( [ $d->schedule($objs[9]) ], bag(@objs[8,9]), "unordered dep" );
		cmp_deeply( [ $d->schedule($objs[2]) ], bag(@objs[2, 5, 7, 9, 8]), "unordered dep" );
		cmp_deeply( [ $d->schedule_all ], bag(@objs), "unordered dep" );
	}

	{
		my $d = Algorithm::Dependency::Objects::Ordered->new(
			objects => \@objs,
		);

		is_deeply(
			[ $d->schedule($objs[9]) ],
			[ @objs[8,9] ],
			"simple schedule",
		);

		is_deeply(
			[ $d->schedule($objs[2]) ],
			[ @objs[8, 9, 7, 5, 2 ] ],
			"complex schedule",
		);

		is_deeply(
			[ $d->schedule($objs[0]) ],
			[ @objs[8, 9, 7, 5, 2, 4, 0] ],
			"complex schedule",
		);
	}
}

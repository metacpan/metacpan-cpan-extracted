#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Scalar::Util qw(refaddr);

use Data::Visitor;
use Data::Visitor::Callback;

{
	my $structure = {
		foo => {
			bar => undef,
		},
	};

	$structure->{foo}{bar} = $structure;

	my $o = Data::Visitor->new;

	{
		alarm 1;
		$o->visit( $structure );
		alarm 0;
		pass( "circular structures don't cause an endless loop" );
	}

	is_deeply( $o->visit( $structure ), $structure, "Structure recreated" );

	is( $structure, $structure->{foo}{bar}, "circular address" );

	my $visited = $o->visit( $structure );

	is( $visited, $visited->{foo}{bar}, "circular address" );
}

{
	my $orig = {
		one => [ ],
		two => [ ],
	};

	my $hash = $orig->{one}[0] = $orig->{two}[0] = bless {}, "yyy";

	my $c = Data::Visitor::Callback->new(
		object => sub { bless {}, "zzzzz" },
	);

	my $copy = $c->visit( $orig );

	is( $copy->{one}[0], $copy->{two}[0], "copy of object is a mapped copy" );
}


{
	my $orig = [
		[ ],
		[ ],
	];

	my $hash = $orig->[0][0] = $orig->[1][0] = { };

	my $c = Data::Visitor::Callback->new(
		hash => sub { $_ = { foo => "bar" } },
	);

	$c->visit( $orig );

	{
		local $TODO = "broken in older perls" unless Data::Visitor::Callback::FIVE_EIGHT();
		is( $orig->[0][0], $orig->[1][0], "equality preserved" );
	}

	isnt( $orig->[0][0], $hash, "original replaced" );

	is_deeply( $orig->[0][0], { foo => "bar" }, "data is as expected" );
}

{
	my $orig = {
		foo => { obj => bless {}, "blah" },
		misc => bless {}, "oink",
	};

	$orig->{foo}{self} = $orig;
	$orig->{foo}{foo} = $orig->{foo};

	my $c = Data::Visitor::Callback->new();

	my $copy = $c->visit( $orig );

	is_deeply( $copy, $orig, "structure retained" );
}

{
	my $orig = [
		{ obj => bless {}, "blah" },
	];

	$orig->[0]{self} = $orig;
	$orig->[1] = $orig->[0];

	my $c = Data::Visitor::Callback->new( seen => sub { "seen" } );

	my $copy = $c->visit( $orig );

	is_deeply(
		$copy,
		[
			{ obj => bless({}, "blah"), self => "seen" },
			"seen",
		],
		"seen callback",
	);
}

{
	my $orig = {
		foo => { bar => 42 },
	};

	$orig->{bar} = \( $orig->{foo}{bar} );

	is( refaddr($orig->{bar}), refaddr( \( $orig->{foo}{bar} ) ), "scalar ref to hash element" );

	my $copy = Data::Visitor->new->visit($orig);

	is_deeply( $copy, $orig, "structures eq deeply" );

	local $TODO = "hash/array elements are not yet references internally";
	is( refaddr($copy->{bar}), refaddr( \($copy->{foo}{bar}) ), "scalar ref in copy" );
}

{
	my $orig = {
		foo => 42,
	};

	$orig->{bar} = \( $orig->{foo} );

	is( refaddr($orig->{bar}), refaddr( \( $orig->{foo} ) ), "scalar ref to sibling hash element" );

	my $copy = Data::Visitor->new->visit($orig);

	is_deeply( $copy, $orig, "structures eq deeply" );

	local $TODO = "hash/array elements are not yet references internally";
	is( refaddr($copy->{bar}), refaddr( \($copy->{foo}) ), "scalar ref in copy" );
}

done_testing;

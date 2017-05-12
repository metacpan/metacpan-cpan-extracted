#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


use Data::Visitor::Callback;

foreach my $ignore ( 0, 1 ) {
	my $structure = {
		foo => "bar",
		gorch => [ "baz", 1 ],
	};

	my $o = Data::Visitor::Callback->new(
		ignore_return_values => $ignore,
		plain_value => sub { no warnings 'uninitialized'; s/b/m/g; "laaa" },
		array => sub { $_ = 42; undef },
	);

	$_ = "original";

	$o->visit( $structure );

	is( $_, "original", '$_ unchanged in outer scope');

	is_deeply( $structure, {
		foo => "mar",
		gorch => 42,
	}, "values were modified" );

	$o->callbacks->{hash} = sub { $_ = "value" };
	$o->visit( $structure );
	is( $structure, "value", "entire structure can also be changed");
}

done_testing;

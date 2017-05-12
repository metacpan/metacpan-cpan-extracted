#!/usr/bin/perl -w
use strict;
use Test::More tests => 3;

is(simple(), "foobazbarqux");
is(postsub(),6);

TODO: {
	local $TODO = "Certain strings can be mis-parsed as code.";
	is(string_embed(),"{ milk } but first { coffee }");
};

use Acme::ButFirst;

sub simple {

	my $x = "";

	{
		$x .= "bar";
		$x .= "qux";
	} butfirst {
		$x .= "foo";
		$x .= "baz";
	}

	return $x;

}

our $z;

sub postsub {
	my $y = 1;

	$y = $y + $z;

	return $y;
	
} butfirst {
	$z = 5;
}

sub string_embed {
	return "{ milk } but first { coffee }";
}

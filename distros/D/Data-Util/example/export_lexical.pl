#!perl -w

use strict;
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN{
	package Foo;
	use feature 'say';

	use Sub::Exporter::Lexical # in example/lib/Sub/Exporter/Lexical.pm
		exports => [qw(foo bar baz), ('A' .. 'Z')],
	;

	sub foo{ say 'foo!' }
	sub bar{ say 'bar!' }
	sub baz{ say 'baz!' }

	$INC{'Foo.pm'} = __FILE__;

	package Bar;
	use Exporter qw(import);
	our @EXPORT = (qw(foo bar baz), ('A' .. 'Z'));

	sub foo{}
	sub bar{}
	sub baz{}
	$INC{'Bar.pm'} = __FILE__;
}

{
	use Foo qw(foo bar baz);

	foo;
	bar;
	baz;
}


eval{ foo() } or warn '! ', $@;
eval{ bar() } or warn '! ', $@;
eval{ baz() } or warn '! ', $@;

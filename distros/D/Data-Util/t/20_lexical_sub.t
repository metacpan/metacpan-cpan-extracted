#!perl -w
use strict;
use Test::More tests => 9;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/../example/lib";

BEGIN{
	package Foo;
	use Sub::Exporter::Lexical
		exports => [
			qw(foo),
			bar => \&bar,
			baz => \&bar,
		],
	;

	sub foo{ 'foo' }

	sub bar{ 'bar' }

	$INC{'Foo.pm'} = __FILE__;
}

{
	use Foo;

	lives_ok{
		is foo(), 'foo';
	} 'call lexical sub';

	lives_ok{
		is bar(), 'bar';
	} 'call lexical sub';

	lives_ok{
		is baz(), 'bar';
	} 'call lexical sub';
}

throws_ok{
	isnt foo(), 'foo';
} qr/Undefined subroutine \&main::foo/;

throws_ok{
	isnt bar(), 'bar';
} qr/Undefined subroutine \&main::bar/;

throws_ok{
	isnt baz(), 'bar';
} qr/Undefined subroutine \&main::baz/;;

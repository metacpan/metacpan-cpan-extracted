#!perl -w

use strict;

use Data::Util qw(:all);
use Data::Dumper;
use Carp qw(cluck);
{
	sub foo {
		cluck('foo called');
		print Dumper [foo => @_];
		return (-1, -2);
	}
	sub bar {
		my $f = shift;
		print Dumper [bar => @_ ];
		$f->(@_);
	};
	sub baz {
		my $f = shift;
		print Dumper [baz => @_ ];
		$f->(@_);
	};
}
my $c = modify_subroutine(
	\&foo,
	before => [sub { print ":before\n" } ],
	around => [\&bar, \&baz],
	after  => [sub { print ":after\n" } ],
);

$c->(42);

#!perl -w

use strict;
use Data::Util qw(:all);

{
	package Foo;
	use Data::Dumper;
	use Data::Util qw(:all);
	use Carp qw(cluck);

	install_subroutine(__PACKAGE__,
		baz => curry(\0, 'bar', x => \1, y => \2, z => \3),
	);

	sub bar{
		my($self, %args) = @_;
		print Dumper \%args;
	}

	sub incr{ $_[1]++ }
}

Foo->baz(10, 20, 30);

my $i = 0;

install_subroutine __PACKAGE__, incr => curry('Foo', 'incr', *_);

for (1 .. 3){
	incr($i);
	print 'incr $i = ', $i, "\n";
}

use strict;
use warnings;
use Test::More;

our ( @BUILD, @DEMOLISH );

BEGIN {
	package Local::Foo;
	use Class::XSConstructor;
	use Class::XSDestructor;
	sub BUILD     { push @BUILD, __PACKAGE__ };
	sub DEMOLISH  { push @DEMOLISH, __PACKAGE__ };
};

BEGIN {
	package Local::Foo::Bar;
	our @ISA = 'Local::Foo';
	sub BUILD     { push @BUILD, __PACKAGE__ };
	sub DEMOLISH  { push @DEMOLISH, __PACKAGE__ };
};

do {
	my $x = Local::Foo::Bar->new;

	is_deeply( \@BUILD, [ 'Local::Foo', 'Local::Foo::Bar' ] ) or diag explain \@BUILD;
	is_deeply( \@DEMOLISH, [] ) or diag explain \@DEMOLISH;
	is_deeply( +{%$x}, {} );
};

is_deeply( \@BUILD, [ 'Local::Foo', 'Local::Foo::Bar' ] ) or diag explain \@BUILD;
is_deeply( \@DEMOLISH, [ 'Local::Foo::Bar', 'Local::Foo' ] ) or diag explain \@DEMOLISH;

done_testing;

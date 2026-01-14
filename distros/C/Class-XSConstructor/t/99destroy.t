use strict;
use warnings;
use Test::More;

our ( @BUILD, @DEMOLISH );

BEGIN {
	package Local::Foo;
	use Class::XSConstructor;
	use Class::XSDestructor;
	sub BUILD     { shift; push @BUILD, __PACKAGE__ };
	sub DEMOLISH  { shift; push @DEMOLISH, __PACKAGE__, @_ };
};

BEGIN {
	package Local::Foo::Bar;
	our @ISA = 'Local::Foo';
	sub BUILD     { shift; push @BUILD, __PACKAGE__ };
	sub DEMOLISH  { shift; push @DEMOLISH, __PACKAGE__, @_ };
};

do {
	my $x = Local::Foo::Bar->new;

	is_deeply( \@BUILD, [ 'Local::Foo', 'Local::Foo::Bar' ] ) or diag explain \@BUILD;
	is_deeply( \@DEMOLISH, [] ) or diag explain \@DEMOLISH;
	is_deeply( +{%$x}, {} );
	
	@DEMOLISH = ();
	
	$x->DEMOLISHALL( qw/ foo bar/ );
	
	is_deeply( \@DEMOLISH, [ 'Local::Foo::Bar' => qw/ foo bar /, 'Local::Foo' => qw/ foo bar / ] ) or diag explain \@DEMOLISH;
	
	@DEMOLISH = ();
};

is_deeply( \@BUILD, [ 'Local::Foo', 'Local::Foo::Bar' ] ) or diag explain \@BUILD;
is_deeply( \@DEMOLISH, [ 'Local::Foo::Bar' => 0, 'Local::Foo' => 0 ] ) or diag explain \@DEMOLISH;

done_testing;

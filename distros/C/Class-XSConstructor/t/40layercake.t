use strict;
use warnings;
use Test::More;
use Carp 'cluck';

{
	package XXXX1;
	use Test::Requires { 'Moo' => '2.005000' }
}

my @BUILD;

BEGIN {
	package Local::Layer1;
	use Moo;
	sub BUILD {
		push @BUILD, __PACKAGE__, [ @_ ];
	}
};

BEGIN {
	package Local::Layer2;
	use parent -norequire, 'Local::Layer1';
	use Class::XSConstructor;
	sub BUILD {
		push @BUILD, __PACKAGE__, [ @_ ];
	}
};

my $obj = Local::Layer2->new( x => 42 );

is_deeply(
	\@BUILD,
	[
		'Local::Layer1' => [ $obj, { x => 42 } ],
		'Local::Layer2' => [ $obj, { x => 42 } ],
	],
) or diag explain(\@BUILD);

isa_ok( $obj, 'Local::Layer2' );

ok( !exists $obj->{x} );

done_testing;

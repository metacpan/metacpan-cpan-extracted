use strict; use warnings;

my $max;
use Test::More tests => $max = 32;

use Class::Observable;
our @ISA = 'Class::Observable';

my ( $n, %seen );
for my $i ( 1 .. 100_000 ) {
	bless \my %hash;
	$n = ( \%hash )->add_observer( 'Foo' );
	$seen{ \%hash }++ or next;
	is( $n, 1, sprintf "new instance at 0x%x was empty (attempt $i)", \%hash );
	--$max > 0 or last;
}

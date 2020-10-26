use strict;
use warnings;
use Test::More;

my @inputs  = ( "Foo", 3.1, '', 3.1, 4.1, '' );
my @outputs = ();

{
	package Local::Foo;
	
	use Moo;
	use Ask;
	use Ask::Callback;
	use Types::Standard -types;
	
	my $Rounded = Int->plus_coercions( Num, 'int($_)' );
	
	has numbers => (
		is       => 'lazy',
		isa      => ArrayRef[ $Rounded ],
		coerce   => 1,
		default  => Ask::Q(
			"Enter some numbers",
			type    => ArrayRef[ $Rounded ],
			backend => 'Ask::Callback'->new(
				input_callback  => sub { shift @inputs },
				output_callback => sub { push @outputs, @_ },
			),
		),
	);
}


my $foo = 'Local::Foo'->new;

is_deeply( $foo->numbers, [ 3, 4 ] );

is_deeply( \@inputs, [] );

like $outputs[0], qr/did not pass type constraint/;

done_testing;

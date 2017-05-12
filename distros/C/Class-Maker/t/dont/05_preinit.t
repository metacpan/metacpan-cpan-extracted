BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;

use Carp;

#use Object::Debugable qw(debugDump);

use Class::Maker;

use Class::Maker::Examples::Shop;

	foreach my $class ( qw( Array Basket SBasket ) )
	{
		#debugDump( $class->new );
	}

	my $basket = new SBasket;

	foreach my $what ( qw(shoe umbrella computer car knife) )
	{
		$basket->push( new SItem( desc => $what, price => '99' ) );
	}

	#debugDump( $basket );

	eval
	{
		1;
	};

	if($@)
	{
		croak "Exception caught: $@\n";

		print 'not ';
	}

printf "ok %d\n", ++$loaded;

BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;

use Carp;

#use Object::Debugable qw(debugDump debugSymbols);

use IO::Extended qw(:all);

use Class::Maker;

use Class::Maker::Examples::Array;

package main;

	my $obj = new Array( _array => [qw( ONE TWO THREE )] );

	#debugDump( $obj );

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

END
{
	#::debugSymbols( 'main::Array::' );
}

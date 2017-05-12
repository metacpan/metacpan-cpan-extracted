BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;

use Carp;

#use Object::Debugable qw(debugDump);

use IO::Extended qw(:all);

use Class::Maker qw(reflect);

use Class::Maker::Examples::Array;

	if( my $obj = new Array( _array => [qw( ONE TWO THREE )] ) )
	{
		$obj->push( qw( four five six ) );

		printfln "Pop: %s", $obj->pop();

		printfln "Shift: %s", $obj->shift();

		$obj->unshift( 'UNSHIFT' );

		printfln "Count: %s", $obj->count();

		#debugDump( $obj );

		$obj->clear();

		println "Clear";

		printfln "Count: %s", $obj->count();
	}

	reflect( 'Array' );

	foreach my $func ( @{ reflect( 'Array', 'methods' ) } )
	{
		print "We can $func\n";
	}

	#debugDump( reflect( 'Array' ) );

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

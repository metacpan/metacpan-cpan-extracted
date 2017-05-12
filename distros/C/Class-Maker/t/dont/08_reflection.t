BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;

use Carp;

#use Object::Debugable qw(debugDump);

#use IO::Extended qw(:all);

use Class::Maker qw(reflect);

use Class::Maker::Examples::Array;

	eval
	{
		my $obj = new Array( _array => [qw( ONE TWO THREE )] ) or die;

		#debugDump( reflect( 'Array' ) );
	};

	if($@)
	{
		croak "Exception caught: $@\n";

		print 'not ';
	}

printf "ok %d\n", ++$loaded;

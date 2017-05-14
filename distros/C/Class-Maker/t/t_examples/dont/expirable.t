BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;
use Object::Expirable;
use Carp;

	eval
	{
		if( my $obj = Object::Expirable->new( creation => time() , expiration => time()+5 ) )
		{
			printf "Is expired ? %s\n", $obj->expirationStatus() ? 'Yes' : 'No' ;

			print "\nOk, then substract 6 secs\n\n";

			$obj->expiration( $obj->expiration - 6 );

			printf "Again, Is expired ? %s\n", $obj->expirationStatus() ? 'Yes' : 'No' ;
		}
	};
	if($@)
	{
		croak "Exception caught: $@\n";

		print 'not ';
	}

printf "ok %d\n", ++$loaded;

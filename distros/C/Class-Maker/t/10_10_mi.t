BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;

use Class::Maker qw(class);

printf "ok %d\n", ++$loaded;


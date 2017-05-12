#!perl

use 5.010;
use strict;
use warnings;
no warnings 'void';

use Benchmark qw(:all);

use Acme::StringFormat ();

say 'Acme::StringFormat/', Acme::StringFormat->VERSION, "\n";

my $src = join ";\n", (q{ 42 % 2 }) x 100;

cmpthese timethese -1 => {
	no__A_SF => sub{
		eval q{ no  Acme::StringFormat; } . $src;
	},
	use_A_SF => sub{
		eval q{ use Acme::StringFormat; } . $src;
	},
	normal => sub{
		eval $src;
	},
};

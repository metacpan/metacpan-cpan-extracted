#!perl -w
use strict;
use warnings FATAL => 'all';

use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

use Params::Util qw(_ARRAY0);
use Data::Util qw(:all);

signeture 'Data::Util' => \&is_array_ref, 'Params::Util' => \&_ARRAY0;

print "Benchmark: Params::Util::_ARRAY0() vs. Data::Util::is_array() vs. ref()\n";

foreach my $o([], {}, bless({}, 'Foo'), undef){
	print "\nFor ", neat($o), "\n";

	cmpthese -1 => {
		'_ARRAY0' => sub{
			for(1 .. 10){
				if(_ARRAY0($o)){
					;
				}
			}
		},
		'is_array_ref' => sub{
			for(1 .. 10){
				if(is_array_ref($o)){
					;
				}
			}
		},
		'ref() eq "ARRAY"' => sub{
			for(1 ..10){
				if(ref($o) eq 'ARRAY'){
					;
				}
			}
		},
	};
}

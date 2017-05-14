use Coro;
use Coro::EV;


my $scalar;

use Coro::LocalScalar::XS;
localize($scalar); # $scalar is now different in all coros. Current value of $scalar is deleted.

# $hash{element} = undef; # hash element MUST exist if you want to localize it correctly
# localize($hash{element}); 

# or
# use Coro::LocalScalar::XS qw//; # don't export localize
# Coro::LocalScalar::XS->localize($scalar);

async {
		$scalar = "thread 1";
		print "1 - $scalar\n";
		cede;
		print "3 - $scalar\n";
		cede;
		print "5 - $scalar\n";
		
};

async {
		$scalar = "thread 2";
		print "2 - $scalar\n";
		cede;
		print "4 - $scalar\n";
		cede;
		print "6 - $scalar\n";
};

EV::loop;




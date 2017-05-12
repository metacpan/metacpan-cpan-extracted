use CookBookB::Mstruct qw( myfunc myfunc2 );

use Devel::Peek 'Dump';

sub ex1 {
	my $ret;
	my $pMystruct;

	# Turn $pMystruct into an array
	$ret = myfunc( $pMystruct );
	print "ret($ret)\n";
	#Dump $pMystruct;

	print "mymember1 = $pMystruct->[0]\n";
	print "mymember2 = $pMystruct->[1]\n";
	print "iData[]: \n";
	print " iData[0] = $pMystruct->[2]->[0]\n";
	print " iData[1] = $pMystruct->[2]->[1]\n";
	print " iData[2] = $pMystruct->[2]->[2]\n";
	print "Data = $pMystruct->[3]\n";
}

sub ex2 {
	my $pMystruct2 = [];
	my $ret;

	# Use a pre-declared array
	$ret = myfunc2( $pMystruct2 );
	print "ret($ret)\n";
	#Dump $pMystruct2;

	print "mymember1 = $pMystruct2->[0]\n";
	print "mymember2 = $pMystruct2->[1]\n";
}

&ex1;
&ex2;

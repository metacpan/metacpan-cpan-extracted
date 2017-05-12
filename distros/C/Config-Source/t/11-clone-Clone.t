use 5.14.0;
use warnings FATAL => 'all';

use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;

use lib $FindBin::Bin;
use CloneTest;

BEGIN {
	eval 'use Clone';
	if( $@ ) {
		plan skip_all => 'Clone required for testing' 
	}
}


use Config::Source clone => \&Clone::clone;

my $config = Config::Source->new;

CloneTest->test( $config );

done_testing();


1;

use 5.14.0;
use warnings FATAL => 'all';

use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;

use lib $FindBin::Bin;
use CloneTest;

BEGIN {
	eval 'use Clone::Fast';
	if( $@ ) {
		plan skip_all => 'Clone::Fast required for testing' 
	}
	
	plan skip_all => 'Clone::Fast does not work correctly...';
}

use Config::Source clone => \&Clone::Fast::clone;

my $config = Config::Source->new;

CloneTest->test( $config );

done_testing();


1;

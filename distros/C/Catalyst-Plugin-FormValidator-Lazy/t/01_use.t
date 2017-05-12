use strict;
use warnings;

use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin , 'lib' ); 

use Test::More tests => 1 ;
use_ok( 'Catalyst::Test' , 'TestApp');



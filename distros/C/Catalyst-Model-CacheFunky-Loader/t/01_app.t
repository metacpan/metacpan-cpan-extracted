use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin , 'lib' ); 

use Test::More qw(no_plan);

use Catalyst::Test 'TestApp' ;
TestApp->setup;

{
    my $page = get('/date') ;
    is( $page , 1  , 'date test' );
}

{
    my $page = get('/context') ;
    is( $page , 1  , 'context test' );
}


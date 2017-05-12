use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin , 'lib' ); 

use Test::More qw(no_plan);

use Catalyst::Test 'TestApp' ;
TestApp->setup;


# Test Custom Param
{
    my $page = get('/') ;
    ok( $page =~ /hello/ , $page );
}



use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin , 'lib' ); 

use Test::More qw(no_plan);

use Catalyst::Test 'TestApp' ;
TestApp->setup;


my $page = get('/');
ok( $page =~ /no porn! Jon!/ , $page );

$page = get('/boin');
ok( $page =~ /boin/ , $page );

$page = get('/foo');
ok( $page =~ /foo/ , $page );

use FindBin;
use File::Spec;
use lib ( File::Spec->catfile( $FindBin::Bin , 'lib' ), '/Users/vkgtaro/Desktop/experimental/catalyst/Catalyst-Runtime-5.71001/lib');

use Test::More qw(no_plan);

use Catalyst::Test 'TestApp' ;
TestApp->setup;
diag( Catalyst->VERSION );

my $page = get('/disable/foo/');
ok( $page =~ /top/ , $page );


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
    my $page = get('/test_custom_param') ;
    ok( $page =~ /ok/ , $page );
}

# Test Strict
{
    my $page =get('/test_strict?osaka=3&kyoto=kinkakuji&hyogo=hyogo&user_id=12');
    ok( $page =~ /ok/ , $page );
}

# Test Loose
ok( get('/test_loose?hyogo=h1&kyoto=kinko&osaka=3') =~ /ok/ );
ok( get('/test_loose?kyoto=kinko&osaka=3') =~ /hyogo/ );

# Test static
{
    my $page =  get('/test_static?neko=10&inu=won' ) ;
    ok( $page =~ /ok/ , $page );
}

# Test regexp
{
    my $page = get('/test_regexp?user_id=23&member_id=43&panda_neko=10');
    ok( $page =~ /ok/ , $page );
}


# Test2 regexp
{
    my $page = get('/test_regexp?user_id=af&member_id=43&panda_neko=10');
    ok( $page =~ /user_id/ , $page );
}


# Test3 regexp
{
    my $page = get('/test_regexp?user_id=23&member_id=43&panda_neko=12');
    ok( $page =~ /panda_neko/ , $page );
}

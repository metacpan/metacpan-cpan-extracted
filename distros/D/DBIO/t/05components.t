use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::ForeignComponent;

#   Tests if foreign component was loaded by calling foreign's method
ok( DBIO::Test::ForeignComponent->foreign_test_method, 'foreign component' );

#   Test for inject_base to filter out duplicates
{   package DBIO::Test::_InjectBaseTest;
    use base qw/ DBIO::Base /;
    package DBIO::Test::_InjectBaseTest::A;
    package DBIO::Test::_InjectBaseTest::B;
    package DBIO::Test::_InjectBaseTest::C;
}
DBIO::Test::_InjectBaseTest->inject_base( 'DBIO::Test::_InjectBaseTest', qw/
    DBIO::Test::_InjectBaseTest::A
    DBIO::Test::_InjectBaseTest::B
    DBIO::Test::_InjectBaseTest::B
    DBIO::Test::_InjectBaseTest::C
/);
is_deeply( \@DBIO::Test::_InjectBaseTest::ISA,
    [qw/
        DBIO::Test::_InjectBaseTest::A
        DBIO::Test::_InjectBaseTest::B
        DBIO::Test::_InjectBaseTest::C
        DBIO::Base
    /],
    'inject_base filters duplicates'
);

use_ok('DBIO::Componentised');

done_testing;

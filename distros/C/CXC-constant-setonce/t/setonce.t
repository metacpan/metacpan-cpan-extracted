#! perl

use Test2::V0;

{
    package MyTest::TooEarly;
    use Test2::V0;
    use CXC::constant::setonce 'CONST';

    subtest 'too early' => sub {
        like( dies { CONST },       qr/before initialization/, 'use before set' );
        like( dies { CONST( 22 ) }, qr/too many arguments /,   'set after failed use fails' );
    };
}

{
    package MyTest::TooLate;
    use Test2::V0;
    use CXC::constant::setonce 'CONST';

    subtest 'too late' => sub {
        ok( lives { CONST( 22 ) }, 'set' );
        is( CONST, 22, 'get' );
        ok( dies { CONST( 22 ) }, 'set after set' );
        is( CONST, 22, 'get still good' );
    };
}


done_testing;

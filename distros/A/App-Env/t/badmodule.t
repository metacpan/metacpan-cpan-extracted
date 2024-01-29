#! perl

use Test2::V0;
use Test::Lib;

use App::Env;
use App::Env::_Util;

subtest import => sub {
    ok( lives { App::Env::import( 'App1' ) }, 'module exists' )
      or note $@;

    like( dies { App::Env::import( 'BadModule' ) }, qr/does not exist/, 'module does not exist', );
};

subtest require => sub {
    is(
        [ App::Env::_Util::require_module( 'App1' ) ],
        array {
            item 'App::Env::Site1::App1';
            item hash {};
            end;
        },
        'module exists',
    );
    is( [ App::Env::_Util::require_module( 'BadModule' ) ], [ U(), U() ], 'module does not exist' );
};

done_testing;

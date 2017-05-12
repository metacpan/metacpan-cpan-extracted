use Test::More;
use Test::Exception;

use App::Kit;

diag("Testing ex() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

ok $app->ex->fsleep(0.25), 'fsleep() returns true';

throws_ok {
    $app->ex->runcom(
        'Starting test',
        [ 'step 1' => 'echo foo' ],
        [ 'step 2' => 'echo bar' ],
    );
}
qr/Due to compile time Shenanigans in an underlying module, you must 'use App::Kit::Util::RunCom;' to enable runcom\(\)\./, 'runcom() dies when not initiated';

ok( !exists $INC{'Unix/Whereis.pm'}, 'Sanity: Unix::Whereis not loaded before whereis()' );
is $app->ex->whereis('perl'), Unix::Whereis::whereis('perl'), 'whereis() matches underlying whereis';
ok( exists $INC{'Unix/Whereis.pm'}, 'Unix::Whereis lazy loaded on initial whereis()' );

{
    no warnings 'redefine';
    no warnings 'once';

    # in order to mock underlying functions we don't test for laziness here, instead we load the module and mock the functions
    local $INC{'IPC/Open3/Utils.pm'} = 1;
    local *IPC::Open3::Utils::run_cmd = sub { is_deeply( \@_, [ 1, 2, 3 ], 'run_cmd() called OK' ) };
    $app->ex->run_cmd( 1, 2, 3 );

    local *IPC::Open3::Utils::put_cmd_in = sub { is_deeply( \@_, [ 4, 5, 6 ], 'put_cmd_in() called OK' ) };
    $app->ex->put_cmd_in( 4, 5, 6 );

    local $INC{'Acme/Spork.pm'} = 1;
    local *Acme::Spork::spork = sub { is_deeply( \@_, [ 7, 8, 9 ], 'spork() called OK' ) };
    $app->ex->spork( 7, 8, 9 );
}

# TODO: more behaviorial tests of run_cmd(), put_cmd_in(), and spork()

done_testing;

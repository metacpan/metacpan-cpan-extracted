use Test::More tests => 2;

BEGIN {
    use_ok( 'App::SlowQuitApps' );
    $App::SlowQuitApps::CONFIGURED = 1;
}

diag( "Testing App::SlowQuitApps $App::SlowQuitApps::VERSION" );

can_ok 'main', qw< delay fastquit slowquit >;

use Test::More tests => 2;

BEGIN {
    use_ok('Async::Selector' );
    use_ok('Async::Selector::Watcher');
}

diag( "Testing Async::Selector $Async::Selector::VERSION, Perl $], $^X" );

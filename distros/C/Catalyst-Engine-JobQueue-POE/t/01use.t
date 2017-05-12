use Test::More tests => 3;

BEGIN {
    use_ok( 'Catalyst::Engine::JobQueue::POE' );
    use_ok( 'Catalyst::Helper::JobQueue::POE' );
    use_ok( 'Catalyst::JobQueue::Job' );
}


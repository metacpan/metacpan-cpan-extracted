use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Database::Async;
use Database::Async::Engine::Empty;

my $db = new_ok(
    'Database::Async', [
        pool => {
            min => 0,
            max => 5
        }
    ]
);
isa_ok(my $pool = $db->pool, 'Database::Async::Pool');
is($pool->min, 0, 'min value passed through from constructor');
is($pool->max, 5, 'max value passed through from constructor');

my $engine = Database::Async::Engine::Empty->new;
is($pool->count, 0, 'no engines in pool yet');
$pool->register_engine($engine);
is($pool->count, 1, 'now have one engine in pool');
$pool->queue_ready_engine($engine);
Scalar::Util::weaken($engine);
is(exception {
    isa_ok(my $f = $pool->next_engine, 'Future');
    ok($f->is_ready, 'the engine is available immediately');
    is($f->get, $engine, 'requested engine matches ready one');
    my $requested = 0;
    local $pool->{request_engine} = sub {
        ++$requested;
    };
    isa_ok(my $next = $pool->next_engine, 'Future');
    is($requested, 1, 'asked for one engine');
    ok(!$next->is_ready, 'still pending on second request');
}, undef, 'can request an engine');
is($engine, undef, 'engine was released when no longer used');

done_testing;


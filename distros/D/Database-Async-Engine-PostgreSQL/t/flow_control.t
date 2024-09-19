use Full::Script qw(:v1);
use feature qw(state);

use Test::More;
use Test::Fatal;
use Test::Deep qw();
use Ryu::Async;
use IO::Async::Loop;
use Database::Async;
use Database::Async::Engine::PostgreSQL;
use Log::Any::Adapter qw(TAP);

plan skip_all => 'set DATABASE_ASYNC_PG_TEST env var to test, but be prepared for it to *delete any and all data* in that database' unless exists $ENV{DATABASE_ASYNC_PG_TEST};

my $loop = IO::Async::Loop->new;
$loop->add(
    my $ryu = Ryu::Async->new
);

my $db;
is(exception {
    $loop->add(
        $db = Database::Async->new(
            type => 'postgresql',
        )
    );
}, undef, 'can safely add to the loop');

$log->debugf('Execute single query');
$log->infof('Have result: %s', await $db->query('select 1')->single);

my $sink = $ryu->sink;
my $max_id;
my $q = $db->query(q{select g.id from generate_series(1, 1000000) g(id)})->row_hashrefs;
my $f = $loop->new_future;
$q->each(sub { $f->done unless $f->is_ready; $max_id = $_->{id} });
$sink->drain_from($q->buffer);
$sink->source->pause;
await Future->wait_any($f->without_cancel, $loop->timeout_future(after => 5));
if(defined $max_id) {
    my $prev = $max_id;
    ok($max_id > 0, 'have non-zero ID from initial data');
    await $loop->delay_future(after => 1);
    is($max_id, $prev, 'ID has not changed');
    await $loop->delay_future(after => 1);
    is($max_id, $prev, 'ID still has not changed');
    $sink->source->resume;
    await $loop->delay_future(after => 1);
    isnt($max_id, $prev, 'ID changes after resume');
} else {
    fail('did not see any rows at all');
}
done_testing;


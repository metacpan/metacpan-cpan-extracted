use strict;
use warnings;

use feature qw(state);
no indirect;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Future::AsyncAwait;
use IO::Async::Loop;
use Database::Async;
use Database::Async::Engine::PostgreSQL;
use Log::Any::Adapter qw(TAP);
use Log::Any qw($log);

plan skip_all => 'set DATABASE_ASYNC_PG_SERVICE env var to test, but be prepared for it to *delete any and all data* in that database' unless exists $ENV{DATABASE_ASYNC_PG_SERVICE};

my $loop = IO::Async::Loop->new;

my $db;
my $app = join '-', 'DBASYNCTEST', $$, 0+{}, $loop->time;
$log->infof('Using app name [%s]', $app);
is(exception {
    $loop->add(
        $db = Database::Async->new(
            type => 'postgresql',
            pool => {
                max => 2,
            },
            engine => {
                service => $ENV{DATABASE_ASYNC_PG_SERVICE},
                application_name => $app,
            },
        )
    );
}, undef, 'can safely add to the loop');

$log->debugf('Execute single query');
$log->tracef('Have result: %s', await Future->wait_any($db->query('select 1')->single, $loop->timeout_future(after => 3)));

# Run this multiple times to ensure that our pool doesn't starve out pending queue if we disconnect after a request
# is queued. This is more of an empirical test than an in-depth logic validation, since we expect that to happen
# at the Database::Async level.
for my $it (1..3) {
    my $f = (async sub {
        await $db->query(q{select pg_sleep(3)})->single;
    })->();
    my $target_pid;
    my $timeout = $loop->timeout_future(after => 2);
    until($timeout->is_ready or $target_pid) {
        note 'Look up PID...';
        my @rows = await $db->query(q{select pg_backend_pid(), * from pg_stat_activity})->row_hashrefs->as_list;
        ($target_pid) = map { $_->{pid} } grep { $_->{application_name} eq $app and $_->{pid} != $_->{pg_backend_pid} } @rows;
    }
    $timeout->cancel;
    note "Terminate PID $target_pid";
    await $db->query(q{select pg_terminate_backend($1)}, $target_pid)->single;
    note "Check our status";
    note $f->state;
    cmp_deeply(exception {
        Future->wait_any(
            $f,
            $loop->timeout_future(after => 3)
        )->get;
    }, methods(code => '57P01'), 'was terminated (error code 57P01)');
}
done_testing;

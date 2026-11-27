# A real preforking server (examples/counter.pl), stopped with signals
# while a Perl client is connected. A graceful stop waits for connections
# to end, and a WebSocket never ends by itself, so the hub has to close
# its connections when the stop begins; otherwise the server would only
# exit after Mojolicious's graceful_timeout of two minutes.
use v5.44;
use Test::More;

plan skip_all => 'set TEST_ONLINE to a PostgreSQL connection string to run this test'
    unless $ENV{TEST_ONLINE};

use FindBin;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojo::Pg;
use Mojo::Promise;
use POSIX qw(WNOHANG);
use Time::HiRes qw(time);

use BoardStreams::Client;

my $schema = 'bs_stop_test';
my $admin  = Mojo::Pg->new($ENV{TEST_ONLINE});
$admin->db->query("drop schema if exists $schema cascade");
$admin->db->query("create schema $schema");

my $port = Mojo::IOLoop::Server->generate_port;
my %running;

# Starts the example application under Mojo::Server::Prefork, with two
# workers and the default graceful_timeout. Returns the manager's pid.
sub start_server {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $ENV{BOARDSTREAMS_PG}     = $ENV{TEST_ONLINE};
        $ENV{BOARDSTREAMS_SCHEMA} = $schema;
        $ENV{MOJO_LOG_LEVEL}      = 'fatal';
        exec $^X, "-I$FindBin::Bin/../lib", "$FindBin::Bin/../examples/counter.pl",
            'prefork', '-w', 2, '-l', "http://127.0.0.1:$port";
        die "exec: $!";
    }
    $running{$pid} = 1;
    return $pid;
}
END { kill KILL => keys %running if %running }

sub wait_for ($condition, $what, $seconds = 15) {
    my $deadline = time + $seconds;
    my $tick     = Mojo::IOLoop->recurring(0.005 => sub { });
    Mojo::IOLoop->one_tick until $condition->() or time > $deadline;
    Mojo::IOLoop->remove($tick);
    return ok $condition->(), $what;
}
sub settle ($promise) {
    my @result;
    $promise->then(sub (@values) { @result = (resolved => @values) }, sub ($error) { @result = (rejected => "$error") });
    wait_for(sub { scalar @result }, 'the promise settled');
    return @result;
}
sub collect ($observable) {
    my @seen;
    $observable->subscribe(sub ($value) { push @seen, $value });
    return \@seen;
}
# Sends the signal to the server and returns how long it took to exit,
# while the client in this process carries on.
sub seconds_to_stop ($pid, $signal, $limit = 20) {
    my $from = time;
    kill $signal => $pid;
    my $gone = 0;
    wait_for(sub { $gone ||= waitpid($pid, WNOHANG) == $pid }, "the server exited after $signal", $limit) or return $limit;
    delete $running{$pid};
    return time - $from;
}

my $bs       = BoardStreams::Client->new(url => "ws://127.0.0.1:$port/boardstreams", min_delay => 0.05, max_delay => 0.3);
my $counter  = $bs->join('counter:stop');
my $events   = collect($counter->events_o);
my $gaps     = collect($counter->gaps_o);
my $statuses = collect($counter->status_o);
my $states   = collect($counter->state_o);

subtest 'a graceful stop (QUIT) lets go of the connections at once' => sub {
    my $server = start_server();
    is_deeply [settle($counter->joined)], ['resolved'], 'joined, once the server was up';
    is_deeply [settle($counter->request('add', { by => 1 }))], [resolved => { n => 1 }], 'a request before the stop';

    # In the middle of being handled when the stop begins: the handler
    # waits half a second before it changes anything.
    my $in_flight = $counter->request('add_later', { after => 0.5 });
    Mojo::Promise->timer(0.15)->wait;
    $counter->action('wave', 'goodbye');

    my $took = seconds_to_stop($server, 'QUIT');
    cmp_ok $took, '<', 5, sprintf 'the server exited in %.1f seconds, not after graceful_timeout', $took;
    wait_for(sub { $statuses->[-1] eq 'joining' }, 'the client noticed that it lost its connection');
    isnt $statuses->[-1], 'rejected', 'the client was not told to stay away';

    # Sent while no server is running.
    my $meanwhile = $counter->request('add', { by => 1 });

    my $replacement = start_server();
    my @answers = map { [settle($_)] } $in_flight, $meanwhile;
    is_deeply [map { $_->[0] } @answers], ['resolved', 'resolved'],
        'the request that was in flight and the one made in between are answered by the new process';
    is_deeply [sort map { $_->[1]{n} } @answers], [2, 3], '...each with its own result';
    wait_for(sub { 1 == grep { $_->{name} eq 'waved' } @$events }, 'the action arrived');
    Mojo::Promise->timer(0.5)->wait;

    is_deeply $counter->state, { n => 3, log => [1, 1, 1] }, 'each request took effect exactly once';
    is scalar(grep { $_->{name} eq 'waved' } @$events), 1, 'the action took effect exactly once';
    is_deeply [map { $_->{seq} } @$events], [1 .. scalar @$events], 'every event arrived, in order, none twice';
    is_deeply $gaps, [], 'no gap was reported: the client rejoined from where it was';
    is scalar @$states, 4, 'the state arrived once on joining and then only as changes';
    is $statuses->[-1], 'joined', 'the client is joined again';

    my $took_term = seconds_to_stop($replacement, 'TERM');
    cmp_ok $took_term, '<', 5, sprintf 'an immediate stop (TERM) is as quick as ever: %.1f seconds', $took_term;
    wait_for(sub { $statuses->[-1] eq 'joining' }, 'the client lost its connection again');
};

$bs->close;
$admin->db->query("drop schema $schema cascade");
done_testing;

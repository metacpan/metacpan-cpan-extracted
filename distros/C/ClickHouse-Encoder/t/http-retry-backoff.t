use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# bulk_inserter retry policy, exercised with a captive transport so no
# network is touched. retry_wait => 0 makes the exponential-backoff
# sleep collapse to zero (window/2 + rand(window/2) == 0), keeping the
# test instant and deterministic.

# A transport that yields a scripted sequence of responses and counts
# how many times post() was called.
{
    package ScriptedHttp;
    sub new {
        my ($class, @responses) = @_;
        bless { queue => [@responses], calls => 0 }, $class;
    }
    sub post {
        my $self = shift;
        $self->{calls}++;
        my $r = shift @{ $self->{queue} };
        die "ScriptedHttp: ran out of scripted responses\n" unless $r;
        return { %$r };
    }
}

my $ok  = { success => 1, status => 200, content => '', headers => {} };
my $e5  = { success => 0, status => 503, content => 'overloaded',
            headers => {} };
my $e4  = { success => 0, status => 400, content => 'bad request',
            headers => {} };
my $net = { success => 0, status => 599, content => 'timeout',
            headers => {} };

# Two 5xx failures then success: 3 posts, flush succeeds.
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        retries => 3, retry_wait => 0);
    $bi->{http} = ScriptedHttp->new($e5, $e5, $ok);
    $bi->push([1]);
    $bi->flush;
    is($bi->{http}{calls}, 3, '5xx,5xx,ok -> 3 attempts, then success');
    is($bi->sent_rows, 1, 'row counted as sent after eventual success');
}

# 4xx fails immediately - no retry (request is malformed).
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        retries => 3, retry_wait => 0);
    $bi->{http} = ScriptedHttp->new($e4, $ok, $ok, $ok);
    $bi->push([1]);
    local $@;
    eval { $bi->flush };
    like($@, qr/HTTP 400/,           '4xx croaks');
    is($bi->{http}{calls}, 1,        '4xx is not retried');
}

# Network error (599) is retryable like 5xx.
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        retries => 2, retry_wait => 0);
    $bi->{http} = ScriptedHttp->new($net, $ok);
    $bi->push([1]);
    $bi->flush;
    is($bi->{http}{calls}, 2, '599 network error is retried');
}

# Retries exhausted: retries => 2 means 1 initial + 2 retries = 3 posts,
# then give up with a descriptive error.
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        retries => 2, retry_wait => 0);
    $bi->{http} = ScriptedHttp->new($e5, $e5, $e5);
    $bi->push([1]);
    local $@;
    eval { $bi->flush };
    like($@, qr/gave up after 2 retries/, 'exhausted retries croak');
    is($bi->{http}{calls}, 3, 'retries=>2 -> 3 total attempts');
}

# retries => 0 disables retrying entirely.
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        retries => 0, retry_wait => 0);
    $bi->{http} = ScriptedHttp->new($e5);
    $bi->push([1]);
    local $@;
    eval { $bi->flush };
    ok($@, 'retries=>0 still croaks on failure');
    is($bi->{http}{calls}, 1, 'retries=>0 -> exactly 1 attempt');
}

# retry_max_wait is accepted and stored (caps the backoff window).
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        retry_max_wait => 5);
    is($bi->{retry_max_wait}, 5, 'retry_max_wait honored');
}

# push_many error recovery: when a mid-batch flush croaks, the `local`
# in push_many must restore the row buffer to the rows that were not
# yet attempted, so a caller wrapping push_many in eval can retry them.
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['v', 'Int32']],
        batch_size => 2, retries => 0, retry_wait => 0);
    $bi->{http} = ScriptedHttp->new($e5);   # first flush fails hard
    local $@;
    eval { $bi->push_many([ [1], [2], [3], [4], [5] ]) };
    ok($@, 'push_many propagates the flush failure');
    is($bi->buffered_count, 3,
       'push_many: rows past the failed batch stay buffered for a retry');
    is($bi->{http}{calls}, 1, 'push_many: only the first batch was attempted');
}

done_testing();

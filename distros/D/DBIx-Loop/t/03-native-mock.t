#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

# Exercise the native (Backend A) C paths without a Postgres: a mock that
# implements exactly the DBD::Pg async surface DBIx::Loop drives -
# prepare({pg_async}) / execute / {pg_socket} / pg_ready / pg_result /
# fetchall_arrayref / errstr. Readiness arrives over a real socketpair from a
# forked child, so the loop genuinely waits on the fd.

BEGIN {
    plan skip_all => 'IO::Async required' unless eval { require IO::Async::Loop; 1 };
}

use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;

# the async surface marker the capability sniff looks for
sub DBD::Pg::PG_ASYNC { 1 }

# ---- the mock --------------------------------------------------------------------

package Mock::Attr;   # anything read via ->FETCH($key)
sub new { my ($c, %h) = @_; bless {%h}, $c }
sub FETCH { $_[0]{ $_[1] } }

package Mock::PgSth;
sub new { my ($c, %h) = @_; bless {%h}, $c }
sub execute {
    my $self = shift;
    my $dbh  = $self->{dbh};
    die "mock execute: connection busy\n" if $dbh->{inflight};
    $dbh->{inflight} = $self;
    # completion arrives asynchronously: a forked child writes one byte to the
    # far end of the socketpair after `delay` seconds
    my $pid = fork; defined $pid or die "fork: $!";
    if (!$pid) {
        select undef, undef, undef, ($self->{delay} || 0.02);
        syswrite $dbh->{notify}, "x", 1;
        POSIX::_exit(0) if eval { require POSIX; 1 };
        exit 0;
    }
    push @{ $dbh->{kids} }, $pid;
    return '0E0';
}
sub fetchall_arrayref { $_[0]{rows} }
sub FETCH {
    my ($s, $k) = @_;
    return scalar @{ $s->{columns} } if $k eq 'NUM_OF_FIELDS';
    return $s->{columns}             if $k eq 'NAME';
    return undef;
}

package Mock::PgDBH;
sub new {
    my ($class) = @_;
    socketpair(my $r, my $w, Socket::AF_UNIX(), Socket::SOCK_STREAM(),
               Socket::PF_UNSPEC()) or die "socketpair: $!";
    return bless {
        sock => $r, notify => $w, inflight => undef, kids => [],
        driver => Mock::Attr->new(Name => 'Pg'),
    }, $class;
}
sub FETCH {
    my ($s, $k) = @_;
    return $s->{driver}          if $k eq 'Driver';
    return fileno($s->{sock})    if $k eq 'pg_socket';
    return undef;
}
sub prepare {
    my ($s, $sql, $attr) = @_;
    die "mock: prepare called without pg_async\n"
        unless $attr && $attr->{pg_async};
    die "mock prepare failed: bad sql\n" if $sql =~ /\bbad\b/;
    my ($delay) = $sql =~ /delay=([\d.]+)/;
    my $fail    = $sql =~ /\bfail_result\b/;
    return Mock::PgSth->new(
        dbh => $s, delay => $delay,
        fail    => $fail,
        columns => [ 'id', 'name' ],
        rows    => [ [ 1, 'rex' ], [ 2, 'milo' ] ],
    );
}
sub pg_ready {
    my ($s) = @_;
    my $rin = ''; vec($rin, fileno($s->{sock}), 1) = 1;
    return select($rin, undef, undef, 0) > 0 ? 1 : 0;
}
sub pg_result {
    my ($s) = @_;
    sysread $s->{sock}, my $b, 1;              # consume the readiness byte
    my $sth = delete $s->{inflight};
    if ($sth && $sth->{fail}) { $s->{errstr} = 'mock result error'; return 0 }
    return 2;                                   # "rows affected"
}
sub errstr     { $_[0]{errstr} }
sub disconnect { waitpid $_, 0 for @{ $_[0]{kids} }; 1 }

# ---- the tests -------------------------------------------------------------------

package main;

my $ad  = DBIx::Loop::Loop::IOAsync->new;
my $dbh = Mock::PgDBH->new;
my $db  = DBIx::Loop->new(dbh => $dbh, loop => $ad);

is($db->capability, 'native', 'mock Pg with PG_ASYNC -> native backend');

# ---- a query really waits on the fd (loop free meanwhile) -----------------------
{
    my $timer_fired = 0;
    $ad->timer(0.05, sub { $timer_fired = 1 });
    my $f = $db->query("SELECT delay=0.15");
    ok(!$f->is_ready, 'future pending right after fire (result not ready)');
    $ad->await($f);
    my $res = ($f->get)[0];
    is_deeply($res->{rows}, [[1, 'rex'], [2, 'milo']], 'rows fetched on completion');
    is_deeply($res->{columns}, ['id', 'name'], 'columns fetched on completion');
    ok($timer_fired, 'a loop timer fired while the query was in flight');
}

# ---- one in flight, the rest FIFO-queue -----------------------------------------
{
    my @f = map { $db->query("SELECT q$_ delay=0.02") } 1 .. 3;
    ok(!$f[1]->is_ready && !$f[2]->is_ready, 'later queries queue behind the first');
    $ad->await($_) for @f;
    is(scalar(grep { $_->is_done } @f), 3, 'all three resolve through one connection');
}

# ---- do() maps rows_affected -----------------------------------------------------
{
    my $w = $db->do("UPDATE t delay=0.02");
    $ad->await($w);
    is(($w->get)[0]{rows_affected}, 2, 'do returns rows_affected from pg_result');
}

# ---- immediate failure: prepare dies -> failed future, connection survives ------
{
    my $f = $db->query("SELECT bad");
    ok($f->is_ready && $f->is_failed, 'prepare death fails the future immediately');
    like($f->failure, qr/bad sql/, 'failure carries the prepare error');
    my $g = $db->query("SELECT after delay=0.02");
    $ad->await($g);
    ok($g->is_done, 'connection still serves after a prepare failure');
}

# ---- pg_result false -> failed future with errstr --------------------------------
{
    my $f = $db->query("SELECT fail_result delay=0.02");
    $ad->await($f);
    ok($f->is_failed, 'pg_result false -> failed future');
    like($f->failure, qr/mock result error/, 'failure carries errstr');
    my $g = $db->query("SELECT again delay=0.02");
    $ad->await($g);
    ok($g->is_done, 'connection still serves after a result failure');
}

$db->disconnect;
done_testing();

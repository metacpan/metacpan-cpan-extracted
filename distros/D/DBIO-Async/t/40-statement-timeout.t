use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Time::HiRes ();
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k54: the connect option statement_timeout.
#
# WHY IT MATTERS. A connection that hangs -- a lock wait, a network partition
# that never resets -- holds its statement's flight, its pool slot and, for a
# blocking call, the caller for as long as the hang lasts. statement_timeout
# gives every statement a time on the wire. When it is up the statement is
# cancelled the way a cancel in flight is (karr k29, k33): its connection is
# reported dead and retired, never handed to the next borrower with a result
# unread, and the caller's Future fails saying which option ran out and after
# how many seconds -- never what the statement was.
#
# WHAT IS REAL. The whole transport -- _query_async, _query_async_pinned, the
# statement queue, the flight register, the Future::IO timer behind _delay on
# the built-in implementation -- and the real DBIO::Async::Pool, with core's
# retirement. The mock owns the DB-specific seams and nothing else. Its server
# never answers a statement, except one whose SQL starts with ANSWER: that
# one is answered at once.

{
  package Hang40;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { id => ++$self->{_next_id}, r => $r, w => $w };
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{shutdown} }, $conn->{id};
    close $conn->{r};
    close $conn->{w};
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, [ $sql, $conn->{id} ];
    syswrite $conn->{w}, 'R' if $sql =~ /\AANSWER/;
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    return Future->done([ 'row', $conn->{id} ]);
  }

  # Every timer the transport asks for, to see it stopped.
  sub _delay {
    my $self = shift;
    my $timer = $self->SUPER::_delay(@_);
    push @{ $self->{timers} }, $timer;
    return $timer;
  }
}

sub new_storage {
  my (%opts) = @_;
  my $storage = Hang40->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(wire shutdown timers);
  $storage->connect_info([{ host => 'localhost', pool_size => 1, %opts }]);
  return $storage;
}

# Run the loop until the Future settles, without dying on a failure.
sub settle { my $f = shift; eval { $f->get }; return $f }

my $SECRET_SQL  = 'SELECT secret_column FROM secret_table';
my $SECRET_BIND = 'bind-VALUE-7731-xyzzy';

sub no_statement_in {
  my ($message, $label) = @_;
  unlike $message, qr/secret_column|secret_table|SELECT/i,
    "$label: the message holds no SQL";
  unlike $message, qr/\Q$SECRET_BIND\E/,
    "$label: the message holds no bind value";
}

# ---------------------------------------------------------------------------
# 0. The option is declared by the backend class, and its value is checked.
# ---------------------------------------------------------------------------

{
  my @own = Hang40->async_option_names;
  ok scalar(grep { $_ eq 'statement_timeout' } @own),
    'statement_timeout is one of the backend\'s async_option_names';
  ok scalar(grep { $_ eq 'statement_timeout' } Hang40->declared_async_option_names),
    '... and so of its declared_async_option_names, beside core\'s';
  ok scalar(grep { $_ eq 'acquire_timeout' } Hang40->declared_async_option_names),
    '... which still hold the core\'s own';

  my $storage = new_storage(statement_timeout => '2.5');
  is $storage->async_option('statement_timeout'), '2.5',
    'a value given is readable with async_option';
  is new_storage()->async_option('statement_timeout'), undef,
    'no value given: undef';

  for my $bad ('SECRET-not-a-number', -1, [ 5 ], { a => 1 }, 'inf', 'nan') {
    my $s = Hang40->new(undef);
    my $ok = eval {
      $s->connect_info([{ host => 'localhost', pool_size => 1, statement_timeout => $bad }]);
      1;
    };
    my $label = 'a value that is ' . (ref $bad ? lc ref $bad . ' ref' : "'$bad'");
    ok !$ok, "$label is refused";
    like $@, qr/statement_timeout.*takes a number of seconds/,
      '... naming the option and the form it takes';
    unlike $@, qr/SECRET|-1|\binf\b|\bnan\b|ARRAY|HASH/i, '... and not the value';
  }

  my $zero = new_storage(statement_timeout => 0);
  is $zero->async_option('statement_timeout'), 0, '0 is accepted (it turns the timeout off)';
}

# ---------------------------------------------------------------------------
# 1. Pooled: the statement is cancelled, the connection retired, the slot free.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage(statement_timeout => 0.2);
  my $pool    = $storage->pool;

  my $t0 = Time::HiRes::time;
  my $f  = $storage->_query_async($SECRET_SQL, [ $SECRET_BIND ]);
  ok !$f->is_ready, 'pooled: the statement is on the wire, unanswered';
  settle($f);
  my $took = Time::HiRes::time - $t0;

  ok $f->is_failed, 'pooled: the caller\'s Future failed';
  like scalar $f->failure,
    qr/\Astatement timed out after 0\.2 seconds \(statement_timeout\)/,
    '... saying which option ran out, and after how many seconds';
  no_statement_in(scalar $f->failure, 'pooled');
  cmp_ok $took, '>=', 0.15, '... not before the time was up';
  cmp_ok $took, '<', 5, '... and not by a hang';

  is_deeply $storage->{shutdown}, [1],
    'pooled: the connection was retired and closed through the transport';
  is $pool->available, 0, '... it is not idle';
  is $pool->size, 0, '... and its slot is free';
  is scalar(keys %{ $storage->{_flights} }), 0, '... the register holds nothing';
  ok $storage->{timers}[0]->is_ready, '... the timer is spent';

  my $g = settle($storage->_query_async('ANSWER next', []));
  ok $g->is_done, 'pooled: the next statement runs';
  is_deeply [ $g->get ], [ [ 'row', 2 ] ],
    '... on a fresh connection, not the one that hung';
}

# ---------------------------------------------------------------------------
# 2. Pinned: the statement fails, the connection is retired at its hand-back,
#    and what waited behind it is failed unsent.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage(statement_timeout => 0.2);
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;

  my $first  = $storage->_query_async_pinned($conn, $SECRET_SQL, [ $SECRET_BIND ]);
  my $behind = $storage->_query_async_pinned($conn, 'SELECT behind', [ $SECRET_BIND ]);
  is scalar @{ $storage->{wire} }, 1, 'pinned: one statement on the wire, one waiting';
  is scalar @{ $storage->{timers} }, 1,
    '... only the statement on the wire has a timer: the queue is not on the clock';

  settle($first);
  ok $first->is_failed, 'pinned: the statement in flight failed';
  like scalar $first->failure,
    qr/\Astatement timed out after 0\.2 seconds \(statement_timeout\)/,
    '... with the timeout';
  no_statement_in(scalar $first->failure, 'pinned');

  ok $behind->is_failed, 'pinned: the statement behind it failed too';
  like scalar $behind->failure, qr/\Anot sent:/, '... unsent';
  is scalar @{ $storage->{wire} }, 1, '... nothing more went on the wire';
  no_statement_in(scalar $behind->failure, 'pinned, behind');

  ok $pool->_connection_is_dead($conn), 'pinned: the connection is reported dead to the pool';
  $pool->release($conn);
  is_deeply $storage->{shutdown}, [1], '... so its hand-back retires it';
  is $pool->size, 0, '... and the slot is free';
}

# ---------------------------------------------------------------------------
# 3. The clock of a waiting statement starts when it is sent.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage(statement_timeout => 30);
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;

  my $a = $storage->_query_async_pinned($conn, 'ANSWER a', []);
  my $b = $storage->_query_async_pinned($conn, 'ANSWER b', []);
  is scalar @{ $storage->{timers} }, 1, 'queue: one timer while the second statement waits';
  settle($a);
  settle($b);
  ok $a->is_done && $b->is_done, 'queue: both statements were answered';
  is scalar @{ $storage->{timers} }, 2, '... the second got its timer when it was sent';
  ok $_->is_cancelled, '... and every timer was stopped when its statement settled'
    for @{ $storage->{timers} };
  is scalar(keys %{ $storage->{_flights} }), 0, '... the register is empty';
  $pool->release($conn);
}

# ---------------------------------------------------------------------------
# 4. A statement that settles in time leaves no timer behind; without the
#    option, or with 0, no timer is made at all.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage(statement_timeout => 30);
  my $f = settle($storage->_query_async('ANSWER ok', []));
  ok $f->is_done, 'in time: the statement completed';
  is scalar @{ $storage->{timers} }, 1, '... it had a timer';
  ok $storage->{timers}[0]->is_cancelled, '... which was cancelled when it settled';
  is scalar(keys %{ $storage->{_flights} }), 0, '... the register holds nothing';

  my $bad = $storage->_query_async('ANSWER later', []);
  $bad->cancel;
  ok $storage->{timers}[1]->is_cancelled, 'cancelled by the caller: the timer is stopped too';
  is scalar(keys %{ $storage->{_flights} }), 0, '... the register holds nothing';
}

for my $case ([ 'no option' => () ], [ 'statement_timeout 0' => (statement_timeout => 0) ]) {
  my ($label, @opts) = @$case;
  my $storage = new_storage(@opts);
  my $f = settle($storage->_query_async('ANSWER ok', []));
  ok $f->is_done, "$label: the statement completed";
  is scalar @{ $storage->{timers} }, 0, "$label: no timer was made";
}

done_testing;

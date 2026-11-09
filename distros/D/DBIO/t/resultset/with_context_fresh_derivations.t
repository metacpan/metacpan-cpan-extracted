use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# ADR 0045 section 3 / karr k281: the derivations that build a FRESH resultset
# instead of cloning the one they are called on -- the six set operations,
# bare, correlate and count_rs (plain and subquery path) -- carry the pinned
# async context of the resultset they are called on, like every other
# derivation (karr k195). Before k281 they dropped it: a *_async on the result
# was not refused, it ran on a pool connection, outside the transaction.
#
# What is asserted is where the statement RAN, never that a slot is set:
#   - inside the transaction: BEGIN, the statement and COMMIT all on the one
#     transaction connection, nothing on the pool;
#   - held past the transaction: refused ('no longer active'), nothing sent;
#   - called on an unbound resultset: on the pool, as before.
#
# The harness is the synchronous fake transport of t/resultset/with_context.t,
# with one difference: the pool hands out a connection of its own name per
# transaction, so two transactions in flight are told apart.

{
  package Test::SyncPool;
  sub new { bless { released => [], txns => 0 }, shift }
  sub acquire     { DBIO::Test::Future->done('POOL') }
  sub acquire_txn { DBIO::Test::Future->done('TXN' . ++$_[0]->{txns}) }
  sub release     { push @{ $_[0]->{released} }, $_[1]; 1 }
  sub shutdown    { 1 }
}

{
  package Test::CtxBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured} = [];
    return $self;
  }
  sub future_class    { 'DBIO::Test::Future' }
  sub sql_maker_class { 'DBIO::SQLMaker' }
  sub _sql_maker_args { (quote_char => '"', name_sep => '.') }
  sub _transform_sql  { $_[1] }
  sub pool { $_[0]->{pool} ||= Test::SyncPool->new }

  # A statement that reaches _query_async left for the pool; one that reaches
  # _query_async_pinned names the connection it was pinned to.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, on => 'the pool' };
    return $self->future_class->done;
  }
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, on => $conn };
    return $self->future_class->done;
  }
}

DBIO::Storage::DBI->register_async_mode( fresh_derivations_backend => 'Test::CtxBackend' );

sub wired_schema {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode('fresh_derivations_backend');
  delete $schema->storage->{_async_storage_obj};
  return ($schema, $schema->storage->_async_storage);
}

# What went over the wire, in order: [ first word of the statement, where ].
sub wire {
  my ($backend) = @_;
  return [ map { [ ($_->{sql} =~ /(\w+)/)[0], $_->{on} ] } @{ $backend->{captured} } ];
}

sub statement {
  my ($backend, $re) = @_;
  return grep { $_->{sql} =~ $re } @{ $backend->{captured} };
}

# Each derivation: how it is derived from the resultset it is called on, the
# async method run on what comes back, and what its statement looks like.
# count_rs returns a ResultSetColumn, the others a ResultSet.
my @derivations = (
  ( map {
      my ($method, $keyword) = @$_;
      {
        name   => $method,
        derive => sub { $_[0]->search({ rank => 1 })->$method( $_[0]->search_rs({ rank => 2 }) ) },
        call   => 'all_async',
        sql    => qr/"rank" = \? \) $keyword SELECT .* "rank" = \? \)\) "me"$/,
      },
    }
    [ union         => 'UNION' ],
    [ union_all     => 'UNION ALL' ],
    [ intersect     => 'INTERSECT' ],
    [ intersect_all => 'INTERSECT ALL' ],
    [ except        => 'EXCEPT' ],
    [ except_all    => 'EXCEPT ALL' ],
  ),
  {
    name   => 'union of three (arrayref of operands)',
    derive => sub {
      $_[0]->search({ rank => 1 })->union([
        $_[0]->search_rs({ rank => 2 }),
        $_[0]->search_rs({ rank => 3 }),
      ]);
    },
    call   => 'all_async',
    sql    => qr/ UNION SELECT .* UNION SELECT /,
  },
  {
    name   => 'bare',
    derive => sub { $_[0]->search({ rank => 1 })->bare },
    call   => 'all_async',
    sql    => qr/FROM "artist" "me"$/,
  },
  {
    name   => 'correlate',
    derive => sub { $_[0]->correlate('cds') },
    call   => 'all_async',
    sql    => qr/FROM cd "cds_alias" WHERE \( "cds_alias"."artist" = "me"."artistid" \)$/,
  },
  {
    name   => 'count_rs',
    derive => sub { $_[0]->search({ rank => 1 })->count_rs },
    call   => 'single_async',
    sql    => qr/^SELECT COUNT\( \* \) FROM "artist" "me" WHERE/,
  },
  {
    name   => 'count_rs with a condition',
    derive => sub { $_[0]->count_rs({ rank => 1 }) },
    call   => 'single_async',
    sql    => qr/^SELECT COUNT\( \* \) FROM "artist" "me" WHERE/,
  },
  {
    name   => 'count_rs over a group_by (subquery)',
    derive => sub { $_[0]->search(undef, { group_by => 'me.rank' })->count_rs },
    call   => 'single_async',
    sql    => qr/^SELECT COUNT\( \* \) FROM \(SELECT .* GROUP BY/,
  },
  {
    name   => 'count_rs over rows (subquery)',
    derive => sub { $_[0]->search(undef, { rows => 2 })->count_rs },
    call   => 'single_async',
    sql    => qr/^SELECT COUNT\( \* \) FROM \(SELECT /,
  },
);

for my $d (@derivations) {
  my ($name, $call) = @{$d}{qw/name call/};

  # Inside the transaction: on its connection, between BEGIN and COMMIT.
  {
    my ($schema, $backend) = wired_schema();

    $backend->txn_do_async(sub {
      my ($ctx) = @_;
      return $d->{derive}->($schema->resultset('Artist')->with_context($ctx), $schema)->$call;
    })->get;

    is scalar( statement($backend, $d->{sql}) ), 1, "$name: its statement was sent";
    is_deeply wire($backend),
      [ [ BEGIN => 'TXN1' ], [ SELECT => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
      "$name: it ran inside the transaction, on its connection, nothing on the pool";
  }

  # Held past the transaction: refused, not sent to the pool.
  {
    my ($schema, $backend) = wired_schema();

    my $held;
    $backend->txn_do_async(sub {
      my ($ctx) = @_;
      $held = $d->{derive}->($schema->resultset('Artist')->with_context($ctx), $schema);
      return DBIO::Test::Future->done;
    })->get;

    throws_ok { $held->$call } qr/no longer active/,
      "$name: held past the transaction it is refused";
    is_deeply wire($backend), [ [ BEGIN => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
      "$name: and nothing was sent in its place";
  }

  # Nothing bound: the pool, as before.
  {
    my ($schema, $backend) = wired_schema();

    $d->{derive}->($schema->resultset('Artist'), $schema)->$call->get;

    is scalar( statement($backend, $d->{sql}) ), 1, "$name, unbound: its statement was sent";
    is_deeply wire($backend), [ [ SELECT => 'the pool' ] ],
      "$name, unbound: on the pool";
  }
}

# ---------------------------------------------------------------------------
# A set operation needs its operands bound alike (karr k324, ADR 0045 addendum
# 2026-10-10): all unbound, or all bound to the one context. Anything else is
# refused when the operation is built, before any operand SQL is rendered, and
# names the operation and the operands that are bound differently. The result of
# an operation over equally bound operands carries that binding, as before.
#
# This replaces two assertions that held the state before the decision (an
# unbound resultset united with a bound one ran on the pool; two transactions'
# resultsets united ran in the first's), and the derivation entry "the operand
# unbound" above. They described what happened, not what is meant.
# ---------------------------------------------------------------------------
my @set_ops = qw(union union_all intersect intersect_all except except_all);

# Runs $code->($artists_rs, $ctx) inside one transaction; returns the wire.
sub in_one_txn {
  my ($code) = @_;
  my ($schema, $backend) = wired_schema();
  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $code->($schema->resultset('Artist'), $ctx);
    return DBIO::Test::Future->done;
  })->get;
  return wire($backend);
}

my $txn_only = [ [ BEGIN => 'TXN1' ], [ COMMIT => 'TXN1' ] ];

# (a) the caller unbound, the operand bound -- every operation
for my $op (@set_ops) {
  my $wire = in_one_txn(sub {
    my ($artists, $ctx) = @_;
    throws_ok {
      $artists->search({ rank => 1 })
              ->$op( $artists->with_context($ctx)->search_rs({ rank => 2 }) );
    } qr/\b$op\b.*operand 0 \(the caller\) is unbound.*operand 1 is bound to /s,
      "$op, the caller unbound and the operand bound: refused, naming both";
  });
  is_deeply $wire, $txn_only, "$op, caller unbound / operand bound: nothing was sent";
}

# (b) the caller bound, the operand unbound -- every operation
for my $op (@set_ops) {
  my $wire = in_one_txn(sub {
    my ($artists, $ctx) = @_;
    throws_ok {
      $artists->with_context($ctx)->search({ rank => 1 })
              ->$op( $artists->search_rs({ rank => 2 }) );
    } qr/\b$op\b.*operand 0 \(the caller\) is bound to .*operand 1 is unbound/s,
      "$op, the caller bound and the operand unbound: refused, naming both";
  });
  is_deeply $wire, $txn_only, "$op, caller bound / operand unbound: nothing was sent";
}

# (c) two different contexts -- two transactions in flight
for my $op (@set_ops) {
  my ($schema, $backend) = wired_schema();
  my ($first, $second) = map { DBIO::Test::Future->new } 1, 2;
  my ($ctx_first, $ctx_second);

  my $txn_first  = $backend->txn_do_async(sub { ($ctx_first)  = @_; $first  });
  my $txn_second = $backend->txn_do_async(sub { ($ctx_second) = @_; $second });

  my $artists = $schema->resultset('Artist');
  throws_ok {
    $artists->with_context($ctx_first)->search({ rank => 1 })
            ->$op( $artists->with_context($ctx_second)->search_rs({ rank => 2 }) );
  } qr/\b$op\b.*operand 0 \(the caller\) is bound to .*operand 1 is bound to /s,
    "$op across two transactions: refused";

  $_->done for $first, $second;
  $_->get for $txn_first, $txn_second;

  is_deeply wire($backend),
    [ [ BEGIN => 'TXN1' ], [ BEGIN => 'TXN2' ], [ COMMIT => 'TXN1' ], [ COMMIT => 'TXN2' ] ],
    "$op across two transactions: nothing was sent";
}

# the two contexts are told apart by identity: the message names a different
# context for each operand
{
  my ($schema, $backend) = wired_schema();
  my ($first, $second) = map { DBIO::Test::Future->new } 1, 2;
  my ($ctx_first, $ctx_second);
  my $txn_first  = $backend->txn_do_async(sub { ($ctx_first)  = @_; $first  });
  my $txn_second = $backend->txn_do_async(sub { ($ctx_second) = @_; $second });

  my $artists = $schema->resultset('Artist');
  my $err = eval {
    $artists->with_context($ctx_first)->union( $artists->with_context($ctx_second) ); 1
  } ? '' : "$@";
  my @named = $err =~ /is bound to (\S+)/g;
  is scalar(@named), 2, 'the message names a context for each of the two operands'
    or diag $err;
  isnt $named[0], $named[1], 'and they are not the same context'
    if @named == 2;

  $_->done for $first, $second;
  $_->get for $txn_first, $txn_second;
}

# (d) an arrayref of operands, one of them bound differently: the message names it
{
  my $wire = in_one_txn(sub {
    my ($artists, $ctx) = @_;
    my $err = eval {
      $artists->search({ rank => 1 })->union([
        $artists->search_rs({ rank => 2 }),
        $artists->with_context($ctx)->search_rs({ rank => 3 }),
        $artists->search_rs({ rank => 4 }),
      ]); 1
    } ? '' : "$@";
    like $err, qr/operand 0 \(the caller\) is unbound, operand 2 is bound to /,
      'arrayref of operands: the deviating operand is named';
    unlike $err, qr/operand [13]/,
      'arrayref of operands: the operands bound like the caller are not named';
  });
  is_deeply $wire, $txn_only, 'arrayref of operands: nothing was sent';
}

# (e) all unbound: unchanged -- the result is unbound, on the pool
for my $op (@set_ops) {
  my ($schema, $backend) = wired_schema();
  my $artists = $schema->resultset('Artist');
  my $rs = $artists->search({ rank => 1 })->$op( $artists->search_rs({ rank => 2 }) );
  ok !defined $rs->_async_context, "$op, all unbound: the result is unbound";
  $rs->all_async->get;
  is_deeply wire($backend), [ [ SELECT => 'the pool' ] ], "$op, all unbound: on the pool";
}

# (f) all on the one context: unchanged -- the result carries the binding
for my $op (@set_ops) {
  my ($schema, $backend) = wired_schema();
  my $same;
  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    my $artists = $schema->resultset('Artist')->with_context($ctx);
    my $rs = $artists->search({ rank => 1 })->$op([
      $artists->search_rs({ rank => 2 }),
      $artists->search_rs({ rank => 3 }),
    ]);
    $same = $rs->_async_context == $ctx;
    return $rs->all_async;
  })->get;
  ok $same, "$op, all on the one context: the result carries that context";
  is_deeply wire($backend),
    [ [ BEGIN => 'TXN1' ], [ SELECT => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
    "$op, all on the one context: it ran inside the transaction";
}

done_testing;

use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => 'PERL_FUTURE_STRICT disables Future\'s plain-return wrapping'
    if $ENV{PERL_FUTURE_STRICT};
}

use Future;
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;

# OFFLINE test for two resolution contracts a caller of this transport depends
# on and nothing pinned (karr k15 points 3 and 5).
#
# 1. update_async / delete_async resolve an affected-row COUNT -- a plain
#    scalar, not rows (DBIO::Storage::Async, "update_async"). This is not
#    cosmetic. Core's Row::update_async reads that number to tell "row not
#    found" from "updated more than one row", exactly as sync _update_body
#    does; hand it an arrayref of rows instead and both diagnostics silently
#    become "1 thing came back, all is well". The select side must stay row-
#    shaped at the same time, so the two are asserted against each other.
#
# 2. A ->then block may return a PLAIN value and the Future wraps it (ADR 0031
#    section 4). Every core RS/Row async helper is written that way -- a
#    ->then that ends in `return $row` or `return \@rows` and not in
#    `return Future->done(...)`. Future has done this since 0.45 and this dist
#    requires 0.52, so the contract holds; what was never pinned is that it
#    holds for the Futures THIS transport actually hands out, which under a
#    Future::IO implementation are not Future.pm objects but a subclass minted
#    by the loop. If that subclass ever overrode the sequencing, every core
#    helper would start failing with "Expected a Future" and the cause would be
#    two dists away.
#
# The transport is real throughout (the same pipe-as-wire mock as t/12): these
# are claims about what a caller receives from select_async / update_async, so
# they are asserted on the objects a caller really receives.

{
  package SrcStub15;
  sub new     { bless {}, shift }
  sub name    { 'artist' }
  sub columns { qw(artistid name rank) }
}

{
  package ShapeMock;
  use base 'DBIO::Async::Storage';
  use Future;

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  # k193 (core "restore select preparation parity"): the async SELECT path
  # prepares its args through the OWNING sync storage's _select_args. This mock
  # is its own owner and mirrors the real return shape (op name first). The
  # update/delete/count assertions this file centres on never reach it; the
  # read-side counter-assertion (test 12) does, and without an owner it throws
  # "async SELECT requires its owning sync storage".
  sub _owner_storage { $_[0] }
  sub _select_args {
    my ($self, @args) = @_;
    return ('select', @args);
  }

  sub _create_pool_connection {
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { r => $r, w => $w };
  }
  sub _shutdown_pool_connection { close $_[1]{r}; close $_[1]{w} }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, $sql;
    syswrite $conn->{w}, 'R';
    return;
  }

  # What a driver's collect yields for the statement just submitted. A write
  # statement yields the engine's affected-row count; a read yields rows. The
  # test sets {next} per scenario, so one mock covers both sides.
  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $b, 1;
    return Future->done(@{ $self->{next} });
  }
}

sub new_storage {
  my @next = @_;
  my $storage = ShapeMock->new(undef);
  $storage->{wire} = [];
  $storage->{next} = [@next];
  $storage->connect_info([{ host => 'localhost' }]);
  return $storage;
}

# ---------------------------------------------------------------------------
# 1. update_async / delete_async resolve the count as a plain scalar.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage(3);
  my $src     = SrcStub15->new;

  my $updated = $storage->update_async($src, { name => 'Miles' }, { id => 1 })->get;

  ok !ref $updated,
    'update_async resolves a plain SCALAR, not a row or a rowset -- the shape '
    . 'Row::update_async reads to detect "not found" and "more than one row"';
  is $updated, 3, '... and it is the affected-row count the engine reported';
  like $storage->{wire}[0], qr/^UPDATE artist SET/,
    'the source was unwrapped to its table name and an UPDATE was issued';
}

{
  my $storage = new_storage(2);

  my $deleted = $storage->delete_async('artist', { id => 1 })->get;
  ok !ref $deleted, 'delete_async resolves a plain SCALAR too';
  is $deleted, 2, '... the affected-row count';
  like $storage->{wire}[0], qr/^DELETE FROM artist/, 'a DELETE was issued';
}

# A transport that resolves more than one value must still yield exactly the
# count -- core takes the FIRST resolved value on purpose rather than handing
# the caller an unshaped list, and a caller doing `my $n = $f->get` in scalar
# context would otherwise get whatever the list happened to end with.
{
  my $storage = new_storage(5, 'diagnostics', 'more');

  my $updated = $storage->update_async('artist', { name => 'x' }, { id => 1 })->get;
  is $updated, 5,
    'a transport resolving extra values still yields exactly the count from '
    . 'update_async (core extracts the one contracted value)';
}

# Zero is a legitimate count and the one the "row not found" diagnostic is
# built on. It must survive as 0 -- a `||` anywhere on this path would turn it
# into undef or an empty string and the diagnostic would never fire.
{
  my $storage = new_storage(0);

  my $updated = $storage->update_async('artist', { name => 'x' }, { id => 999 })->get;
  ok defined $updated, 'an affected-row count of 0 stays DEFINED';
  is $updated, 0, '... and stays 0 -- "no row matched" must remain reportable';
}

# The same shape on the pinned (transaction) path: an in-txn update has to be
# able to detect the same conditions, and it goes through the same builder.
{
  my $storage = new_storage(1);
  my $conn    = $storage->pool->acquire->get;

  my $updated = $storage->_run_crud_pinned(
    'update', $conn, 'artist', { name => 'x' }, { id => 1 },
  )->get;
  is $updated, 1, 'the pinned (txn) update resolves the same plain count';
}

# The sync wrappers (ADR 0001: block via ->get) hand back the same scalar.
{
  my $storage = new_storage(4);
  is $storage->update('artist', { name => 'x' }, {}), 4,
    'the sync update() wrapper returns the count, like sync storage does';
}
{
  my $storage = new_storage(7);
  is $storage->delete('artist', {}), 7,
    'the sync delete() wrapper returns the count too';
}

# The counter-assertion that keeps the two apart: the READ side is unchanged
# and still resolves rows. If the count contract had been implemented by
# reshaping every result, this would go red.
{
  my $storage = new_storage([ 1, 'a' ], [ 2, 'b' ]);

  my @rows = $storage->select_async('artist', ['*'], {})->get;
  is scalar @rows, 2, 'select_async still resolves a LIST of rows';
  is_deeply \@rows, [ [ 1, 'a' ], [ 2, 'b' ] ],
    '... as raw arrayrefs, the cursor shape the RS layer inflates';
}

# ---------------------------------------------------------------------------
# 2. ->then wraps a plain return (ADR 0031 section 4).
# ---------------------------------------------------------------------------

cmp_ok( Future->VERSION, '>=', '0.45',
  'the Future in use wraps plain ->then returns (0.45+); this dist requires '
  . '0.52, so core\'s RS/Row helpers may end a ->then with a bare value' );

{
  my $storage = new_storage([1, 'a'], [2, 'b']);

  my $f = $storage->select_async('artist', ['*'], {});
  my $count = $f->then(sub { my @rows = @_; return scalar @rows })->get;

  is $count, 2,
    'a ->then on a Future THIS transport handed out may return a plain value '
    . '-- the shape every core RS/Row async helper is written in';
}

{
  my $storage = new_storage([1, 'a']);

  my $ref = $storage->select_single_async('artist', ['*'], {})
    ->then(sub { my $row = shift; return { id => $row->[0] } })->get;
  is_deeply $ref, { id => 1 },
    'a plain HASHREF return is wrapped as one value, not flattened';
}

{
  my $storage = new_storage([1]);

  my $chained = $storage->select_async('artist', ['*'], {})
    ->then(sub { return 'a' })
    ->then(sub { return $_[0] . 'b' })->get;
  is $chained, 'ab', 'plain returns chain -- the next ->then receives the value';
}

{
  my $storage = new_storage([1]);

  my $undef_f = $storage->select_async('artist', ['*'], {})
    ->then(sub { return undef });
  my $got = scalar $undef_f->get;
  ok $undef_f->is_done,
    'a ->then returning undef resolves the sequence, it does not fail it';
  ok !defined $got, '... with undef as the result';
}

# And the counter-assertion: an explicitly returned Future is used as the
# sequence, not wrapped inside another one. Without this, "wraps plain returns"
# could equally describe an implementation that wraps everything.
{
  my $storage = new_storage([1]);

  my $inner = $storage->select_async('artist', ['*'], {})
    ->then(sub { return Future->done('from-a-future') })->get;
  is $inner, 'from-a-future',
    'a returned Future is adopted as the sequence, never double-wrapped';
}

# The same on the future_class this transport names, asked directly -- the
# claim is about the class, and the pooled path only ever samples it through
# whatever the loop happened to mint.
{
  my $storage = new_storage();
  is $storage->future_class, 'Future', 'future_class is Future';
  is $storage->future_class->done(1)->then(sub { return 'plain' })->get,
    'plain',
    'and a plain ->then return is wrapped on future_class itself';
}

done_testing;

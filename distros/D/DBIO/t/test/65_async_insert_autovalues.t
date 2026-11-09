use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k331, maintainer decision 2026-10-12 (question 4, way B): a column
# marked { auto_nextval => 1, sequence => ... } is filled by the synchronous
# insert through _prefetch_autovalues. The async insert does not prefetch --
# the prefetch seam (_sequence_fetch_async) is a later card with an ADR -- so
# insert_async REFUSES, loudly, when such a column has no value in the data,
# instead of sending an INSERT that leaves the column NULL (nullable column)
# or dies with a NOT NULL error from the server (not nullable).
#
# Claim of the refusal tests: no statement goes out and the sequence is not
# touched; a value given (plain or literal SQL) is the caller's own and passes.
#
# Mock only.

{
  package K331::SeqStorage;
  use base 'DBIO::Test::Storage';
  # What a driver provides (DBIO::PostgreSQL::Storage::_sequence_fetch): the
  # sequence name is the explicit 'sequence' of the column info here.
  sub _sequence_fetch {
    my ($self, $function, $sequence) = @_;
    push @{ $self->{seq_calls} }, [ $function, $sequence ];
    return 4711;
  }
}

{
  package K331::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { bless { id => ++$_[0]->{_next_id} }, 'K331::Conn' }
}

{
  package K331::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }   # what the PostgreSQL adapter appends
  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K331::Pool->new(
      conninfo => 'fake', size => 1, future_class => $self->future_class,
    );
  }
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, [ $sql, @{ $bind || [] } ];
    return $self->future_class->new->done([ 1 ]);
  }
}

my $schema = DBIO::Test->init_schema;
my $source = $schema->source('Artist');
my $info   = $source->column_info('rank');
$info->{auto_nextval} = 1;
$info->{sequence}     = 'k331_seq';

# --- sync: the reference the refusal stands against ---------------------------
my $storage = $schema->storage;
bless $storage, 'K331::SeqStorage';
$storage->reset_captured;

$storage->insert($source, { name => 'sync' });

is_deeply $storage->{seq_calls}, [ [ 'NEXTVAL', 'k331_seq' ] ],
  'sync insert: _prefetch_autovalues asked the driver for NEXTVAL of the sequence';
my @sync = $storage->captured_sql_bind;
like $sync[0][0], qr/INSERT INTO "artist"\s*\(.*"rank"/s,
  'sync insert: the INSERT names the auto_nextval column';

# --- async ------------------------------------------------------------------
my $backend = K331::Backend->new($schema);
$backend->_owner_storage($storage);
$backend->{captured} = [];
$storage->{seq_calls} = [];

my $f = eval { $backend->insert_async($source, { name => 'async' }) };
my $err = $@;
ok !$f, 'async insert without the auto_nextval column: insert_async returns no Future';
like "$err", qr/auto_nextval/, '... the refusal names auto_nextval';
like "$err", qr/\brank\b/,     '... and the column';
like "$err", qr/Artist/,       '... and the source';
is_deeply $storage->{seq_calls}, [], '... the sequence is not touched';
is scalar @{ $backend->{captured} }, 0, '... and no statement went out';

# a value given is the caller's own -- plain or literal SQL
$f = $backend->insert_async($source, { name => 'given', rank => 7 });
ok $f->is_ready, 'async insert with a plain value for the column passes';
like $backend->{captured}[0][0], qr/"rank"/, '... and the INSERT names the column';

$f = $backend->insert_async($source, { name => 'lit', rank => \"nextval('k331_seq')" });
ok $f->is_ready, 'async insert with literal SQL for the column passes';
like $backend->{captured}[1][0], qr/nextval\('k331_seq'\)/,
  '... and the literal is sent as given';

# a column without auto_nextval is not required
delete $info->{auto_nextval};
$f = $backend->insert_async($source, { name => 'plain' });
ok $f->is_ready, 'async insert: a column without auto_nextval is not required';

# a bare table name has no source to ask
$info->{auto_nextval} = 1;
$f = $backend->insert_async('artist', { name => 'bare' });
ok $f->is_ready, 'async insert on a bare table name is not checked';

done_testing;

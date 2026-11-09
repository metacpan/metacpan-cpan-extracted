use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util ();

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# ADR 0045 / karr k195: the pinned async context bound with with_context must be
# INHERITED by every derived ResultSet / Row / ResultSetColumn -- related /
# search_related (both ResultSet- and Row-level, incl. the generated rel_async),
# page, as_subselect_rs, prefetched children, get_from_storage_async /
# discard_changes_async, copy_async, and a bound resultset carrying a pre-filled
# row cache. k145 only propagated across search_rs, top-level rows and
# get_column; these are the further derivation paths.
#
# Every assertion here proves CONNECTION IDENTITY (the query actually ran on the
# pinned txn connection 'CONN'), not merely that a context slot is present --
# House Rule 7/11 / ticket DONE #4. The harness is the same fully-synchronous
# fake transport used by t/resultset/with_context.t.

{
  package Test::SyncPool;
  sub new { bless { released => [] }, shift }
  sub acquire     { DBIO::Test::Future->done('CONN') }
  sub acquire_txn { DBIO::Test::Future->done('CONN') }
  sub release     { push @{ $_[0]->{released} }, $_[1]; 1 }
  sub shutdown    { 1 }
}

{
  package Test::CtxBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured}  = [];
    $self->{next_rows} = [];
    return $self;
  }
  sub future_class    { 'DBIO::Test::Future' }
  sub sql_maker_class { 'DBIO::SQLMaker' }
  sub _sql_maker_args { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }
  sub pool { $_[0]->{pool} ||= Test::SyncPool->new }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 0 };
    return $self->future_class->done(@{ $self->{next_rows} });
  }
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 1, conn => $conn };
    return $self->future_class->done(@{ $self->{next_rows} });
  }
}

DBIO::Storage::DBI->register_async_mode( with_ctx_backend => 'Test::CtxBackend' );

sub wired_schema {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode('with_ctx_backend');
  delete $schema->storage->{_async_storage_obj};
  my $backend = $schema->storage->_async_storage;
  return ($schema, $backend);
}

sub captured_matching {
  my ($backend, $re) = @_;
  return grep { ($_->{sql} || '') =~ $re } @{ $backend->{captured} };
}

# Assert that exactly the queries matching $re all ran pinned on 'CONN', and
# that at least one such query was captured.
sub pinned_on_conn_ok {
  my ($backend, $re, $desc) = @_;
  my @m = captured_matching($backend, $re);
  ok scalar(@m), "$desc: query was issued";
  ok !( grep { !$_->{pinned} } @m ), "$desc: ran on the PINNED connection";
  ok !( grep { ($_->{conn} || '') ne 'CONN' } @m ), "$desc: on the txn connection";
}

my @ARTISTS = ( [ 1, 'Miles Davis', 13, undef ], [ 2, 'John Coltrane', 13, undef ] );
my @CDS     = ( [ 10, 1, 'Kind of Blue', 1959, undef, undef ] );

# ---------------------------------------------------------------------------
# ResultSet->search_related / related_resultset inherit the pin.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ @CDS ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->search_related('cds')
                  ->all_async;
  })->get;

  # CD's table is a scalar-ref ('cd'), emitted unquoted, and search_related
  # joins it in: SELECT "cds".* FROM "artist" "me" JOIN cd "cds" ...
  pinned_on_conn_ok($backend, qr/JOIN cd/, 'ResultSet search_related');
  ok !( grep { !$_->{pinned} } @{ $backend->{captured} } ),
    'nothing in the search_related txn hit the pool';
}

# ---------------------------------------------------------------------------
# ResultSet->page inherits the pin.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ @ARTISTS ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->search(undef, { rows => 2, order_by => 'me.artistid' })
                  ->with_context($ctx)
                  ->page(1)
                  ->all_async;
  })->get;

  pinned_on_conn_ok($backend, qr/FROM "artist"/, 'ResultSet page');
}

# ---------------------------------------------------------------------------
# ResultSet->as_subselect_rs inherits the pin.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ @ARTISTS ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->search(undef, { order_by => 'me.artistid' })
                  ->with_context($ctx)
                  ->as_subselect_rs
                  ->all_async;
  })->get;

  pinned_on_conn_ok($backend, qr/FROM/, 'ResultSet as_subselect_rs');
}

# ---------------------------------------------------------------------------
# A Row derived from a bound RS: search_related / the multi rel _rs accessor
# inherit the pin.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ [ 1, 'Miles Davis', 13, undef ] ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->first_async
                  ->then(sub {
                    my ($artist) = @_;
                    $backend->{next_rows} = [ @CDS ];
                    return $artist->cds_rs->all_async;
                  });
  })->get;

  # A Row's has_many fetch selects the child table directly: FROM cd "me" WHERE
  # "me"."artist" = ? (CD's scalar-ref table is emitted unquoted).
  pinned_on_conn_ok($backend, qr/FROM cd\b/, 'Row cds_rs (search_related)');
}

# ---------------------------------------------------------------------------
# The generated single-accessor rel_async (belongs_to genre) inherits the pin.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  # CD row with a non-null genreid so the belongs_to actually queries.
  $backend->{next_rows} = [ [ 10, 1, 'Kind of Blue', 1959, 3, undef ] ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('CD')
                  ->with_context($ctx)
                  ->first_async
                  ->then(sub {
                    my ($cd) = @_;
                    $backend->{next_rows} = [ [ 3, 'Jazz' ] ];
                    return $cd->genre_async;
                  });
  })->get;

  pinned_on_conn_ok($backend, qr/FROM "genre"/, 'Row genre_async (rel_async)');
}

# ---------------------------------------------------------------------------
# Prefetched child ResultSet AND child Row inherit the pin: an UPDATE issued on
# a prefetched child must run on the pinned txn connection.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  # JOIN rows for Artist(artistid,name,rank,charfield) prefetch
  # cds(cdid,artist,title,year,genreid,single_track)
  $backend->{next_rows} = [
    [ 1, 'Miles Davis', 13, undef, 10, 1, 'Kind of Blue', 1959, undef, undef ],
  ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->search(undef, { prefetch => 'cds', order_by => 'me.artistid' })
                  ->all_async
                  ->then(sub {
                    my ($artist) = @_;
                    isa_ok $artist, 'DBIO::Test::Schema::Artist', 'prefetch parent';
                    my ($cd) = $artist->cds->all;   # prefetched, no extra query
                    isa_ok $cd, 'DBIO::Test::Schema::CD', 'prefetched child row';
                    $backend->{next_rows} = [ 1 ];  # UPDATE affects one row
                    return $cd->update_async({ title => 'Kind of Blue (remaster)' });
                  });
  })->get;

  pinned_on_conn_ok($backend, qr/^UPDATE cd\b/, 'prefetched child update');
  # the prefetch itself issued only the FROM "artist" join -- no separate cd fetch
  is scalar( captured_matching($backend, qr/FROM cd\b/) ), 0,
    'prefetched child needed no separate SELECT (collapse held)';
}

# ---------------------------------------------------------------------------
# get_from_storage_async on a bound row refetches on the pinned connection.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ [ 1, 'Miles Davis', 13, undef ] ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->first_async
                  ->then(sub {
                    my ($artist) = @_;
                    $backend->{next_rows} = [ [ 1, 'Miles Davis', 13, undef ] ];
                    return $artist->get_from_storage_async;
                  });
  })->get;

  # both the first_async SELECT and the refetch SELECT stayed pinned
  pinned_on_conn_ok($backend, qr/FROM "artist"/, 'get_from_storage_async refetch');
  ok !( grep { !$_->{pinned} } @{ $backend->{captured} } ),
    'no query in the get_from_storage_async txn hit the pool';
}

# ---------------------------------------------------------------------------
# discard_changes_async on a bound row refreshes on the pinned connection.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ [ 1, 'Miles Davis', 13, undef ] ];

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->first_async
                  ->then(sub {
                    my ($artist) = @_;
                    $backend->{next_rows} = [ [ 1, 'Miles Davis', 13, undef ] ];
                    return $artist->discard_changes_async;
                  });
  })->get;

  ok !( grep { !$_->{pinned} } @{ $backend->{captured} } ),
    'discard_changes_async refresh stayed on the pinned connection';
  ok scalar( captured_matching($backend, qr/FROM "artist"/) ) >= 2,
    'discard_changes_async issued its refresh SELECT';
}

# ---------------------------------------------------------------------------
# copy_async on a bound row inserts on the pinned connection. Uses a source
# with NO cascade_copy relationship (Money) so copy takes the flat
# insert_async path rather than the sync cascade punt.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ [ 5, '1.00' ] ];

  my $copy;
  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Money')
                  ->with_context($ctx)
                  ->first_async
                  ->then(sub {
                    my ($money) = @_;
                    $backend->{next_rows} = [ [ 6, '2.00' ] ];  # RETURNING *
                    return $money->copy_async({ amount => '2.00' });
                  });
  })->then(sub { $copy = $_[0] })->get;

  isa_ok $copy, 'DBIO::Test::Schema::Money', 'copy_async resolved a Row';
  pinned_on_conn_ok($backend, qr/^INSERT INTO "money_test"/, 'copy_async insert');
}

# ---------------------------------------------------------------------------
# A bound ResultSet carrying a PRE-FILLED row cache: rows returned from the
# cache inherit the pin, so a write-back off a cached row runs pinned.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();

  # Build + cache a row OUTSIDE any context (sync), then bind and write back.
  my $cached_rs = $schema->resultset('Artist')->search(undef, { cache => 1 });
  my $prebuilt  = $schema->resultset('Artist')->new_result({ artistid => 5, name => 'Bill Evans' });
  $prebuilt->in_storage(1);
  $cached_rs->set_cache([ $prebuilt ]);

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $cached_rs->with_context($ctx)
                     ->all_async
                     ->then(sub {
                       my ($row) = @_;
                       is $row->artistid, 5, 'cache row returned from bound RS';
                       $backend->{next_rows} = [ 1 ];  # UPDATE affects one row
                       return $row->update_async({ name => 'Bill Evans Trio' });
                     });
  })->get;

  pinned_on_conn_ok($backend, qr/^UPDATE "artist"/, 'pre-filled cache row update');

  # The unbound source must NOT have been left dispatching to a foreign pin:
  # its own cached row still routes to the pool (no context leak that would
  # send a pooled write onto a since-terminal connection).
  my ($src_row) = $cached_rs->all;
  ok !defined $src_row->_async_context,
    'unbound source cache row was not left carrying the context';
}

# ---------------------------------------------------------------------------
# DONE #2: a derived path retained past a terminal transaction refuses LOUDLY
# instead of silently falling back to the pool.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  my ($related, $saved_ctx);
  my $gate = DBIO::Test::Future->new;

  my $txn = $backend->txn_do_async(sub {
    ($saved_ctx) = @_;
    $related = $schema->resultset('Artist')
                      ->with_context($saved_ctx)
                      ->search_related('cds');
    return $gate;
  });
  $gate->done('done');
  $txn->get;

  my $before = scalar @{ $backend->{captured} };
  throws_ok { $related->all_async }
    qr/no longer active/,
    'a search_related RS retained past the terminal txn refuses loudly';
  is scalar @{ $backend->{captured} }, $before,
    'the refused derived path dispatched no query (no pool fallback)';
}

# ---------------------------------------------------------------------------
# DONE #2: copy_async with a cascade-copy relationship refuses on a bound
# context rather than silently running the synchronous copy outside the txn.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();
  $backend->{next_rows} = [ [ 1, 'Miles Davis', 13, undef ] ];

  throws_ok {
    $backend->txn_do_async(sub {
      my ($ctx) = @_;
      return $schema->resultset('Artist')
                    ->with_context($ctx)
                    ->first_async
                    ->then(sub {
                      my ($artist) = @_;
                      # Artist has a cascade_copy has_many (cds), so copy is a
                      # multi-statement cascade -- not a single pinned insert.
                      return $artist->copy_async({ name => 'X' });
                    });
    })->get;
  } qr/cannot run on a bound async context/,
    'copy_async cascade refuses on a bound context (consequence 4)';
}

# ---------------------------------------------------------------------------
# karr k203 (edge out of k195): a top-level row cached OUTSIDE any context, that
# itself carries eagerly-prefetched children (the GRANDCHILDREN relative to the
# cached top-level resultset), then bound via with_context. The pin must cascade
# THROUGH the cached grandchildren -- a write-back on a grandchild served from
# the cache runs on the pinned txn connection -- WITHOUT mutating the shared
# rows / related resultsets of the unbound source.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired_schema();

  # Build the tree sync, outside any context: an Artist with a pre-filled cds
  # cache (its prefetched grandchildren), then cache the Artist on a top-level RS.
  my $src_artist = $schema->resultset('Artist')
                          ->new_result({ artistid => 5, name => 'Bill Evans' });
  $src_artist->in_storage(1);
  my $src_cd = $schema->resultset('CD')
                      ->new_result({ cdid => 10, artist => 5, title => 'Sunday', year => 1961 });
  $src_cd->in_storage(1);
  $src_artist->related_resultset('cds')->set_cache([ $src_cd ]);

  my $cached_rs = $schema->resultset('Artist')->search(undef, { cache => 1 });
  $cached_rs->set_cache([ $src_artist ]);

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $cached_rs->with_context($ctx)
                     ->all_async
                     ->then(sub {
                       my ($artist) = @_;
                       is $artist->artistid, 5, 'pre-cached bound artist returned';
                       my ($cd) = $artist->cds->all;   # grandchild, served from cache
                       isa_ok $cd, 'DBIO::Test::Schema::CD', 'grandchild from cache';
                       $backend->{next_rows} = [ 1 ];  # UPDATE affects one row
                       return $cd->update_async({ title => 'Sunday at the Village Vanguard' });
                     });
  })->get;

  # HR11: connection identity on the GRANDCHILD level -- the UPDATE actually ran
  # on the pinned txn connection, not merely a context slot being present.
  pinned_on_conn_ok($backend, qr/^UPDATE cd\b/, 'pre-cached-then-bound grandchild update');
  # the grandchild was served from the cache -- no separate SELECT issued for it
  is scalar( captured_matching($backend, qr/FROM cd\b/) ), 0,
    'grandchild needed no separate SELECT (served from the pre-filled cache)';

  # The UNBOUND source must be untouched: neither the top row, nor its cached
  # child resultset, nor the grandchild row may have been left carrying the pin.
  ok !defined $src_artist->_async_context,
    'unbound source artist row was not mutated';
  ok !defined $src_artist->{related_resultsets}{cds}->_async_context,
    'unbound source child resultset was not mutated (no context leak)';
  my ($leaked_cd) = $src_artist->{related_resultsets}{cds}->all;
  ok !defined $leaked_cd->_async_context,
    'unbound source grandchild row was not mutated';
}

done_testing;

use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Future::Immediate;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# Single-type relationship accessors (belongs_to/might_have/has_one) had no async
# form: the only way to fetch a related row asynchronously was to manually compose
# ->search_related($rel)->single_async yourself -- which, unlike the sync accessor,
# does NOT populate $self->{_relationship_data}{$rel}, so a later sync $row->$rel
# call misses the cache and re-queries. This adds ${rel}_async sugar (generated
# alongside the sync accessor in DBIO::Relationship::Codegen::add_relationship_accessor)
# that closes that gap: it shares the sync accessor's own cache (both directions)
# and its undef_on_null_fk short-circuit (no query for a definitely-NULL FK), and
# populates the cache on resolution so a subsequent sync call is a cache hit.
#
# Only single-type relationships get the sugar -- multi rels (has_many) already
# compose fine via ${rel}_rs->all_async, so no ${rel}_async is generated for them.
#
# Fixture note: CD->belongs_to('artist', ...) is NOT single-type -- its accessor
# name collides with the FK column name 'artist', so DBIO defaults it to the
# inflate/deflate 'filter' accessor style instead (a different code path
# entirely, untouched by this change). CD->very_long_artist_relationship points
# at the same FK column under a non-colliding accessor name, so it IS
# single-type, and is the fixture used below for the non-null happy path.
# CD->genre (nullable genreid, undef_on_null_fk defaults true for belongs_to)
# exercises the null-FK short-circuit. Artist->cds (has_many) is the multi-rel
# negative case.
#
# All of this runs on the mock storage -- no real DB, no event loop.

# --- A mock async backend that delegates to the sync storage ------------------
{
  package My::Mock::RelAsyncBackend;
  use base 'DBIO::Storage::Async';

  sub new { my ($c, $s) = @_; bless { schema => $s, calls => [] }, $c }
  sub future_class { 'DBIO::Future::Immediate' }
  sub connect_info { my $s = shift; $s->{connect_info} = shift if @_; $s->{connect_info} }
  sub disconnect { 1 }

  sub _sync { $_[0]{schema}->storage }

  sub select_async {
    my ($self, @args) = @_;
    push @{$self->{calls}}, 'select';
    my @rows = $self->_sync->select(@args)->all;
    return DBIO::Future::Immediate->done(@rows);
  }

  sub select_single_async {
    my ($self, @args) = @_;
    push @{$self->{calls}}, 'select_single';
    my @row = $self->_sync->select_single(@args);
    return DBIO::Future::Immediate->done( @row ? [ @row ] : undef );
  }
}

DBIO::Storage::DBI->register_async_mode( relasyncmock => 'My::Mock::RelAsyncBackend' );

sub set_mode {
  my ($storage, $mode) = @_;
  $storage->_async_mode($mode);
  delete $storage->{_async_storage_obj};
  return $storage;
}

# fetch a fresh CD row (uncached relationship_data) pointing at artist=1, without
# querying the artist table yet
sub fresh_cd {
  my ($schema) = @_;
  $schema->storage->mock_persistent(qr/FROM cd\b/i, [ [ 10, 1, 'Bitches Brew', '1970', undef, undef ] ]);
  return $schema->resultset('CD')->find(10);
}

# -----------------------------------------------------------------------
# routing + parity: very_long_artist_relationship_async on a live backend
# resolves with the same inflated Artist row the sync accessor would
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'relasyncmock');
  my $backend = $storage->_async_storage;

  my $cd = fresh_cd($schema);
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  $storage->reset_captured;
  my $f = $cd->very_long_artist_relationship_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'very_long_artist_relationship_async returns a Future';
  ok $f->is_ready, 'resolves (immediately, under the mock backend)';

  my $artist = $f->get;
  isa_ok $artist, 'DBIO::Test::Schema::Artist', 'resolves with an inflated Row';
  is $artist->name, 'Miles Davis', 'matches the fixture data';

  is_deeply $backend->{calls}, ['select_single'], 'routed through backend select_single_async';
}

# -----------------------------------------------------------------------
# null-object parity: the sync accessor deliberately returns a falsy-but-defined
# $val as-is ("$val instead of undef so that null-objects can go through" --
# Codegen.pm's own comment on the sync branch) rather than converting it to
# undef, so a related class that overloads boolean-false still survives the
# accessor. The _async accessor must match -- NOT squash a falsy-but-defined
# resolved value down to undef. Stub single_async at the DBIO::ResultSet level
# (restored automatically at the end of this block via `local`) so
# search_related(...)->single_async resolves with a canned null-object,
# bypassing the mock backend/schema entirely -- this isolates the exact
# then-callback branch under review, independent of real inflation plumbing.
# -----------------------------------------------------------------------
{
  package My::NullObject;
  use overload 'bool' => sub { 0 }, '""' => sub { 'NULL_ARTIST' }, fallback => 1;
  sub new { bless {}, shift }
}

{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'relasyncmock');

  my $cd = fresh_cd($schema);
  my $null_object = My::NullObject->new;
  ok !$null_object, 'sanity: the stand-in null-object is falsy (overloaded)';

  local *DBIO::ResultSet::single_async = sub { DBIO::Future::Immediate->done($null_object) };

  my $val = $cd->very_long_artist_relationship_async->get;
  isa_ok $val, 'My::NullObject',
    'the _async accessor preserves a falsy-but-defined resolved value, does NOT squash it to undef';
  ok !$val, 'the preserved value is still falsy (the same overloaded object, not a copy)';
  ok !exists $cd->{_relationship_data}{very_long_artist_relationship},
    'a falsy-but-defined value is NOT cached, matching the sync accessor -- only a truthy $val is cached';
}

# -----------------------------------------------------------------------
# cache-integration, direction 1: async-then-sync HIT. The sugar must populate
# $self->{_relationship_data}{$rel} on resolution, so a later sync accessor call
# is a cache hit (no new query).
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'relasyncmock');

  my $cd = fresh_cd($schema);
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  ok !exists $cd->{_relationship_data}{very_long_artist_relationship}, 'sanity: relationship cache starts empty';

  my $async_artist = $cd->very_long_artist_relationship_async->get;
  ok exists $cd->{_relationship_data}{very_long_artist_relationship},
    'the _async accessor populated the relationship cache on resolution';

  $storage->reset_captured;
  my $sync_artist = $cd->very_long_artist_relationship;
  is scalar( grep { $_->{op} eq 'select' } $storage->captured_queries ), 0,
    'sync accessor after the _async call issues NO new query -- cache hit';
  is $sync_artist->artistid, $async_artist->artistid,
    'sync accessor returns the same cached row the _async accessor resolved with';
}

# -----------------------------------------------------------------------
# cache-integration, direction 2: cached-then-async NO-QUERY. Respect the
# existing cache first, exactly like sync's own cache check.
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'relasyncmock');
  my $backend = $storage->_async_storage;

  my $cd = fresh_cd($schema);
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  my $sync_artist = $cd->very_long_artist_relationship;   # populates the cache, issues one query
  ok exists $cd->{_relationship_data}{very_long_artist_relationship}, 'sanity: sync accessor populated the cache';

  $storage->reset_captured;
  my $f = $cd->very_long_artist_relationship_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'cached _async accessor still returns a Future';
  my $async_artist = $f->get;
  is scalar( $storage->captured_queries ), 0, 'cached _async accessor issued NO query at all';
  is_deeply $backend->{calls}, [], 'cached _async accessor never reached the backend';
  is $async_artist->artistid, $sync_artist->artistid, 'cached _async accessor resolves with the cached row';
}

# -----------------------------------------------------------------------
# THE GAP this closes: manual composition (->search_related($rel)->single_async)
# does NOT populate the cache, so a later sync call still misses and re-queries.
# Pin the gap down so the value of the sugar (above) is demonstrable.
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'relasyncmock');

  my $cd = fresh_cd($schema);
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  $cd->search_related('very_long_artist_relationship')->single_async->get;   # manual composition, no sugar
  ok !exists $cd->{_relationship_data}{very_long_artist_relationship},
    'manual search_related(...)->single_async composition does NOT populate the cache';

  $storage->reset_captured;
  $cd->very_long_artist_relationship;   # sync accessor
  is scalar( grep { $_->{op} eq 'select' } $storage->captured_queries ), 1,
    'sync accessor after manual composition issues a NEW query -- cache MISS (the pre-existing gap)';
}

# -----------------------------------------------------------------------
# multi-type relationships get NO _async sugar (they already compose via
# ${rel}_rs->all_async)
# -----------------------------------------------------------------------
{
  my $schema = DBIO::Test->init_schema;
  my $artist = $schema->resultset('Artist')->new({ artistid => 1 });

  ok !$artist->can('cds_async'), 'has_many relationship "cds" has no cds_async sugar';
}

# -----------------------------------------------------------------------
# filter-type relationships also get NO _async sugar. CD->artist collides with
# the FK column name and so is 'filter'-type, not 'single' (see the fixture
# note up top) -- add_relationship_accessor's 'filter' branch is a completely
# separate code path this change doesn't touch, and it never generates
# ${rel}_async.
# -----------------------------------------------------------------------
{
  ok( !DBIO::Test::Schema::CD->can('artist_async'),
    "filter-type relationship 'artist' (accessor name collides with its FK column) has no artist_async sugar" );
}

# -----------------------------------------------------------------------
# might_have/has_one DO get the sugar -- they route through the same 'single'
# branch as belongs_to. CD->liner_notes is might_have, CD->mandatory_artwork
# is has_one.
# -----------------------------------------------------------------------
{
  ok( DBIO::Test::Schema::CD->can('liner_notes_async'), 'might_have relationship "liner_notes" has liner_notes_async sugar' );
  ok( DBIO::Test::Schema::CD->can('mandatory_artwork_async'), 'has_one relationship "mandatory_artwork" has mandatory_artwork_async sugar' );
}

# -----------------------------------------------------------------------
# null-FK short-circuit: CD->genre is nullable (undef_on_null_fk defaults true
# for belongs_to) -- genre_async must resolve undef with NO query, exactly
# like sync genre()'s own free short-circuit.
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'relasyncmock');
  my $backend = $storage->_async_storage;

  $storage->mock_persistent(qr/FROM cd\b/i, [ [ 10, 1, 'Bitches Brew', '1970', undef, undef ] ]);
  my $cd = $schema->resultset('CD')->find(10);
  is $cd->get_column('genreid'), undef, 'sanity: fixture CD has a NULL genreid';

  $storage->reset_captured;
  my $sync_genre = $cd->genre;
  ok !defined $sync_genre, 'sanity: sync genre() short-circuits to undef on the null FK';
  is scalar( $storage->captured_queries ), 0, 'sanity: sync genre() issued no query for the null FK';

  $storage->reset_captured;
  my $f = $cd->genre_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'genre_async returns a Future even on the short-circuit path';
  ok !defined $f->get, 'genre_async resolves undef on the null FK, matching sync genre()';
  is scalar( $storage->captured_queries ), 0, 'genre_async issued NO query for the null FK';
  is_deeply $backend->{calls}, [], 'genre_async never reached the backend for the null FK';
}

# -----------------------------------------------------------------------
# setter guard: unlike the sync accessor, ${rel}_async does not take a setter
# form (setting a relationship is an in-memory sync operation, not a query)
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'relasyncmock');

  my $cd = fresh_cd($schema);
  my $other_artist = $schema->resultset('Artist')->new({ artistid => 2, name => 'John Coltrane' });

  throws_ok { $cd->very_long_artist_relationship_async($other_artist) }
    qr/very_long_artist_relationship_async doesn't take arguments/,
    'the _async accessor with arguments croaks -- read-only, use the sync setter form instead';
}

# -----------------------------------------------------------------------
# sync instance: the _async accessor croaks (no silent degrade), matching
# every other DBIO *_async
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, undef);   # undef mode == sync

  my $cd = fresh_cd($schema);

  throws_ok { $cd->very_long_artist_relationship_async }
    qr/not an async connection/,
    'the _async accessor on a sync instance croaks';
}

# -----------------------------------------------------------------------
# immediate mode: degrades to the sync accessor (including its own caching),
# still resolves via a Future
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;   # mock default: 'immediate'
  is $schema->storage->_async_mode, 'immediate', 'mock storage defaults to immediate';

  my $cd = fresh_cd($schema);
  $schema->storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);

  my $f = $cd->very_long_artist_relationship_async;
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate _async accessor returns a Future';
  ok $f->is_ready, 'immediate _async accessor is ready';
  my $artist = $f->get;
  isa_ok $artist, 'DBIO::Test::Schema::Artist', 'immediate _async accessor still resolves/inflates';
  ok exists $cd->{_relationship_data}{very_long_artist_relationship},
    'immediate _async accessor still populates the cache (via the sync degrade)';
}

done_testing;

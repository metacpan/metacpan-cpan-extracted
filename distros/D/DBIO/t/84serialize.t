use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;
use Storable qw(dclone freeze nfreeze thaw);
use Scalar::Util qw(refaddr);
use Carp;

sub ref_ne {
  my ($refa, $refb) = map { refaddr $_ or croak "$_ is not a reference!" } @_[0,1];
  cmp_ok(
    $refa, '!=', $refb,
    sprintf('%s (0x%07x != 0x%07x)', $_[2], $refa, $refb),
  );
}

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# Artist columns: artistid, name, rank, charfield
$schema->storage->mock_persistent(
  qr/SELECT "me"\."artistid".*FROM "artist" "me"/i,
  [[ 1, 'Caterwauler McCrae', 13, undef ]],
);

# CD search_related columns: cdid, artist, title, year, genreid, single_track
$schema->storage->mock_persistent(
  qr/SELECT "me"\."cdid".*FROM cd "me"/i,
  [
    [ 1, 1, 'Spoonful of bees',       '1999', undef, undef ],
    [ 2, 1, 'Forkful of chortles',    '2001', undef, undef ],
    [ 3, 1, 'Caterwauling',           '1999', undef, undef ],
  ],
);

$schema->storage->mock_persistent(qr/SELECT COUNT/i, [[3]]);

my %stores = (
  dclone_method => sub { $schema->dclone($_[0]) },

  dclone_func => sub {
    local $DBIO::ResultSource::thaw_schema = $schema;
    dclone($_[0]);
  },

  'freeze/thaw_method' => sub {
    my $ice = $schema->freeze($_[0]);
    $schema->thaw($ice);
  },

  'nfreeze/thaw_func' => sub {
    my $ice = nfreeze($_[0]);
    local $DBIO::ResultSource::thaw_schema = $schema;
    thaw($ice);
  },
);

for my $name (sort keys %stores) {
  my $store = $stores{$name};
  my $copy;

  my $artist = $schema->resultset('Artist')->find(1);

  lives_ok { $copy = $store->($artist) } "serialize row object lives: $name";
  ref_ne($copy, $artist, "row cloned: $name");
  is_deeply($copy, $artist, "serialize row object works: $name");

  my $cd_rs = $artist->search_related('cds');
  is($cd_rs->count, 3, "3 CDs in database: $name");
  ok($cd_rs->next, "advance cursor: $name");

  lives_ok {
    $copy = $store->($cd_rs);
    ref_ne($copy, $cd_rs, "resultset cloned: $name");
    is_deeply(
      [ $copy->all ],
      [ $cd_rs->all ],
      "serialize resultset works: $name",
    );
  } "serialize resultset lives: $name";

  ok $artist->{related_resultsets}, "has related_resultsets key: $name";

  lives_ok { $copy = $store->($artist) }
    "serialize row with related_resultset lives: $name";

  for my $key (keys %$artist) {
    next if $key eq 'related_resultsets';
    next if $key eq '_inflated_column';

    ref_ne($copy->{$key}, $artist->{$key},
      "row internals cloned '$key': $name")
      if ref $artist->{$key};

    is_deeply($copy->{$key}, $artist->{$key},
      "serialize with related_resultset '$key': $name");
  }

  lives_ok(sub { $copy->discard_changes }, "discard_changes works: $name")
    or diag $@;
  is($copy->id, $artist->id, "IDs still match: $name");

  # Cached resultset — should only fire one DB query total
  $schema->is_executed_querycount(sub {
    $cd_rs = $cd_rs->search({}, { cache => 1 });
    my @cds = $cd_rs->all;  # primes cache (1 query)

    $copy = $store->($cd_rs);
    ref_ne($copy, $cd_rs, "cached resultset cloned: $name");
    is_deeply(
      [ $copy->all ],
      [ $cd_rs->all ],
      "serialize cached resultset works: $name",
    );

    is($copy->count, $cd_rs->count, "cached count identical: $name");
  }, 1, "only one DB query fired for cached RS: $name");
}

# Schema-less detached thaw
{
  my $artist = $schema->resultset('Artist')->find(1);

  $artist = dclone $artist;  # no $thaw_schema set — detached result source

  is($artist->name, 'Caterwauler McCrae', 'detached: getting column works');

  ok($artist->update, 'detached: non-dirty update is a noop (no storage needed)');

  ok($artist->name('Beeeeeeees'), 'detached: setting column works');

  ok($artist->is_column_changed('name'), 'detached: column dirtyness works');
  ok($artist->is_changed, 'detached: object dirtyness works');

  my $rs = $artist->result_source->resultset;
  $rs->set_cache([$artist]);
  is($rs->count, 1, 'detached: synthetic resultset count works');

  my $exc = qr/Unable to perform storage-dependent operations with a detached result source/;

  throws_ok { $artist->update }
    $exc, 'detached: correct exception on dirty row update';

  throws_ok { $artist->discard_changes }
    $exc, 'detached: correct exception on discard_changes';

  throws_ok { $rs->find(1) }
    $exc, 'detached: correct exception on rs find';
}

# Direct ResultSource round-trip. Exercises the STORABLE_freeze/STORABLE_thaw
# hooks on DBIO::ResultSource itself — the serialization vehicle that replaced
# DBIO::ResultSourceHandle. Each store localizes $thaw_schema to $schema, so a
# thawed source must re-resolve to the schema's registered, working source.
for my $name (sort keys %stores) {
  my $store = $stores{$name};

  my $rsrc = $schema->source('Artist');
  my $copy;

  lives_ok { $copy = $store->($rsrc) } "serialize result source lives: $name";
  isa_ok($copy, 'DBIO::ResultSource', "thawed source: $name");
  is($copy->source_name, 'Artist', "source_name survives round-trip: $name");
  is($copy->schema, $schema, "thawed source re-attached to schema: $name");
  is(
    $copy->resultset->find(1)->name,
    'Caterwauler McCrae',
    "thawed source builds a working resultset: $name",
  );
}

# count/pager after freeze/thaw.
#
# Both paths reach through result_source->storage, which is precisely what a
# badly resolved thaw leaves unusable - and neither was covered here before,
# so a thawed resultset could look fine and still die the moment it is counted.
for my $name (sort keys %stores) {
  my $store = $stores{$name};

  my $rs = $schema->resultset('CD')->search({}, { rows => 2, page => 2 });
  $rs->pager;  # lazy pager, must not fire a count

  my $copy;
  $schema->is_executed_querycount(
    sub { $copy = $store->($rs) },
    0, "no query fired by freeze/thaw of a paged rs: $name",
  );

  isa_ok($copy->result_source, 'DBIO::ResultSource', "thawed rs result_source: $name");
  is($copy->count, 1, "count on thawed paged rs: $name");
  is($copy->pager->total_entries, 3, "pager total_entries on thawed rs: $name");
  is($copy->pager->current_page, 2, "pager current_page on thawed rs: $name");
  is($copy->pager->entries_on_this_page, 1, "pager entries_on_this_page on thawed rs: $name");
}

# Detached thaw of a paged resultset: no schema channel at all.
{
  my $rs = $schema->resultset('CD')->search({}, { rows => 2, page => 2 });
  $rs->pager;

  my $copy = dclone($rs);  # no $thaw_schema set

  isa_ok($copy->result_source, 'DBIO::ResultSource',
    'detached: thawed rs still carries a result source');
  ok($copy->result_source->{_detached_thaw},
    'detached: thawed rs source is marked detached');
  is_deeply(
    [ sort $copy->result_source->columns ],
    [ sort $rs->result_source->columns ],
    'detached: column metadata survives the thaw',
  );

  my $exc = qr/Unable to perform storage-dependent operations with a detached result source/;

  throws_ok { $copy->count }
    $exc, 'detached: correct exception on rs count';

  throws_ok { $copy->pager->total_entries }
    $exc, 'detached: correct exception on pager total_entries';
}

# compose_namespace + thaw outside the schema channel.
#
# compose_namespace parks the schema *class name* on the composed result
# class' result_source_instance. That is not a schema instance and cannot
# supply a storage, so a thaw must fall through to a detached source. Taking
# it for a live schema instead yielded a half-attached source whose ->storage
# was silently undef, and the count path then died with the useless
# 'Can't call method "_count_select" on an undefined value'.
{
  my $composed = $schema->compose_namespace('DBIO::Test::SerializeNS');
  $composed->storage($schema->storage);

  is(
    DBIO::Test::SerializeNS::CD->result_source_instance->{schema},
    ref $schema,
    'composed result class carries the schema class name, not an instance',
  );

  my $rs = $composed->resultset('CD')->search({}, { rows => 2, page => 2 });
  is($rs->count, 1, 'composed: sanity - live count');

  my $detached = dclone($rs);  # no $thaw_schema set
  ok($detached->result_source->{_detached_thaw},
    'composed: schema class name is not mistaken for a live schema');

  my $exc = qr/Unable to perform storage-dependent operations with a detached result source/;

  throws_ok { $detached->count }
    $exc, 'composed: count throws the detached-source exception';
  throws_ok { $detached->pager->total_entries }
    $exc, 'composed: pager throws the detached-source exception';

  my $attached = $composed->dclone($rs);
  is($attached->count, 1, 'composed: count works when thawed through the schema channel');
  is($attached->pager->total_entries, 3,
    'composed: pager works when thawed through the schema channel');
}

done_testing;

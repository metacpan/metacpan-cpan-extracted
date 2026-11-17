use strict;
use warnings;

use Test::More;
use DBIO::Test::Slow;
use Test::Exception;
use DBI ();
use Storable 'dclone';
use DBIO::SQLite::Test ':DiffSQL';
use lib 't/lib';
use DBDSQLiteQuadmath qw($todo_quadmath);

# having_bind: HAVING with bind values must compare numerically, not as TEXT, on SQLite.
# This test verifies that HAVING clauses with bind parameters return
# correct results. SQLite (and potentially other backends) binds all
# parameters as TEXT by default, which breaks comparisons against
# integer aggregate results due to cross-type comparison rules
# (e.g. INTEGER > TEXT is always FALSE in SQLite).
#
# DBIO's SQLite storage layer fixes this by auto-hinting numeric
# bind values as SQL_INTEGER. This test ensures the fix works and
# catches regressions on any backend.
subtest 'having_bind' => sub {
  my $schema = DBIO::SQLite::Test->init_schema(
    dsn => 'dbi:SQLite::memory:',
  );

  # Test data from populate_schema:
  #   Artist 1 (Caterwauler McCrae) -> CDs 1,2,3 -> 3 tracks each = 9 tracks
  #   Artist 2 (Random Boy Band)    -> CD 4       -> 3 tracks      = 3 tracks
  #   Artist 3 (We Are Goth)        -> CD 5       -> 3 tracks      = 3 tracks

  # --- HAVING with literal condition + bind operator ---
  # Note: hashref keys like { 'COUNT(tracks.trackid)' => ... } do not work
  # with quote_names because SQL::Abstract treats the key as an identifier
  # and quotes the dot as a separator: "COUNT(tracks"."trackid)".
  # Use literal SQL for function calls in HAVING.
  {
    my $rs = $schema->resultset('Artist')->search(undef, {
      join     => { cds => 'tracks' },
      group_by => ['me.artistid', 'me.name'],
      having   => \[ 'COUNT("tracks"."trackid") > ?', 3 ],
    });
    my @artists = $rs->all;
    is(scalar @artists, 1, 'HAVING with literal+bind operator: 1 artist with > 3 tracks');
    is($artists[0]->name, 'Caterwauler McCrae', 'HAVING with literal+bind operator: correct artist')
      if @artists;
  }

  # --- HAVING with literal SQL + bind parameter ---
  {
    my $rs = $schema->resultset('Artist')->search(undef, {
      join     => { cds => 'tracks' },
      group_by => ['me.artistid', 'me.name'],
      having   => \[ 'COUNT(tracks.trackid) > ?', 3 ],
    });
    my @artists = $rs->all;
    is(scalar @artists, 1, 'HAVING with literal+bind: 1 artist with > 3 tracks');
    is($artists[0]->name, 'Caterwauler McCrae', 'HAVING with literal+bind: correct artist')
      if @artists;
  }

  # --- HAVING with literal SQL + typed bind parameter ---
  {
    my $rs = $schema->resultset('Artist')->search(undef, {
      join     => { cds => 'tracks' },
      group_by => ['me.artistid', 'me.name'],
      having   => \[ 'COUNT(tracks.trackid) > ?', [ {}, 3 ] ],
    });
    my @artists = $rs->all;
    is(scalar @artists, 1, 'HAVING with literal+typed bind: 1 artist with > 3 tracks');
    is($artists[0]->name, 'Caterwauler McCrae', 'HAVING with literal+typed bind: correct artist')
      if @artists;
  }

  # --- HAVING with equality (also affected by type mismatch) ---
  {
    my $rs = $schema->resultset('Artist')->search(undef, {
      join     => { cds => 'tracks' },
      group_by => ['me.artistid', 'me.name'],
      having   => \[ 'COUNT(tracks.trackid) = ?', 3 ],
    });
    my @artists = sort { $a->artistid <=> $b->artistid } $rs->all;
    is(scalar @artists, 2, 'HAVING with = bind: 2 artists with exactly 3 tracks');
  }

  # --- HAVING with literal SQL (no bind, sanity check) ---
  {
    my $rs = $schema->resultset('Artist')->search(undef, {
      join     => { cds => 'tracks' },
      group_by => ['me.artistid', 'me.name'],
      having   => \[ 'COUNT(tracks.trackid) > 3' ],
    });
    my @artists = $rs->all;
    is(scalar @artists, 1, 'HAVING with literal (no bind): 1 artist with > 3 tracks');
  }
};

# literal_bind_no_affinity: binds without a column are typed by their spelling; the documented limits are escaped only by typing the bind.
# karr k62. The two limits named in the POD of DBIO::SQLite::Storage
# ("Binds without a column"): a bind that belongs to no column is typed by the
# spelling of its value, and against an expression without affinity that is
# wrong for a canonical integer string that is meant as text, and for a
# non-integer that is meant as a number. The way out is the type at the bind,
# and this file holds that it works: if a typed bind were rebound by the
# storage, the typed cases below turn into the untyped ones and fail.
subtest 'literal_bind_no_affinity' => sub {
  my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

  my $artists = $schema->resultset('Artist');

  $artists->create({ name => '99999', rank => 2 });

  # --- limit 1: canonical integer string, text expression ---

  is $artists->search({ name => '99999' })->count, 1,
    'reference: the column itself matches, its TEXT affinity turns the integer back';

  is $artists->search(\[ 'lower(name) = ?', '99999' ])->count, 0,
    'untyped: lower(name) = ? with a canonical integer string is bound as INTEGER (the documented limit)';

  is $artists->search(\[ 'lower(name) = ?', [ { sqlt_datatype => 'varchar' } => '99999' ] ])->count, 1,
    'sqlt_datatype => varchar at the bind: lower(name) = ? finds the row';

  # --- limit 2: non-integer, numeric expression ---

  # populate_schema: artistid 1, 2, 3, plus the row created above
  my %attrs = ( group_by => 'me.artistid' );

  is $artists->search(undef, {
    %attrs, having => \[ 'AVG(me.artistid) > ?', 1.5 ],
  })->count, 0,
    'untyped: AVG(x) > ? with 1.5 is bound as text and never true (the documented limit)';

  TODO: {
    local $TODO = $todo_quadmath;
    is $artists->search(undef, {
      %attrs,
      having => \[ 'AVG(me.artistid) > ?', [ { dbd_attrs => DBI::SQL_REAL() } => 1.5 ] ],
    })->count, 3,
      'dbd_attrs => SQL_REAL at the bind: AVG(x) > ? counts the groups above 1.5';
  }
};

# reentrancy: search/single/find on one resultset must stay reentrant across repeated passes with deletes in between.
subtest 'reentrancy' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $track_titles = { map { @$_ }
    $schema->resultset('Track')
            ->search({}, { columns => [qw(trackid title)] })
             ->cursor
              ->all
  };

  my $rs = $schema->resultset('Track');

  for my $pass (1,2,3) {
    for my $meth (qw(search single find)) {

      my $id = (keys %$track_titles)[0];
      my $tit = delete $track_titles->{$id};

      my ($o) = $meth eq 'search'
        ? $rs->$meth({ trackid => $id })->all
        : $rs->$meth({ trackid => $id });

      is(
        $rs->count({ trackid => $id }),
        1,
        "Count works (pass $pass)",
      );

      is(
        $o->title,
        $tit,
        "Correct object retrieved via $meth() (pass $pass)"
      );

      $o->delete;

      is(
        $rs->count_rs({ trackid => $id })->next,
        0,
        "Count_rs works (pass $pass)",
      );
    }
  }
};

# related_has_many: search_related over a has_many must iterate, count and all() consistently even with childless parents.
subtest 'related_has_many' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $cd_rs = $schema->resultset('CD')->search ({ artist => { '!=', undef }});

  # create some CDs without tracks
  $cd_rs->create({ artist => 1, title => 'trackless_foo', year => 2010 });
  $cd_rs->create({ artist => 1, title => 'trackless_bar', year => 2010 });

  my $tr_count = $schema->resultset('Track')->count;

  my $tr_rs = $cd_rs->search_related('tracks');


  my @tracks;
  while ($tr_rs->next) {
    push @tracks, $_;
  }

  is (scalar @tracks, $tr_count, 'Iteration is correct');
  is ($tr_rs->count, $tr_count, 'Count is correct');
  is (scalar ($tr_rs->all), $tr_count, 'All is correct');
};

# auto_join: joins are discovered automatically from dotted search condition keys.
# Test auto-discovery of joins from search condition keys.
# When a search condition references a relationship via dotted notation
# (e.g. 'artist.name'), the required join should be added automatically
# without the user needing to specify { join => 'artist' }.
subtest 'auto_join' => sub {
  my $schema = DBIO::SQLite::Test->init_schema;

  # Test data from populate_schema:
  #   Artist 1 (Caterwauler McCrae) -> CDs 1,2,3
  #   Artist 2 (Random Boy Band)    -> CD 4
  #   Artist 3 (We Are Goth)        -> CD 5
  #   CD 1 -> Tracks 16,17,18
  #   CD 2 -> Tracks 4,5,6
  #   etc.

  # --- belongs_to auto-join ---
  {
    my @cds = $schema->resultset('CD')->search(
      { 'artist.name' => 'Caterwauler McCrae' }
    )->all;
    is(scalar @cds, 3, 'auto-join belongs_to: found 3 CDs');
  }

  # --- has_many auto-join ---
  {
    my @cds = $schema->resultset('CD')->search(
      { 'tracks.title' => 'Boring Name' }
    )->all;
    is(scalar @cds, 1, 'auto-join has_many: found 1 CD');
  }

  # --- count works with auto-join ---
  {
    my $count = $schema->resultset('CD')->search(
      { 'artist.name' => 'Caterwauler McCrae' }
    )->count;
    is($count, 3, 'auto-join works with count');
  }

  # --- chained search preserves auto-join ---
  {
    my $rs = $schema->resultset('CD')->search(
      { 'artist.name' => 'Caterwauler McCrae' }
    );
    my @cds = $rs->search({ year => { '>' => 1998 } })->all;
    is(scalar @cds, 2, 'chained search with auto-join');
  }

  # --- explicit join still works ---
  {
    my @cds = $schema->resultset('CD')->search(
      { 'artist.name' => 'Caterwauler McCrae' },
      { join => 'artist' },
    )->all;
    is(scalar @cds, 3, 'explicit join still works');
  }

  # --- me.column does not trigger auto-join ---
  {
    my @cds = $schema->resultset('CD')->search(
      { 'me.title' => 'Spoonful of bees' }
    )->all;
    is(scalar @cds, 1, 'me.column does not trigger auto-join');
  }

  # --- non-relationship dotted name does not crash ---
  {
    my $rs = $schema->resultset('CD')->search(
      { 'nonexistent.column' => 'foo' }
    );
    # Should not auto-join (nonexistent is not a relationship)
    # The query will use the condition as-is; it may fail at DB level
    # but should not throw during ResultSet construction
    ok(defined $rs, 'non-relationship dotted name does not crash RS construction');
  }

  # --- multiple auto-joins ---
  {
    my @cds = $schema->resultset('CD')->search(
      {
        'artist.name' => 'Caterwauler McCrae',
        'tags.tag'    => 'Blue',
      },
    )->all;
    is(scalar @cds, 3, 'multiple auto-joins in one search');
  }
};

# preserve_original_rs: searching (with prefetch) must not modify the attributes of the original resultset.
subtest 'preserve_original_rs' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  # A search() with prefetch seems to pollute an already joined resultset
  # in a way that offsets future joins (adapted from a test case by Debolaz)
  {
    my ($cd_rs, $attrs);

    # test a real-life case - rs is obtained by an implicit m2m join
    $cd_rs = $schema->resultset ('Producer')->first->cds;
    $attrs = dclone( $cd_rs->{attrs} );

    $cd_rs->search ({})->all;
    is_deeply (dclone($cd_rs->{attrs}), $attrs, 'Resultset attributes preserved after a simple search');

    lives_ok (sub {
      $cd_rs->search ({'artist.artistid' => 1}, { prefetch => 'artist' })->all;
      is_deeply (dclone($cd_rs->{attrs}), $attrs, 'Resultset attributes preserved after search with prefetch');
    }, 'first prefetching search ok');

    lives_ok (sub {
      $cd_rs->search ({'artist.artistid' => 1}, { prefetch => 'artist' })->all;
      is_deeply (dclone($cd_rs->{attrs}), $attrs, 'Resultset attributes preserved after another search with prefetch')
    }, 'second prefetching search ok');


    # test a regular rs with an empty seen_join injected - it should still work!
    $cd_rs = $schema->resultset ('CD');
    $cd_rs->{attrs}{seen_join}  = {};
    $attrs = dclone( $cd_rs->{attrs} );

    $cd_rs->search ({})->all;
    is_deeply (dclone($cd_rs->{attrs}), $attrs, 'Resultset attributes preserved after a simple search');

    lives_ok (sub {
      $cd_rs->search ({'artist.artistid' => 1}, { prefetch => 'artist' })->all;
      is_deeply (dclone($cd_rs->{attrs}), $attrs, 'Resultset attributes preserved after search with prefetch');
    }, 'first prefetching search ok');

    lives_ok (sub {
      $cd_rs->search ({'artist.artistid' => 1}, { prefetch => 'artist' })->all;
      is_deeply (dclone($cd_rs->{attrs}), $attrs, 'Resultset attributes preserved after another search with prefetch')
    }, 'second prefetching search ok');
  }

  # Also test search_related, but now that we have as_query simply compare before and after
  my $artist = $schema->resultset ('Artist')->first;
  my %q;

  $q{a2a}{rs} = $artist->search_related ('artwork_to_artist');
  $q{a2a}{query} = $q{a2a}{rs}->as_query;

  $q{artw}{rs} = $q{a2a}{rs}->search_related ('artwork',
    { },
    { join => ['cd', 'artwork_to_artist'] },
  );
  $q{artw}{query} = $q{artw}{rs}->as_query;

  $q{cd}{rs} = $q{artw}{rs}->search_related ('cd', {}, { join => [ 'artist', 'tracks' ] } );
  $q{cd}{query} = $q{cd}{rs}->as_query;

  $q{artw_back}{rs} = $q{cd}{rs}->search_related ('artwork',
    {}, { join => { artwork_to_artist => 'artist' } }
  )->search_related ('artwork_to_artist', {}, { join => 'artist' });
  $q{artw_back}{query} = $q{artw_back}{rs}->as_query;

  for my $s (qw/a2a artw cd artw_back/) {
    my $rs = $q{$s}{rs};

    lives_ok ( sub { $rs->first }, "first() on $s does not throw an exception" );

    lives_ok ( sub { $rs->count }, "count() on $s does not throw an exception" );

    is_same_sql_bind ($rs->as_query, $q{$s}{query}, "$s resultset unmodified (as_query matches)" );
  }

  # ensure nothing pollutes the attrs of an existing rs
  {
    my $fresh = $schema->resultset('CD');

    isa_ok ($fresh->find(1), 'DBIO::Test::CD' );
    isa_ok ($fresh->single({ cdid => 1}), 'DBIO::Test::CD' );
    isa_ok ($fresh->search({ cdid => 1})->next, 'DBIO::Test::CD' );
    is ($fresh->count({ cdid => 1}), 1 );
    is ($fresh->count_rs({ cdid => 1})->next, 1 );

    ok (! exists $fresh->{cursor}, 'Still no cursor on fresh rs');
    ok (! exists $fresh->{_attrs}{_last_sqlmaker_alias_map}, 'aliasmap did not leak through' );

    my $n = $fresh->next;

    # check that we are not testing for deprecated slotnames
    ok ($fresh->{cursor}, 'Cursor at expected slot after fire');
    ok (exists $fresh->{_attrs}{_last_sqlmaker_alias_map}, 'aliasmap at expected slot after fire' );
  }
};

done_testing;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test ':DiffSQL';

# Each subtest was a file of its own; every one builds its own schema.

# WHY: a bind attribute must reach the SQL in the right order when combined with chained searches and custom sources (the cookbook technique).
subtest 'bind_attr' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $where_bind = {
      where => \'name like ?',
      bind  => [ 'Cat%' ],
  };

  my $rs;

  {
      # First, the simple cases...
      $rs = $schema->resultset('Artist')->search(
              { artistid => 1 },
              $where_bind,
      );

      is ( $rs->count, 1, 'where/bind combined' );

      $rs= $schema->resultset('Artist')->search({}, $where_bind)
          ->search({ artistid => 1});

      is ( $rs->count, 1, 'where/bind first' );

      $rs = $schema->resultset('Artist')->search({ artistid => 1})
          ->search({}, $where_bind);

      is ( $rs->count, 1, 'where/bind last' );

      # and the complex case
      $rs = $schema->resultset('CustomSql')->search({}, { bind => [ 1999 ] })
          ->search({ 'artistid' => 1 }, {
              where => \'title like ?',
              bind => [ 'Spoon%' ] });
      is ( $rs->count, 1, '...cookbook + chained search with extra bind' );
  }

  {
    # More complex cases, based primarily on the Cookbook
    # "Arbitrary SQL through a custom ResultSource" technique,
    # which seems to be the only place the bind attribute is
    # documented.  Breaking this technique probably breaks existing
    # application code.
    my $source = DBIO::Test::Artist->result_source_instance;
    my $new_source = $source->new($source);
    $new_source->source_name('Complex');

    $new_source->name(\<<'');
  ( SELECT a.*, cd.cdid AS cdid, cd.title AS title, cd.year AS year
    FROM artist a
    JOIN cd ON cd.artist = a.artistid
    WHERE cd.year = ?)

    $schema->register_extra_source('Complex' => $new_source);

    $rs = $schema->resultset('Complex')->search({}, { bind => [ 1999 ] });
    is ( $rs->count, 1, 'cookbook arbitrary sql example' );

    $rs = $schema->resultset('Complex')->search({ 'artistid' => 1 }, { bind => [ 1999 ] });
    is ( $rs->count, 1, '...cookbook + search condition' );

    $rs = $schema->resultset('Complex')->search({}, { bind => [ 1999 ] })
        ->search({ 'artistid' => 1 });
    is ( $rs->count, 1, '...cookbook (bind first) + chained search' );

    $rs = $schema->resultset('Complex')->search({}, { bind => [ [{ sqlt_datatype => 'datetime'} => 1999 ] ] })->search({}, { where => \"title LIKE ?", bind => [ 'Spoon%' ] });
    is_same_sql_bind(
      $rs->as_query,
      "(SELECT \"me\".\"artistid\", \"me\".\"name\", \"me\".\"rank\", \"me\".\"charfield\" FROM (SELECT a.*, cd.cdid AS cdid, cd.title AS title, cd.year AS year FROM artist a JOIN cd ON cd.artist = a.artistid WHERE cd.year = ?) \"me\" WHERE title LIKE ?)",
      [
        [ { sqlt_datatype => 'datetime' } => '1999' ],
        [ {} => 'Spoon%' ]
      ],
      'got correct SQL'
    );
  }

  {
    # More complex cases, based primarily on the Cookbook
    # "Arbitrary SQL through a custom ResultSource" technique,
    # which seems to be the only place the bind attribute is
    # documented.  Breaking this technique probably breaks existing
    # application code.

    $rs = $schema->resultset('CustomSql')->search({}, { bind => [ 1999 ] });
    is ( $rs->count, 1, 'cookbook arbitrary sql example (in separate file)' );

    $rs = $schema->resultset('CustomSql')->search({ 'artistid' => 1 }, { bind => [ 1999 ] });
    is ( $rs->count, 1, '...cookbook (in separate file) + search condition' );

    $rs = $schema->resultset('CustomSql')->search({}, { bind => [ 1999 ] })
        ->search({ 'artistid' => 1 });
    is ( $rs->count, 1, '...cookbook (bind first, in separate file) + chained search' );

    $rs = $schema->resultset('CustomSql')->search({}, { bind => [ 1999 ] })->search({}, { where => \"title LIKE ?", bind => [ 'Spoon%' ] });
    is_same_sql_bind(
      $rs->as_query,
      "(SELECT \"me\".\"artistid\", \"me\".\"name\", \"me\".\"rank\", \"me\".\"charfield\" FROM (SELECT a.*, cd.cdid AS cdid, cd.title AS title, cd.year AS year FROM artist a JOIN cd ON cd.artist = a.artistid WHERE cd.year = ?) \"me\" WHERE title LIKE ?)",
      [
        [ {} => '1999' ],
        [ {} => 'Spoon%' ]
      ],
      'got correct SQL (cookbook arbitrary SQL, in separate file)'
    );
  }

  done_testing;
};

# WHY: set_cache must clear previously built related resultsets, or they serve stale rows.
subtest 'cache' => sub {
  my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

  # Test how related_resultset and set_cache interact

  for my $i (0, 1) {

    # We do this twice for comparison.
    #
    # The first time we will just set the cache and get the related resultset.
    #
    # The second time we will additionally get $cd_rset->related_resultset('artist') first.
    #
    # In 0.082840, however, this has the undesirable effect that even after set_cache is called,
    # subsequent calls to $cd_rset->related_resultset('artist') reuse the previously generated resultset,
    # instead of returning a resultset with the items from the cache.

    my @tracks = $schema->resultset('Track')->search({ title => 'Apiary' })->all;

    my $cd_rset = $tracks[0]->related_resultset('cd');

    my @cds = $schema->resultset('CD')->search({ cdid => 1 }, { prefetch => 'artist' })->all;

    my ($artist_rset_before, $artist_rset_after);

    if ($i) {
      $artist_rset_before = $cd_rset->related_resultset('artist');
    }

    $cd_rset->set_cache(\@cds);

    $artist_rset_after = $cd_rset->related_resultset('artist');

    is scalar $cd_rset, 1, 'Track should belong to a CD';
    is scalar @{ $cd_rset->get_cache || [] }, 1, 'CD cache should contain one item';

    is scalar $cd_rset->related_resultset('artist'), 1, 'Track should belong to an Artist';

    # The following fails when DBIO::ResultSet::set_cache does not clear related resultsets
    is scalar @{ $artist_rset_after->get_cache || [] }, 1, 'Artist cache should contain one item';
  }

  done_testing;
};

# WHY: __strip_relcond must cope with column names holding spaces and punctuation.
subtest 'column_name_spaces' => sub {
  my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

  # Test that __strip_relcond handles column names with non-word characters
  # This is the fix from DBIx::Class PR #129: changing (\w+) to (.+) in the
  # regex that strips foreign/self prefixes from relationship conditions.

  my $rsrc = $schema->source('Artist');

  # __strip_relcond strips 'foreign.' and 'self.' prefixes from condition keys/values
  # With the old \w+ regex, column names containing spaces or punctuation would
  # fail to match, returning an empty hashref instead of the stripped column names.

  # Test with normal column names (should always work)
  {
    my $cond = { 'foreign.artistid' => 'self.artistid' };
    my $stripped = $rsrc->__strip_relcond($cond);
    is_deeply(
      $stripped,
      { 'artistid' => 'artistid' },
      '__strip_relcond works with normal column names',
    );
  }

  # Test with column names containing spaces
  {
    my $cond = { 'foreign.foo bar' => 'self.baz quux' };
    my $stripped = $rsrc->__strip_relcond($cond);
    is_deeply(
      $stripped,
      { 'foo bar' => 'baz quux' },
      '__strip_relcond works with column names containing spaces',
    );
  }

  # Test with column names containing punctuation (like PunctuatedColumnName schema)
  {
    my $cond = { q{foreign.foo ' bar} => q{self.bar/baz} };
    my $stripped = $rsrc->__strip_relcond($cond);
    is_deeply(
      $stripped,
      { q{foo ' bar} => q{bar/baz} },
      '__strip_relcond works with column names containing punctuation',
    );
  }

  # Test with column names containing semicolons
  {
    my $cond = { 'foreign.baz;quux' => 'self.id' };
    my $stripped = $rsrc->__strip_relcond($cond);
    is_deeply(
      $stripped,
      { 'baz;quux' => 'id' },
      '__strip_relcond works with column names containing semicolons',
    );
  }

  # Test with multiple columns, some with special characters
  {
    my $cond = {
      'foreign.normal_col'  => 'self.id',
      'foreign.spaced col'  => 'self.another col',
    };
    my $stripped = $rsrc->__strip_relcond($cond);
    is_deeply(
      $stripped,
      { 'normal_col' => 'id', 'spaced col' => 'another col' },
      '__strip_relcond works with mixed normal and spaced column names',
    );
  }

  done_testing;
};

# WHY: count_literal must agree with the equivalent search-based count.
subtest 'count_literal' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  # --- count_literal basic ---
  {
    my $count = $schema->resultset('CD')->count_literal('1 = 1');
    ok($count > 0, 'count_literal with always-true returns positive count');
    is($count, $schema->resultset('CD')->count, 'count_literal 1=1 matches total count');
  }

  # --- count_literal with condition ---
  {
    my $count = $schema->resultset('CD')->count_literal('year = ?', 1999);
    ok(defined $count, 'count_literal with bind value returns defined count');
    is(
      $count,
      $schema->resultset('CD')->search({ year => 1999 })->count,
      'count_literal matches equivalent search count'
    );
  }

  # --- count_literal with impossible condition ---
  {
    my $count = $schema->resultset('CD')->count_literal('1 = 0');
    is($count, 0, 'count_literal with always-false returns 0');
  }

  done_testing;
};

# WHY: find on a literal or subquery key must work through search and be refused by find.
subtest 'find_on_subquery_cond' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();
  my $rs = $schema->resultset('Artist');

  for my $id (
    2,
    \' = 2 ',
    \[ '= ?', 2 ],
  ) {
    # find needs a concrete value for the key (ADR 0070): literal SQL is looked
    # up through search, the concrete value through find as well
    lives_ok {
      is( $rs->search({ artistid => $id })->single->id, 2 );
      is( $rs->find({ artistid => $id })->id, 2 ) unless ref $id;
    } "Correctly found artist with id of @{[ explain $id ]}";
  }

  for my $id (
    2,
    \'2',
    \[ '?', 2 ],
  ) {
    my $cond = { artistid => { '=', $id } };
    lives_ok {
      is( $rs->search($cond)->single->id, 2 );
      is( $rs->find($cond)->id, 2 ) unless ref $id;
    } "Correctly found artist with id of @{[ explain $cond ]}";
  }

  # literal SQL is no concrete value: find refuses it instead of running it
  for my $cond (
    { artistid => \' = 2 ' },
    { artistid => \[ '= ?', 2 ] },
    { artistid => { '=', \'2' } },
    { artistid => { '=', \[ '?', 2 ] } },
  ) {
    throws_ok {
      $rs->find($cond)
    } qr/find\(\) needs a condition that gives every column of one unique constraint of source 'Artist' a concrete value/,
      'find refuses literal SQL as the value of the key';
  }

  done_testing;
};

# WHY: an as/columns spec that worked by accident must keep working (see the comment below).
# From http://lists.scsys.co.uk/pipermail/dbix-class/2013-February/011119.html
#
# > Right, at this point we have an "undefined situation turned into an
# > unplanned feature", therefore 0.08242 will downgrade the exception to a
# > single-warning-per-process. This seems like a sane middle ground for
# > "you gave me an 'as' that worked by accident before - fix it at your
# > convenience".
#
# When the things were reshuffled it became apparent implementing a warning
# for the HRI case *only* is going to complicate the code a lot, without
# adding much benefit at this point. So just make sure everything works the
# way it used to and move on
subtest 'inflatemap_abuse' => sub {
  my $s = DBIO::SQLite::Test->init_schema();

  my $rs_2nd_track = $s->resultset('Track')->search(
    { 'me.position' => 2 },
    {
      join => { cd => 'artist' },
      columns => [ 'me.title', { 'artist.cdtitle' => 'cd.title' }, 'artist.name' ],
      order_by => [ 'artist.name', { -desc => 'cd.cdid' }, 'me.trackid' ],
    }
  );

  is_deeply (
    [ map { $_->[-1] } $rs_2nd_track->cursor->all ],
    [ ('Caterwauler McCrae') x 3, 'Random Boy Band', 'We Are Goth' ],
    'Artist name cartesian product correct off cursor',
  );

  is_deeply (
    $rs_2nd_track->all_hri,
    [
      {
        artist => { cdtitle => "Caterwaulin' Blues", name => "Caterwauler McCrae" },
        title => "Howlin"
      },
      {
        artist => { cdtitle => "Forkful of bees", name => "Caterwauler McCrae" },
        title => "Stripy"
      },
      {
        artist => { cdtitle => "Spoonful of bees", name => "Caterwauler McCrae" },
        title => "Apiary"
      },
      {
        artist => { cdtitle => "Generic Manufactured Singles", name => "Random Boy Band" },
        title => "Boring Song"
      },
      {
        artist => { cdtitle => "Come Be Depressed With Us", name => "We Are Goth" },
        title => "Under The Weather"
      }
    ],
    'HRI with invalid inflate map works'
  );

  throws_ok
    { $rs_2nd_track->next }
    qr!\QInflation into non-existent relationship 'artist' of 'Track' requested, check the inflation specification (columns/as) ending in '...artist.name'!,
    'Correct exception on illegal ::Row inflation attempt'
  ;

  # make sure has_many column redirection does not do weird stuff when collapse is requested
  for my $pref_args (
    { prefetch => 'cds'},
    { collapse => 1 }
  ) {
    for my $col_and_join_args (
      { '+columns' => { 'cd_title' => 'cds_2.title' }, join => [ 'cds', 'cds' ] },
      { '+columns' => { 'cd_title' => 'cds.title' }, join => 'cds' },
      { '+columns' => { 'cd_gr_name' => 'genre.name' }, join => { cds => 'genre' } },
    ) {
      for my $call (qw(next all first)) {

        my $weird_rs = $s->resultset('Artist')->search({}, {
          %$col_and_join_args, %$pref_args,
        });

        throws_ok
          { $weird_rs->$call }
          qr/\QResult collapse not possible - selection from a has_many source redirected to the main object/
        for (1,2);
      }
    }
  }

  done_testing;
};

# WHY: a result set whose only selected column is NULL must still produce row objects.
subtest 'nulls_only' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();


  my $cd_rs = $schema->resultset('CD')->search ({ genreid => undef }, { columns => [ 'genreid' ]} );
  my $count = $cd_rs->count;
  cmp_ok ( $count, '>', 1, 'several CDs with no genre');

  my @objects = $cd_rs->all;
  is (scalar @objects, $count, 'Correct amount of objects without limit');
  isa_ok ($_, 'DBIO::Test::CD') for @objects;

  is_deeply (
    [ map { values %{{$_->get_columns}} } (@objects) ],
    [ (undef) x $count ],
    'All values are indeed undef'
  );


  isa_ok ($cd_rs->search ({}, { rows => 1 })->single, 'DBIO::Test::CD');

  done_testing;
};

done_testing;

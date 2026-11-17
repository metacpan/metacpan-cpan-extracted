use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;

# Each subtest was a file of its own; every one builds its own schema.

# WHY: copy of a row carrying an extra selected column must not trip over that column.
subtest 'copy_with_extra_selection' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $cd = $schema->resultset('CD')->search({}, {
    '+columns' => { avg_year => $schema->resultset('CD')->get_column('year')->func_rs('avg')->as_query },
    order_by => 'cdid',
  })->next;

  my $ccd = $cd->copy({ cdid => 5_000_000, artist => 2 });

  cmp_ok(
    $ccd->id,
    '!=',
    $cd->id,
    'IDs differ'
  );

  is(
    $ccd->title,
    $cd->title,
    'Title same on copied object',
  );

  done_testing;
};

# WHY: find_related on a has_many must use the foreign key condition only once.
subtest 'find_one_has_many' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  $schema->resultset('Artist')->delete({ all => 1 });
  $schema->resultset('CD')->delete({ all => 1 });

  my $artist  = $schema->resultset("Artist")->create({ artistid => 21, name => 'Michael Jackson', rank => 20 });
  my $cd = $artist->create_related('cds', { year => 1975, title => 'Compilation from 1975' });

  $schema->is_executed_sql_bind(sub {
    my $find_cd = $artist->find_related('cds',{title => 'Compilation from 1975'});
  }, [
    [
      ' SELECT "me"."cdid", "me"."artist", "me"."title", "me"."year", "me"."genreid", "me"."single_track"
          FROM cd "me"
        WHERE "me"."artist" = ? AND "me"."title" = ?
        ORDER BY "year" ASC
      ',
      [ { dbic_colname => "me.artist", sqlt_datatype => "integer" }
        => 21 ],
      [ { dbic_colname => "me.title",  sqlt_datatype => "varchar", sqlt_size => 100 }
        => "Compilation from 1975" ],
    ]
  ], 'find_related only uses foreign key condition once' );

  done_testing;
};

# WHY: a row of a table without primary key must refuse update and delete.
subtest 'pkless' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $rs = $schema->resultset('NoPrimaryKey');

  my $row = $rs->create ({ foo => 1, bar => 1, baz => 1 });

  lives_ok (sub {
    $row->foo (2);
  }, 'Set on pkless object works');

  is ($row->foo, 2, 'Column updated in-object');

  dies_ok (sub {
    $row->update ({baz => 3});
  }, 'update() fails on pk-less object');

  is ($row->foo, 2, 'Column not updated by failed update()');

  dies_ok (sub {
    $row->delete;
  }, 'delete() fails on pk-less object');

  done_testing;
};

# WHY: changing an extra selected column must be tracked as a column change.
subtest 'set_extra_column' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $rs_with_avg = $schema->resultset('CD')->search({}, {
    '+columns' => { avg_year => $schema->resultset('CD')->get_column('year')->func_rs('avg')->as_query },
    order_by => 'cdid',
  });

  for my $in_storage (1, 0) {
    my $cd = $rs_with_avg->first;

    ok ! $cd->is_column_changed('avg_year'), 'no changes';

    $cd->in_storage($in_storage);

    ok ! $cd->is_column_changed('avg_year'), 'still no changes';

    $cd->set_column( avg_year => 42 );
    $cd->set_column( avg_year => 69 );

    ok $cd->is_column_changed('avg_year'), 'changed';
    is $cd->get_column('avg_year'), 69, 'correct value'
  }

  done_testing;
};

done_testing;

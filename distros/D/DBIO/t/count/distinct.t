use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# make sure distinct+func works
{
  my $rs = $schema->resultset('Artist')->search(
    {},
    {
      join => 'cds',
      distinct => 1,
      '+select' => [ { count => 'cds.cdid', -as => 'amount_of_cds' } ],
      '+as' => [qw/num_cds/],
      order_by => { -desc => 'amount_of_cds' },
    }
  );

  is_same_sql_bind (
    $rs->as_query,
    '(
      SELECT me.artistid, me.name, me.rank, me.charfield, COUNT( cds.cdid ) AS amount_of_cds
        FROM artist me LEFT JOIN cd cds ON cds.artist = me.artistid
      GROUP BY me.artistid, me.name, me.rank, me.charfield
      ORDER BY amount_of_cds DESC
    )',
    [],
  );
}

# and check distinct has_many join count
{
  my $rs = $schema->resultset('Artist')->search(
    { 'cds.title' => { '!=', 'fooooo' } },
    {
      join => 'cds',
      distinct => 1,
      '+select' => [ { count => 'cds.cdid', -as => 'amount_of_cds' } ],
      '+as' => [qw/num_cds/],
      order_by => { -desc => 'amount_of_cds' },
    }
  );

  is_same_sql_bind (
    $rs->as_query,
    '(
      SELECT me.artistid, me.name, me.rank, me.charfield, COUNT( cds.cdid ) AS amount_of_cds
        FROM artist me
        LEFT JOIN cd cds
          ON cds.artist = me.artistid
      WHERE cds.title != ?
      GROUP BY me.artistid, me.name, me.rank, me.charfield
      ORDER BY amount_of_cds DESC
    )',
    [
      [{
        sqlt_datatype => 'varchar',
        dbic_colname => 'cds.title',
        sqlt_size => 100,
      } => 'fooooo' ],
    ],
  );

  is_same_sql_bind (
    $rs->count_rs->as_query,
    '(
      SELECT COUNT( * )
        FROM (
          SELECT me.artistid, me.name, me.rank, me.charfield
            FROM artist me
            LEFT JOIN cd cds
              ON cds.artist = me.artistid
          WHERE cds.title != ?
          GROUP BY me.artistid, me.name, me.rank, me.charfield
        ) me
    )',
    [
      [{
        sqlt_datatype => 'varchar',
        dbic_colname => 'cds.title',
        sqlt_size => 100,
      } => 'fooooo' ],
    ],
  );
}

throws_ok(
  sub { my $row = $schema->resultset('Tag')->search({}, { select => { distinct => [qw/tag cd/] } })->first },
  qr/\Qselect => { distinct => ... } syntax is not supported for multiple columns/,
  'throw on unsupported syntax'
);

done_testing;

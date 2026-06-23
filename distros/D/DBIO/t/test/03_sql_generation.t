use strict;
use warnings;

use Test::More;
use DBIO::Test ':DiffSQL';

my $schema = DBIO::Test->init_schema;

# Simple SELECT
{
  my $rs = $schema->resultset('Artist')->search({ name => 'foo' });
  my $q = ${$rs->as_query};

  is_same_sql_bind(
    $q->[0], [ @{$q}[1..$#$q] ],
    '(SELECT me.artistid, me.name, me.rank, me.charfield FROM artist me WHERE name = ?)',
    [[ { sqlt_datatype => 'varchar', dbic_colname => 'name', sqlt_size => 100 } => 'foo' ]],
    'simple WHERE generates correct SQL'
  );
}

# SELECT with specific columns
{
  my $rs = $schema->resultset('Artist')->search(undef, {
    columns => [qw(artistid name)],
  });
  my $q = ${$rs->as_query};

  is_same_sql(
    $q->[0],
    '(SELECT me.artistid, me.name FROM artist me)',
    'column restriction works'
  );
}

# JOIN
{
  my $rs = $schema->resultset('CD')->search(
    { 'artist.name' => 'bar' },
    { join => 'artist', columns => [qw(cdid title)] },
  );
  my $q = ${$rs->as_query};

  is_same_sql(
    $q->[0],
    '(SELECT me.cdid, me.title FROM cd me JOIN artist artist ON artist.artistid = me.artist WHERE artist.name = ?)',
    'join generates correct SQL'
  );
}

# Subquery in WHERE
{
  my $inner = $schema->resultset('Artist')
    ->search({ rank => 1 })
    ->get_column('artistid');

  my $rs = $schema->resultset('CD')->search({
    artist => { -in => $inner->as_query },
  });

  my $q = ${$rs->as_query};
  like $q->[0], qr/WHERE.*artist IN.*SELECT/i, 'subquery in WHERE clause';
}

# ORDER BY
{
  my $rs = $schema->resultset('Artist')->search(undef, {
    order_by => { -desc => 'name' },
  });
  my $q = ${$rs->as_query};

  is_same_sql(
    $q->[0],
    '(SELECT me.artistid, me.name, me.rank, me.charfield FROM artist me ORDER BY name DESC)',
    'ORDER BY works'
  );
}

# GROUP BY with HAVING
{
  my $rs = $schema->resultset('CD')->search(undef, {
    columns  => ['artist'],
    '+select' => [{ count => 'cdid', -as => 'cd_count' }],
    '+as'     => ['cd_count'],
    group_by  => ['artist'],
    having    => \['count(cdid) > ?', 1],
  });
  my $q = ${$rs->as_query};

  like $q->[0], qr/GROUP BY/i, 'GROUP BY present';
  like $q->[0], qr/HAVING/i, 'HAVING present';
}

# Prefetch generates JOIN (LEFT JOIN for optional rels)
{
  my $rs = $schema->resultset('CD')->search(undef, {
    prefetch => 'tracks',
  });
  my $q = ${$rs->as_query};

  like $q->[0], qr/LEFT JOIN/i, 'prefetch on has_many generates LEFT JOIN';
}

# COUNT
{
  my $rs = $schema->resultset('Artist')->search({ rank => 13 });
  my $count_q = ${$rs->count_rs->as_query};

  is_same_sql(
    $count_q->[0],
    '(SELECT COUNT(*) FROM artist me WHERE rank = ?)',
    'count generates correct SQL'
  );
}

done_testing;

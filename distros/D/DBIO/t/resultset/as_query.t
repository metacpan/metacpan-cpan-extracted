use strict;
use warnings;

use Test::More;

use DBIO::Test ':DiffSQL';

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $art_rs = $schema->resultset('Artist');
my $cdrs = $schema->resultset('CD');

{
  is_same_sql_bind(
    $art_rs->as_query,
    "(SELECT me.artistid, me.name, me.rank, me.charfield FROM artist me)", [],
  );
}

$art_rs = $art_rs->search({ name => 'Billy Joel' });

my $name_resolved_bind = [
  { sqlt_datatype => 'varchar', sqlt_size  => 100, dbic_colname => 'name' }
    => 'Billy Joel'
];

{
  is_same_sql_bind(
    $art_rs->as_query,
    "(SELECT me.artistid, me.name, me.rank, me.charfield FROM artist me WHERE ( name = ? ))",
    [ $name_resolved_bind ],
  );
}

$art_rs = $art_rs->search({ rank => 2 });

my $rank_resolved_bind = [
  { sqlt_datatype => 'integer', dbic_colname => 'rank' }
    => 2
];

{
  is_same_sql_bind(
    $art_rs->as_query,
    "(SELECT me.artistid, me.name, me.rank, me.charfield FROM artist me WHERE name = ? AND rank = ? )",
    [ $name_resolved_bind, $rank_resolved_bind ],
  );
}

my $rscol = $art_rs->get_column( 'charfield' );

{
  is_same_sql_bind(
    $rscol->as_query,
    "(SELECT me.charfield FROM artist me WHERE name = ? AND rank = ? )",
    [ $name_resolved_bind, $rank_resolved_bind ],
  );
}

{
  my $rs = $schema->resultset("CD")->search(
    { 'artist.name' => 'Caterwauler McCrae' },
    { join => [qw/artist/]}
  );
  my $subsel_rs = $schema->resultset("CD")->search( { cdid => { IN => $rs->get_column('cdid')->as_query } } );

  # Just verify the SQL is generated correctly (no real DB)
  is_same_sql_bind(
    $subsel_rs->as_query,
    "(SELECT me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track
       FROM cd me
       WHERE cdid IN (
         SELECT me.cdid FROM cd me JOIN artist artist ON artist.artistid = me.artist WHERE artist.name = ?
       )
    )",
    [ [{ sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'artist.name' }
        => 'Caterwauler McCrae'] ],
  );
}


is_same_sql_bind($schema->resultset('Artist')->search({
   rank => 1,
}, {
   from => $schema->resultset('Artist')->search({ 'name' => 'frew'})->as_query,
})->as_query,
   '(SELECT me.artistid, me.name, me.rank, me.charfield FROM (
     SELECT me.artistid, me.name, me.rank, me.charfield FROM
       artist me
       WHERE (
         ( name = ? )
       )
     ) WHERE (
       ( rank = ? )
     )
   )',
   [
      [{ dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 }, 'frew'],
      [{ dbic_colname => 'rank' }, 1],
   ],
   'from => ...->as_query works'
);

done_testing;

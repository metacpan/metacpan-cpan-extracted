use strict;
use warnings;

use SQL::Abstract::Test import => [qw/is_same_sql_bind/];
use DBI;
use DBIx::DataModel;
use Test::More;


# create a database of Bach's descendents
my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
  RaiseError => 1,
  AutoCommit => 1,
  sqlite_allow_multiple_statements => 1,
});
$dbh->do(q{
  CREATE TABLE family(name TEXT PRIMARY KEY, mom, dad, born, died);

  -- source : http://www.classichistory.net/archives/bach-family-tree
  INSERT INTO family VALUES 
    ('Johann Sebastian',         'Maria Elisabeth',   'Johann Ambrosius',       1685, 1750),
    ('Maria Barbara',            NULL,                NULL,                     1684, 1720),
    ('Catharina Dorothea',       'Maria Barbara',     'Johann Sebastian',       1708, 1774),
    ('Wilhelm Friedmann',        'Maria Barbara',     'Johann Sebastian',       1710, 1784),
    ('Carl Philipp Emanuel',     'Maria Barbara',     'Johann Sebastian',       1714, 1788),
    ('J. Gottfried Bernhard',    'Maria Barbara',     'Johann Sebastian',       1715, 1739),
    ('Friederica Sophie',        NULL,                'Wilhelm Friedmann',      1757, 1801),
    ('Johann August',            NULL,                'Carl Philipp Emanuel',   1745, 1789),
    ('J. Sebastian (J. Samuel)', NULL,                'Carl Philipp Emanuel',   1748, 1778),
    ('Maria Magdalena',          NULL,                NULL,                     1701, 1760),
    ('Gottfried Heinrich',       'Maria Magdalena',   'Johann Sebastian',       1724, 1763),
    ('Elisabeth Juliane',        'Maria Magdalena',   'Johann Sebastian',       1726, 1781),
    ('J. Christoph Friedrich',   'Maria Magdalena',   'Johann Sebastian',       1732, 1795),
    ('Johann Christian',         'Maria Magdalena',   'Johann Sebastian',       1735, 1782),
    ('Johann Caroline',          'Maria Magdalena',   'Johann Sebastian',       1737, 1781),
    ('Regine Susanna',           'Maria Magdalena',   'Johann Sebastian',       1742, 1809),
    ('Augusta Magdalena',        'Elisabeth Juliane', NULL,                     1751, 1809),
    ('Juliane Wilhelmine',       'Elisabeth Juliane', NULL,                     1754, 1815),
    ('Anna Philippine',          NULL,                'J. Christoph Friedrich', 1755, 1804),
    ('Wilhelm Friedrich Ernst',  NULL,                'J. Christoph Friedrich', 1755, 1804)
  ;
});

my @expected_descendants_of_Johann_Sebastian = (
  'Catharina Dorothea (1708-1774)',
  'Wilhelm Friedmann (1710-1784)',
  'Carl Philipp Emanuel (1714-1788)',
  'J. Gottfried Bernhard (1715-1739)',
  'Gottfried Heinrich (1724-1763)',
  'Elisabeth Juliane (1726-1781)',
  'J. Christoph Friedrich (1732-1795)',
  'Johann Christian (1735-1782)',
  'Johann Caroline (1737-1781)',
  'Regine Susanna (1742-1809)',
  'Johann August (1745-1789)',
  'J. Sebastian (J. Samuel) (1748-1778)',
  'Augusta Magdalena (1751-1809)',
  'Juliane Wilhelmine (1754-1815)',
  'Anna Philippine (1755-1804)',
  'Wilhelm Friedrich Ernst (1755-1804)',
  'Friederica Sophie (1757-1801)',
 );

my @expected_descendants_of_Maria_Barbara = (
  'Catharina Dorothea (1708-1774)',
  'Wilhelm Friedmann (1710-1784)',
  'Carl Philipp Emanuel (1714-1788)',
  'J. Gottfried Bernhard (1715-1739)',
  'Johann August (1745-1789)',
  'J. Sebastian (J. Samuel) (1748-1778)',
  'Friederica Sophie (1757-1801)'
 );




# declare the schema and the 'Family' table
my $schema = DBIx::DataModel->Schema('BACHs')->Table(Family => family => qw/name mom dat born died/);

# connect schema to database
$schema->dbh($dbh);

# use Common Table Expressions (CTE) through subqueries
is_deeply names_and_dates(descendants_through_subquery('Johann Sebastian')), 
          \@expected_descendants_of_Johann_Sebastian,
          "descendants of Johann-Sebastian Bach through subquery";

is_deeply names_and_dates(descendants_through_subquery('Maria Barbara')), 
          \@expected_descendants_of_Maria_Barbara,
          "descendants of Maria Barbara Bach through subquery";


# use Common Table Expressions through joins -- but these are permanent declarations, not suitable for a CTE
$schema
    ->Table(qw/Descendant_of descendant_of name/)
    ->Association([qw/Descendant_of descendants *  name/],
                  [qw/Family        family      1  name/]);


is_deeply names_and_dates(descendants_through_join('Johann Sebastian')), 
          \@expected_descendants_of_Johann_Sebastian,
          "descendants of Johann-Sebastian Bach through join";


is_deeply names_and_dates(descendants_through_join('Maria Barbara')), 
          \@expected_descendants_of_Maria_Barbara,
          "descendants of Maria Barbara Bach through join";


done_testing;





sub names_and_dates {
  my $list = shift;
  return [map {"$_->{name} ($_->{born}-$_->{died})"} @$list];
}

sub descendants_through_subquery {
  my $ancestor = shift;

  return $schema->table('Family')->select(
    -with     => sqla_with_CTE_descendant_of($schema, $ancestor),
    -columns  => [qw/name born died/],
    -where    => {name => {-in => \ ["SELECT name FROM descendant_of"] }},
    -order_by => 'born',
  );
}

sub descendants_through_join {
  my $ancestor = shift;

  return $schema->join(qw/Descendant_of family/)->select(
    -with     => sqla_with_CTE_descendant_of($schema, $ancestor),
    -columns  => [qw/family.name born died/],
    -order_by => 'born',
  );
}

sub sqla_with_CTE_descendant_of {
  my ($schema, $ancestor) = @_;

  return $schema->sql_abstract->with_recursive(
    [ -table     => 'parent_of',
      -columns   => [qw/name parent/],
      -as_select => {-columns => [qw/name mom/],
                     -from    => 'family',
                     -union   => [-columns => [qw/name dad/]]},
     ],
    [ -table     => 'descendant_of',
      -columns   => [qw/name/],
      -as_select => {-columns   => [qw/name/],
                     -from      => 'parent_of',
                     -where     => {parent => $ancestor},
                     -union_all => [-columns => [qw/parent_of.name/],
                                    -from    => [qw/-join parent_of {parent=name} descendant_of/]],
                 },
     ],
    );
}

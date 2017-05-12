#!perl 
use strict;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => 'needs DBD::SQLite for testing' if $@;

plan tests => 11;

use lib 't/lib';

use_ok('DBCDs');

# no where
{ 
  is DBCDs->max('price'),  2500, 'SELECT MAX(price) FROM cds';
  is DBCDs->min('price'),   800, 'SELECT MIN(price) FROM cds';
  is DBCDs->sum('price'), 10000, 'SELECT SUM(price) FROM cds';
  is DBCDs->counter('*'),     7, 'SELECT COUNT(*) FROM cds';
}

# where
{
  is DBCDs->max('price', artist => 1), 1200, 'SELECT MAX(price) FROM cds WHERE artist = 1';
  is DBCDs->min('price', artist => 1), 1000, 'SELECT MIN(price) FROM cds WHERE artist = 1';
  is DBCDs->sum('price', artist => 1), 3400, 'SELECT SUM(price) FROM cds WHERE artist = 1';
  is DBCDs->counter('*', artist => 1),    3, 'SELECT COUNT(*) FROM cds WHERE artist = 1';
}

# distinct
{
  is DBCDs->counter('distinct artist'),  5, 'SELECT COUNT( DISTINCT artist ) FROM cds';
  is DBCDs->sum    ('distinct artist'), 15, 'SELECT SUM( DISTINCT artist ) FROM cds';
}

__END__

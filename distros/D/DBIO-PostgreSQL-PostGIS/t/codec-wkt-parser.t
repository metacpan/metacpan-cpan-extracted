use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser;
my $p = 'DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser';

# POINT
{
  my $r = $p->parse('POINT(13.4 52.5)');
  is $r->{type},              'point',  'POINT type';
  is $r->{coords}[0],         13.4,     'POINT x';
  is $r->{coords}[1],         52.5,     'POINT y';
  ok !$r->{has_z},                      'POINT no Z';
}

# POINT Z
{
  my $r = $p->parse('POINT Z(13.4 52.5 10)');
  is $r->{type},   'point',  'POINT Z type';
  is $r->{coords}[2], 10,   'POINT Z z-coord';
  ok $r->{has_z},           'has_z true';
}

# LINESTRING
{
  my $r = $p->parse('LINESTRING(0 0, 1 1, 2 2)');
  is $r->{type},            'linestring', 'LINESTRING type';
  is scalar @{$r->{coords}}, 3,           '3 points';
  is $r->{coords}[1][0],    1,            'second x';
}

# POLYGON
{
  my $r = $p->parse('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))');
  is $r->{type},             'polygon', 'POLYGON type';
  is scalar @{$r->{coords}}, 1,         '1 ring';
  is scalar @{$r->{coords}[0]}, 5,      '5 points in ring';
}

# POLYGON with hole
{
  my $r = $p->parse('POLYGON((0 0,10 0,10 10,0 10,0 0),(1 1,2 1,2 2,1 2,1 1))');
  is scalar @{$r->{coords}}, 2, 'POLYGON 2 rings (outer + hole)';
}

# EMPTY
{
  my $r = $p->parse('POINT EMPTY');
  ok $r->{is_empty}, 'POINT EMPTY flagged';
}

# MULTIPOINT
{
  my $r = $p->parse('MULTIPOINT((0 0),(1 1))');
  is $r->{type},             'multipoint', 'MULTIPOINT type';
  is scalar @{$r->{coords}}, 2,            '2 points';
}

done_testing;

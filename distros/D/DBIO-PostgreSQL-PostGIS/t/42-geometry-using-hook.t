use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Extension;

# karr k28 / k31: what the extension answers for a geometry column whose type
# changes (verdict, phase 3 of the extension protocol, ADR 0066).
#
# The maintainer's decision (2026-10-14): the same geometry type under another
# SRID is converted -- ST_Transform(column, srid), the coordinates are
# recomputed, not relabelled; every other change between spatial types (another
# geometry type, geometry <-> geography) is refused, naming the column. A column
# that is no spatial one is none of this extension's business: undef.
#
# The live counterpart is t/43-geometry-using-hook-live.t.

my $E = 'DBIO::PostgreSQL::PostGIS::Extension';

sub col {
  my ($base, $type, $srid) = @_;
  my $mod = defined $type ? "($type,$srid)" : '';
  return {
    column_name => 'geom', data_type => "public.$base$mod", not_null => 0,
    base_type => $base,
    (defined $type ? (geometry_type => lc $type, srid => $srid) : ()),
  };
}

sub verdict {
  my ($from, $to) = @_;
  return $E->verdict({
    kind => 'column_type', table => 'ns.t', column_name => 'geom',
    old_info => $from, new_info => $to,
  }, {});
}

is_deeply verdict(col('geometry', 'Point', 4326), col('geometry', 'Point', 3857)),
  { using => 'ST_Transform(geom, 3857)' },
  'same type, other SRID: converted with ST_Transform';

is_deeply verdict(col('geography', 'Point', 4326), col('geography', 'Point', 4269)),
  { using => 'ST_Transform(geom::geometry, 4269)::geography' },
  'geography, other SRID: through geometry and back';

{
  my $c = { %{ col('geometry', 'Point', 3857) }, column_name => 'Geo Col' };
  my $answer = $E->verdict({ kind => 'column_type', table => 'ns.t',
    column_name => 'Geo Col', old_info => { %$c, srid => 4326 }, new_info => $c }, {});
  is $answer->{using}, 'ST_Transform("Geo Col", 3857)',
    'a column name that needs quoting is quoted in the expression';
}

for my $case (
  [ 'another geometry type',
    col('geometry', 'Point', 4326), col('geometry', 'LineString', 4326),
    qr/ns\.t\.geom.*geometry point.*geometry linestring/ ],
  [ 'another type and another SRID',
    col('geometry', 'Point', 4326), col('geometry', 'LineString', 3857),
    qr/ns\.t\.geom/ ],
  [ 'geometry to geography',
    col('geometry', 'Point', 4326), col('geography', 'Point', 4326),
    qr/ns\.t\.geom.*geometry point.*geography point/ ],
  [ 'geography to geometry',
    col('geography', 'Point', 4326), col('geometry', 'Point', 4326),
    qr/ns\.t\.geom/ ],
) {
  my ($label, $from, $to, $re) = @$case;
  my $answer = verdict($from, $to);
  is_deeply [ keys %{ $answer || {} } ], ['refuse'], "$label: refused";
  like $answer && $answer->{refuse}, $re, "$label: the column and both types are named";
}

is verdict(col('geometry', 'Point', 4326), col('geometry', 'Point', 4326)), undef,
  'an unchanged type is not asked about: undef';

# not spatial: the extension says nothing
is verdict({ column_name => 'geom', data_type => 'text' },
           { column_name => 'geom', data_type => 'integer' }),
  undef, 'a column that is no spatial one: undef';

is verdict(col('geometry', 'Point', 4326), { column_name => 'geom', data_type => 'text' }),
  undef, 'spatial to a non-spatial type: not this extension\'s decision';

is verdict({ column_name => 'geom', data_type => 'public.geometry', base_type => 'geometry' },
           col('geometry', 'Point', 4326)),
  undef, 'from an unconstrained geometry: no conversion is guessed';

is verdict(col('geometry', 'Point', 4326),
           { column_name => 'geom', data_type => 'public.geometry', base_type => 'geometry' }),
  undef, 'to an unconstrained geometry: no conversion is guessed';

is $E->verdict({ kind => 'column_nullable', table => 'ns.t', column_name => 'geom' }, {}),
  undef, 'a change that is no type change is none of its business';

done_testing;

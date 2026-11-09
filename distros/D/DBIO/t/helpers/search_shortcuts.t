use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';

# The condition shortcuts null/not_null/like/not_like (folded in from
# DBIx::Class::Helper::ResultSet::Shortcut::Search::* on top of
# ::Search::Base). Fake storage only.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $artists = $schema->resultset('Artist');

# Both 'cd' and 'track' have a 'title' column, so an unqualified "title" in
# the WHERE clause is genuinely ambiguous once the join is in place - which is
# exactly what the '.' prefix exists to avoid.
my $cds = $schema->resultset('CD')->search(undef, { join => 'tracks' });

my $cd_select = '"me"."cdid", "me"."artist", "me"."title", "me"."year",'
  . ' "me"."genreid", "me"."single_track"';
my $cd_from = 'FROM cd "me" LEFT JOIN "track" "tracks" ON "tracks"."cd" = "me"."cdid"';

sub cd_sql {
  my ($where) = @_;
  return "(SELECT $cd_select $cd_from WHERE ( $where ))";
}

my $title_bind = { dbic_colname => 'me.title', sqlt_datatype => 'varchar', sqlt_size => 100 };

# --- A) the '.' prefix qualifies with the source alias ---------------
#
# _helper_meify was lost when the four methods were folded in one by one
# without their shared base class. The leading '.' was then simply part of the
# column name and vanished in quoting, so '.title' and 'title' produced the
# identical, ambiguous predicate.

is_same_sql_bind(
  $cds->null('.title')->as_query,
  cd_sql('"me"."title" IS NULL'),
  [],
  q{null('.title') qualifies with the current source alias},
);

is_same_sql_bind(
  $cds->null('title')->as_query,
  cd_sql('"title" IS NULL'),
  [],
  q{null('title') stays unqualified - the prefix is opt-in},
);

is_same_sql_bind(
  $cds->not_null('.title')->as_query,
  cd_sql('"me"."title" IS NOT NULL'),
  [],
  q{not_null('.title') qualifies too},
);

is_same_sql_bind(
  $cds->like('.title', '%x%')->as_query,
  cd_sql('"me"."title" LIKE ?'),
  [ [ $title_bind => '%x%' ] ],
  q{like('.title', ...) qualifies, and the bind resolves to the me. column},
);

is_same_sql_bind(
  $cds->not_like('.title', '%x%')->as_query,
  cd_sql('"me"."title" NOT LIKE ?'),
  [ [ $title_bind => '%x%' ] ],
  q{not_like('.title', ...) qualifies},
);

# An already qualified column must not be touched - only a *leading* dot is
# the marker.
is_same_sql_bind(
  $cds->null('tracks.title')->as_query,
  cd_sql('"tracks"."title" IS NULL'),
  [],
  'an explicitly qualified column is left alone',
);

# The alias the prefix expands to is the ResultSet's own, not a hardcoded 'me'.
is_same_sql_bind(
  $artists->search(undef, { alias => 'artist' })->null('.name')->as_query,
  '(SELECT "artist"."artistid", "artist"."name", "artist"."rank", "artist"."charfield"'
    . ' FROM "artist" "artist" WHERE ( "artist"."name" IS NULL ))',
  [],
  'the prefix expands to current_source_alias, not to a literal "me"',
);

# --- B) argument shapes ----------------------------------------------

is_same_sql_bind(
  $artists->null(['name', 'rank'])->as_query,
  '(SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"'
    . ' FROM "artist" "me" WHERE ( "name" IS NULL AND "rank" IS NULL ))',
  [],
  'null() takes an arrayref of columns',
);

is_same_sql_bind(
  $artists->null('name', 'rank')->as_query,
  $artists->null(['name', 'rank'])->as_query,
  'null() takes a flat list of columns as well',
);

is_same_sql_bind(
  $artists->null(['.name', 'rank'])->as_query,
  '(SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"'
    . ' FROM "artist" "me" WHERE ( "me"."name" IS NULL AND "rank" IS NULL ))',
  [],
  'the prefix is applied per column inside an arrayref',
);

is_same_sql_bind(
  $artists->not_null(['name', 'rank'])->as_query,
  '(SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"'
    . ' FROM "artist" "me" WHERE ( "name" IS NOT NULL AND "rank" IS NOT NULL ))',
  [],
  'not_null() takes an arrayref of columns',
);

is_same_sql_bind(
  $cds->like(['.title', 'tracks.title'], '%x%')->as_query,
  cd_sql('"me"."title" LIKE ? AND "tracks"."title" LIKE ?'),
  [
    [ $title_bind => '%x%' ],
    [ { dbic_colname => 'tracks.title', sqlt_datatype => 'varchar', sqlt_size => 100 } => '%x%' ],
  ],
  'like() applies the same pattern to every column of an arrayref',
);

is_same_sql_bind(
  $cds->not_like(['.title'], '%x%')->as_query,
  cd_sql('"me"."title" NOT LIKE ?'),
  [ [ $title_bind => '%x%' ] ],
  'not_like() takes an arrayref too',
);

# No columns at all must be a no-op, not a bogus empty predicate.
is_same_sql_bind(
  $artists->null([])->as_query,
  $artists->as_query,
  'null() with no columns changes nothing',
);

# --- C) bad column arguments throw a typed exception -----------------
#
# Anything that is a ref but not an ARRAY ref used to reach the deref and die
# with a bare "Not an ARRAY reference at .../ResultSet.pm line N".

throws_ok { $artists->like(\'name', '%x%') } 'DBIO::Exception',
  'like() with a scalar ref column throws a DBIO exception';
throws_ok { $artists->like(\'name', '%x%') } qr/ARRAY reference of column names/,
  'like() says what it wanted instead of "Not an ARRAY reference"';

throws_ok { $artists->like({ name => 1 }, '%x%') } 'DBIO::Exception',
  'like() with a hashref column throws';

throws_ok { $artists->not_like(\'name', '%x%') } 'DBIO::Exception',
  'not_like() with a scalar ref column throws a DBIO exception';
throws_ok { $artists->not_like(\'name', '%x%') } qr/ARRAY reference of column names/,
  'not_like() carries the same message';

done_testing;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;

# Test for virtual columns fix: when a result object has extra columns
# (e.g. from +select/+as), resolve_relationship_condition should filter
# them out and not pass garbage to downstream code.
# Backported from Perl5/DBIx-Class PR #115.

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

# Get a CD with an extra virtual column via +select/+as
my $cd_with_extra = $schema->resultset('CD')->search(
  { 'me.cdid' => 1 },
  {
    join     => 'tracks',
    distinct => 1,
    '+select' => { count => 'tracks.trackid' },
    '+as'     => 'track_count',
  },
)->single;

ok( $cd_with_extra, 'Got a CD result object' );

# Verify the virtual column is present in get_columns
my %cols = $cd_with_extra->get_columns;
ok( exists $cols{track_count}, 'Virtual column track_count exists in get_columns' );

# Test set_from_related with this object that has extra columns.
# The fix filters get_columns output to only actual source columns
# when resolving relationship conditions.
my $track = $schema->resultset('Track')->create({
  cd       => 1,
  position => 99,
  title    => 'Virtual Column Test Track',
});

lives_ok {
  $track->set_from_related( cd => $cd_with_extra );
} 'set_from_related works with an object that has virtual columns';

is( $track->get_column('cd'), $cd_with_extra->cdid,
  'FK column was correctly set from related object with virtual columns' );

# Test the internal _resolve_relationship_condition directly: passing
# a hashref with extra keys as foreign_values should be rejected by
# the validation. This is the path that the fix protects against when
# callers convert objects to hashrefs before calling r_r_c.
my $rsrc = $schema->source('Track');
throws_ok {
  $rsrc->_resolve_relationship_condition(
    rel_name       => 'cd',
    foreign_alias  => 'cd',
    self_alias     => 'me',
    foreign_values => {
      cdid   => 1,
      artist => 1,
      title  => 'Spoonful of bees',
      year   => 1999,
      genreid => 1,
      single_track => undef,
      # This is the virtual column that should not be here
      track_count  => 3,
    },
  );
} qr/is not a column on related source/,
  'Passing a hashref with extra keys as foreign_values is correctly rejected';

# But when passing a blessed object (which the fix handles by filtering),
# the virtual columns are silently stripped
lives_ok {
  $rsrc->_resolve_relationship_condition(
    rel_name       => 'cd',
    foreign_alias  => 'cd',
    self_alias     => 'me',
    foreign_values => $cd_with_extra,
  );
} '_resolve_relationship_condition correctly filters virtual columns from objects';

# Also test that find() works when passing an object with virtual columns
# through a relationship
my $artist_with_extra = $schema->resultset('Artist')->search(
  { 'me.artistid' => 1 },
  {
    '+select' => [ \'42' ],
    '+as'     => [ 'the_answer' ],
  },
)->single;

ok( $artist_with_extra, 'Got an Artist with virtual column' );
ok( exists +{ $artist_with_extra->get_columns }->{the_answer},
  'Virtual column the_answer exists on Artist object' );

lives_ok {
  $schema->resultset('CD')->find({ artist => $artist_with_extra, title => 'Spoonful of bees' });
} 'find() with foreign object containing virtual columns works';

done_testing;

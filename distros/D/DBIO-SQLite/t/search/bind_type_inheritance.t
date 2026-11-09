use strict;
use warnings;

use Test::More;
use DBI ();
use DBIO::SQLite::Test;

# karr k61.
#
# DBD::SQLite keeps the type a placeholder was last bound with until it is
# given another one, and no type code puts it back to "untyped". Statements
# come out of DBI's cache, keyed by their SQL text. A bind that carries no
# attribute -- a column of a non-integer type, a value taken back from the
# integer hint -- therefore does not get the DBD default but the type of the
# call before it that shared the SQL text: '01234' went out as INTEGER 1234
# behind a literal 99999, and the row was not found, without an error.
#
# The storage keys the cached handle by the bind types as well, so a handle
# is shared only between calls that bind alike. This test holds that: it goes
# red when the cache key falls back to the SQL text alone.

# the pair of the card: a literal integer and a column bind that render the
# same SQL text
{
  my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );
  my $artists = $schema->resultset('Artist');

  # artist.name is a varchar: TEXT affinity
  $artists->create({ name => '01234', rank => 1 });
  $artists->create({ name => '99999', rank => 2 });

  my $integer_first = sub { $artists->search(\[ q{"me"."name" = ?}, 99999 ])->count };
  my $column_bind   = sub { $artists->search({ 'me.name' => '01234' })->count };

  is $integer_first->(), 1, "literal integer binds";
  is $column_bind->(), 1, "column bind '01234' after it finds the row";

  is $column_bind->(), 1, "... and again";
  is $integer_first->(), 1, "... literal integer after the column bind";
  is $column_bind->(), 1, "... column bind once more";

  for (1 .. 3) {
    is $integer_first->(), 1, "alternating, literal integer";
    is $column_bind->(), 1, "alternating, column bind";
  }

  # the other order, on a statement that has not run yet: fetching the rows
  # is another SQL text than counting them. The column bind comes first and
  # leaves the placeholder untyped, the literal types it, and the column bind
  # after that must not find it typed.
  my $rows_by_column  = sub { scalar @{[ $artists->search({ 'me.name' => '01234' })->all ]} };
  my $rows_by_integer = sub { scalar @{[ $artists->search(\[ q{"me"."name" = ?}, 99999 ])->all ]} };

  is $rows_by_column->(), 1, "fresh statement: column bind first";
  is $rows_by_integer->(), 1, "... literal integer after it";
  is $rows_by_column->(), 1, "... and the column bind after that still finds the row";
}

# sqlite_see_if_its_a_number keeps working for a bind that has no attribute:
# it is the property the alternatives to this fix would have given up. (The
# pair above says nothing under the switch: DBD::SQLite then guesses '01234'
# to be the integer 1234 already when the row is written.)
{
  my $schema = DBIO::SQLite::Test->init_schema(
    dsn => 'dbi:SQLite::memory:',
    sqlite_see_if_its_a_number => 1,
  );
  my $artists = $schema->resultset('Artist');
  $artists->create({ name => 'x', rank => 5 });

  # untyped, non-integer-column bind of a number-looking string: DBD::SQLite
  # guesses, and binds 1.5 as REAL
  my $typeof = sub {
    my ($t) = $artists->search({ name => 'x' }, {
      columns => [ { t => \[ 'typeof(?)', [ { dbd_attrs => undef } => $_[0] ] ] } ],
    })->cursor->next;
    $t;
  };

  is $typeof->(1.5), 'real', 'see_if_its_a_number: an untyped 1.5 is guessed as a number';

  # a typed call on the same SQL text in between must not leave its mark
  $artists->search({ name => 'x' }, {
    columns => [ { t => \[ 'typeof(?)', [ { dbd_attrs => DBI::SQL_VARCHAR() } => 1.5 ] ] } ],
  })->cursor->next;

  is $typeof->(1.5), 'real', '... also after the same statement ran with a typed bind';
}

# the integer attribute taken back for a non-integer value
# (_dbi_attrs_for_bind: undef $bindattrs->[$i]) inherits nothing either
{
  my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );
  my $artists = $schema->resultset('Artist');
  $artists->create({ name => 'rank-ish', rank => 7 });

  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };

  # rank is an integer column: bound as integer
  is $artists->search({ 'me.rank' => 7 })->count, 1, 'integer column, integer value';

  # same SQL text, a value that is no integer: the attribute is withdrawn
  # and the bind is what DBD::SQLite makes of a bare string
  my ($t) = $artists->search({ 'me.rank' => 7 }, {
    columns => [ { t => \[ 'typeof(?)', [ rank => ' 5' ] ] } ],
  })->cursor->next;
  is $t, 'text', q{a value that is no integer (' 5') for an integer column is bound as text};

  my ($t2) = $artists->search({ 'me.rank' => 7 }, {
    columns => [ { t => \[ 'typeof(?)', [ rank => 7 ] ] } ],
  })->cursor->next;
  is $t2, 'integer', '... the integer after it as integer';

  my ($t3) = $artists->search({ 'me.rank' => 7 }, {
    columns => [ { t => \[ 'typeof(?)', [ rank => ' 5' ] ] } ],
  })->cursor->next;
  is $t3, 'text', '... and the non-integer after that as text again, not as the integer before it';
}

# without statement caching there is no shared handle to begin with, and the
# path stays as it was
{
  my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );
  $schema->storage->disable_sth_caching(1);
  my $artists = $schema->resultset('Artist');
  $artists->create({ name => '01234', rank => 1 });
  $artists->create({ name => '99999', rank => 2 });

  my $cached = scalar keys %{ $schema->storage->dbh->{CachedKids} || {} };
  $artists->search(\[ q{"me"."name" = ?}, 99999 ])->count;
  is $artists->search({ 'me.name' => '01234' })->count, 1,
    'disable_sth_caching: the column bind finds the row';
  is scalar keys %{ $schema->storage->dbh->{CachedKids} || {} }, $cached,
    '... and the two statements did not go into the statement cache';
}

# populate: execute_for_fetch relies on the types being bound once
{
  my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );
  my $artists = $schema->resultset('Artist');

  # a create with a literal bind for name renders the very SQL text populate
  # does, and binds the 99999 as SQL_INTEGER; populate's name column has no
  # attribute of its own and must not take that over
  $artists->create({ artistid => 100, name => \[ '?', 99999 ], rank => 1 });
  $artists->populate([ [qw(artistid name rank)], [ 101, '01234', 3 ], [ 102, '00123', 4 ] ]);

  is_deeply(
    [ sort map { $_->name } $artists->search({ name => [ '99999', '01234', '00123' ] })->all ],
    [ '00123', '01234', '99999' ],
    'populate keeps the spelling of number-looking strings in a text column',
  );
}

done_testing;

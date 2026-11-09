use strict;
use warnings;

use Test::More;
use DBI ();
use DBIO::SQLite::Test;

# karr k55.
#
# DBD::SQLite binds every parameter as TEXT unless told otherwise, and SQLite
# compares INTEGER against TEXT by storage class whenever no column affinity
# is in play -- so COUNT(x) > ? with a TEXT bind is always false. The storage
# therefore hints a bind as an integer when nothing else says what it is
# (t/search/having_bind.t holds that side).
#
# The hint must stay off every value that is not certainly a number. A string
# that merely looks like one -- a zip code, a phone or article number -- loses
# its spelling the moment it is bound as INTEGER: '01234' reaches SQLite as
# 1234, and the row is not found, without an error and without a warning.
# This test holds that side: which values are hinted, and that a bind which
# states its own type is never second-guessed.

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $artists = $schema->resultset('Artist');

# artist.name is a varchar: TEXT affinity. artist.rank is an integer.
$artists->create({ name => '01234', rank => 1 });
$artists->create({ name => '99999', rank => 2 });

my $bound_as = sub {
  my ($bind) = @_;
  my ($type) = $artists->search({ name => '01234' }, {
    columns => [ { bound_as => \[ 'typeof(?)', $bind ] } ],
  })->cursor->next;
  $type;
};

# --- a numeric-looking string against a TEXT column, literal SQL ---
{
  is $artists->search({ name => '01234' })->count, 1,
    'the column-bound form finds the row (reference)';

  is $artists->search(\[ 'name = ?', '01234' ])->count, 1,
    q{literal SQL: name = ? with '01234' finds the row};

  is $artists->search(\[ 'lower(name) = ?', '01234' ])->count, 1,
    q{literal SQL: lower(name) = ? with '01234' finds the row};
}

# --- a numeric-looking string in a SELECT expression keeps its spelling ---
{
  my ($got) = $artists->search({ name => '01234' }, {
    columns => [ { tagged => \[ '? || name', '007' ] } ],
  })->cursor->next;

  is $got, '00701234', q{'007' in a SELECT expression stays '007'};
}

# --- a non-integer number is not announced to DBD::SQLite as an integer ---
{
  @warnings = ();

  # populate_schema's artists carry the default rank 13; of the two rows
  # above only rank 2 is above 1.5
  my $expected = $artists->search({ rank => { '>=' => 2 } })->count;

  is $artists->search(\[ 'rank > ?', 1.5 ])->count, $expected,
    'literal SQL: rank > ? with 1.5 returns the right rows';

  is_deeply \@warnings, [],
    'binding 1.5 raises no DBD::SQLite datatype mismatch warning';
}

# --- the decision is taken per value, on a statement that is reused ---
#
# Statements are cached, and DBD::SQLite keeps the type a placeholder was
# last bound with until it is given another one. A value that is merely not
# hinted would inherit the integer of the value before it.
{
  is $artists->search(\[ 'name = ?', '99999' ])->count, 1,
    q{name = ? with '99999', a canonical integer};

  is $artists->search(\[ 'name = ?', '01234' ])->count, 1,
    q{... and the same statement with '01234' right after it};

  is $bound_as->(42), 'integer', 'a canonical integer is bound as integer';
  is $bound_as->('042'), 'text', '... a non-canonical one after it, on the same statement, as text';
  is $bound_as->(42), 'integer', '... and the integer after that as integer again';
}

# --- a bind that states its own type is left alone ---
#
# '99999' is an integer in canonical spelling, so without a type of its own
# it is hinted. lower(name) has no affinity that would turn the bound integer
# back into text, which makes the comparison show how the value was bound.
for my $spec (
  [ q{sqlt_datatype => 'varchar'}  => { sqlt_datatype => 'varchar' } ],
  [ q{\'varchar' shorthand}        => \'varchar' ],
  [ q{dbd_attrs => SQL_VARCHAR}    => { dbd_attrs => DBI::SQL_VARCHAR() } ],
) {
  my ($desc, $type) = @$spec;

  # an untyped integer first, each time: the typed bind after it shares its
  # statement, and with it the placeholder that was just bound as integer
  $artists->search(\[ 'lower(name) = ?', 42 ])->count;

  is $artists->search(\[ 'lower(name) = ?', [ $type => '99999' ] ])->count, 1,
    "bind with its own type ($desc) is not rebound as an integer";

  is $bound_as->(42), 'integer', 'an untyped canonical integer is bound as integer';

  is $bound_as->([ $type => '99999' ]), 'text',
    "... and the bind with its own type ($desc) after it as text";
}

# dbd_attrs => undef says "no bind attribute at all", and that is what it
# gets -- so this placeholder is whatever the statement had before. The SQL
# below is used nowhere else in this file: on a statement of its own the
# value is bound the way DBD::SQLite binds by default, as text.
is $artists->search(\[ 'upper(name) = ?', [ { dbd_attrs => undef } => '99999' ] ])->count, 1,
  'bind with dbd_attrs => undef is not given an integer hint';

is $bound_as->([ { dbd_attrs => DBI::SQL_REAL() } => 1.5 ]), 'real',
  'an explicit dbd_attrs on a non-integer value is passed through';

# --- which untyped values are hinted ---
{
  @warnings = ();

  my @table = (
    # only an integer in canonical spelling is certainly a number
    [ 3                       => 'integer' ],
    [ '3'                     => 'integer' ],
    [ 0                       => 'integer' ],
    [ -7                      => 'integer' ],
    [ '-7'                    => 'integer' ],
    [ '99999'                 => 'integer' ],
    [ '1760000000000000000'   => 'integer' ],  # an epoch in nanoseconds
    [ '9223372036854775807'   => 'integer' ],  # the 64 bit range, both ends
    [ '-9223372036854775808'  => 'integer' ],

    # anything a round trip through INTEGER would respell stays as written
    [ '01234'                 => 'text' ],
    [ '007'                   => 'text' ],
    [ '00'                    => 'text' ],
    [ '+5'                    => 'text' ],
    [ '-0'                    => 'text' ],
    [ ' 5'                    => 'text' ],
    [ '5 '                    => 'text' ],
    [ "5\n"                   => 'text' ],
    [ '5.0'                   => 'text' ],
    [ '1e3'                   => 'text' ],
    [ '0x10'                  => 'text' ],

    # non-integers: not hinted at all (see the 1.5 block above)
    [ 1.5                     => 'text' ],
    [ '1.50'                  => 'text' ],

    # a digit string past the 64 bit range is no SQLite INTEGER
    [ '9223372036854775808'   => 'text' ],
    [ '-9223372036854775809'  => 'text' ],
    [ '12345678901234567890'  => 'text' ],
  );

  for (@table) {
    my ($value, $expected) = @$_;
    (my $shown = $value) =~ s/\n/\\n/g;
    is $bound_as->($value), $expected, "untyped bind '$shown' is bound as $expected";
  }

  is_deeply \@warnings, [], 'none of the untyped binds raised a warning';
}

# --- the reason the hint exists stays intact ---
{
  my %attrs = (
    join     => { cds => 'tracks' },
    group_by => [ 'me.artistid', 'me.name' ],
  );

  # Artist 1 has 9 tracks, artists 2 and 3 have 3 each
  is $artists->search(undef, {
    %attrs, having => \[ 'COUNT(tracks.trackid) > ?', 3 ],
  })->count, 1, 'COUNT(x) > ? with the number 3';

  # a count that arrives as a string -- a request parameter, a value read
  # from a file -- is the same canonical integer and must behave the same
  is $artists->search(undef, {
    %attrs, having => \[ 'COUNT(tracks.trackid) > ?', '3' ],
  })->count, 1, q{COUNT(x) > ? with the string '3'};

  # an expression as the bind's column name (what a hash condition on an
  # expression produces) is no column, hence carries no type either
  is $artists->search(undef, {
    %attrs,
    having => \[ 'COUNT(tracks.trackid) > ?', [ 'COUNT(tracks.trackid)' => 3 ] ],
  })->count, 1, 'COUNT(x) > ? with the expression as the bind column name';
}

is_deeply \@warnings, [], 'no warnings over the whole run';

done_testing;

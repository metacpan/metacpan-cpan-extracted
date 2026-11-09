use strict;
use warnings;

use Test::More;
use DBI ();
use DBD::SQLite ();
use DBIO::SQLite::Test;

# karr k63.
#
# DBD::SQLite before 1.37 can not bind an integer that occupies more than 32
# bits. The storage asks for the version once and keeps the answer in
# $DBD::SQLite::__DBIO_CHECK_dbd_can_bind_bigint_values; where it is false,
# such a value must not go out as an integer: it is bound as a string, and a
# warning says so.
#
# Two places decide that a bind is an integer -- a bind that already carries
# an integer attribute (an integer column), and the hint for a bind that says
# nothing about itself (literal SQL, an expression). The second one stated
# SQL_INTEGER for every integer SQLite can hold without looking at the DBD.
# This test holds both, on both sides of the 32 bit limit.
#
# No old DBD::SQLite is needed: the answer is faked. Every case runs on SQL
# text of its own, so none of them shares a cached statement with another and
# the result does not depend on what ran before it. A warning is reported
# once per message (carp_unique), so every case that expects one names a
# column of its own -- with one exception, the single bind without any name.

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );
my $artists = $schema->resultset('Artist');
$artists->create({ name => 'k63', rank => 1 });

my $case = 0;

# how SQLite saw the bind, and what was warned while it was bound
my $bound_as = sub {
  my ($bind) = @_;

  $case++;

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my ($type) = $artists->search({ name => 'k63' }, {
    columns => [ { bound_as => \[ "typeof(?) /* case $case */", $bind ] } ],
  })->cursor->next;

  return ($type, \@warnings);
};

my $too_wide = qr/occupying more than 32 bits/;

# a bind the hint applies to: no datatype, and an expression for a name
my $expression = sub { [ { dbic_colname => "abs(k63_$case)" } => $_[0] ] };

# a bind that carries an integer attribute of its own
my $integer_column = sub { [ { dbic_colname => "k63_$case", sqlt_datatype => 'integer' } => $_[0] ] };

my @beyond = ( 5000000000, -5000000000, 2147483648, -2147483649, '9223372036854775807' );
my @within = ( 0, 42, -42, 2147483647, -2147483648 );

# --- a DBD::SQLite that binds them: nothing is held back ---
SKIP: {
  skip 'this DBD::SQLite is itself older than 1.37', 4
    unless eval { DBD::SQLite->VERSION('1.37'); 1 };

  for my $spec ( [ hint => $expression ], [ 'integer column' => $integer_column ] ) {
    my ($name, $bind) = @$spec;

    my ($type, $warnings) = $bound_as->( $bind->(5000000000) );

    is $type, 'integer', "$name: 5000000000 is bound as integer";
    is_deeply $warnings, [], '... without a warning';
  }
}

# --- a DBD::SQLite that can not ---
{
  local $DBD::SQLite::__DBIO_CHECK_dbd_can_bind_bigint_values = 0;

  for my $spec ( [ hint => $expression ], [ 'integer column' => $integer_column ] ) {
    my ($name, $bind) = @$spec;

    for my $value (@beyond) {
      my ($type, $warnings) = $bound_as->( my $b = $bind->($value) );

      is $type, 'text', "old DBD, $name: $value is not bound as integer";

      is scalar @$warnings, 1, '... and one warning says so'
        or diag explain $warnings;

      like $warnings->[0], $too_wide, '... naming the reason';
      like $warnings->[0], qr/\Q'$b->[0]{dbic_colname}'\E/, '... and the bind';
    }

    for my $value (@within) {
      my ($type, $warnings) = $bound_as->( $bind->($value) );

      is $type, 'integer', "old DBD, $name: $value is bound as integer";
      is_deeply $warnings, [], '... without a warning';
    }
  }

  # the forms a caller actually writes: a value in literal SQL, which has no
  # name at all, and a column of the schema. One each -- the warning for a
  # nameless bind names its position, and is not repeated.
  {
    my ($type, $warnings) = $bound_as->(5000000000);

    is $type, 'text', 'old DBD, nameless bind: 5000000000 is not bound as integer';
    like $warnings->[0], $too_wide, '... and the warning comes';

    ($type, $warnings) = $bound_as->(42);

    is $type, 'integer', 'old DBD, nameless bind: 42 is bound as integer';
    is_deeply $warnings, [], '... without a warning';
  }

  {
    my ($type, $warnings) = $bound_as->([ rank => 5000000000 ]);

    is $type, 'text', 'old DBD, artist.rank: 5000000000 is not bound as integer';
    like $warnings->[0], qr/$too_wide.*'rank'/, '... and the warning names the column';

    ($type, $warnings) = $bound_as->([ rank => 42 ]);

    is $type, 'integer', 'old DBD, artist.rank: 42 is bound as integer';
    is_deeply $warnings, [], '... without a warning';
  }

  # the warning is about an integer that is held back. A bind the hint would
  # not have made an integer anyway is text as before, and nothing is said
  # about it. (Named binds, both: a nameless one would be silent here in any
  # case, its warning has been raised above.)
  for my $spec (
    [ q{a non-canonical '05000000000'} => $expression->('05000000000') ],
    [ q{a bind stating a varchar}      =>
      [ { dbic_colname => 'abs(k63_varchar)', sqlt_datatype => 'varchar' } => 5000000000 ] ],
  ) {
    my ($desc, $bind) = @$spec;

    my ($type, $warnings) = $bound_as->($bind);

    is $type, 'text', "old DBD, $desc is text";
    is_deeply $warnings, [], '... and no integer was held back, so no warning';
  }
}

done_testing;

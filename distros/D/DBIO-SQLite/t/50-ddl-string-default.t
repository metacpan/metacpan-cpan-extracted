use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBI ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();
use DBIO::SQLite::Introspect ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k57 -- a string default_value is a value, and has to arrive as that value.
#
# install_ddl wrote it between two apostrophes and left the ones inside it
# alone:
#
#   default_value => "it's"           DEFAULT 'it's'            syntax error,
#                                                               the deploy dies
#   default_value => "rock 'n' roll"  DEFAULT 'rock 'n' roll'   the same
#   default_value => "a''b"           DEFAULT 'a''b'            deploys -- as
#                                                               the default a'b
#
# The last one is why this is checked on a row and not on the statement: the
# statement is valid, the table exists, and every row gets a value nobody
# declared. A string default is written as an SQL literal with the apostrophe
# doubled, the same in every DBIO driver.
#
# Each case has a schema of its own, so that one default failing to deploy
# does not take the others' tables with it.

my $serial = 0;

# A schema with the one table "note": an id and the columns given.
sub schema_with {
  my @columns = @_;
  my $class = 'SD::Schema' . ++$serial;

  eval qq{
    package ${class}::Result::Note;
    use base 'DBIO::Core';
    __PACKAGE__->table('note');
    __PACKAGE__->add_columns(
      id => { data_type => 'integer', is_auto_increment => 1 },
      \@columns,
    );
    __PACKAGE__->set_primary_key('id');

    package $class;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');
    __PACKAGE__->register_class(Note => '${class}::Result::Note');
    1;
  } or die $@;

  return $class->connect('dbi:SQLite::memory:');
}

for my $case (
  [ q{it's},          'an apostrophe'                ],
  [ q{rock 'n' roll}, 'two apostrophes'              ],
  [ q{a''b},          'two apostrophes in a row'     ],
  [ q{'quoted'},      'an apostrophe at either end'  ],
  [ q{'},             'nothing but an apostrophe'    ],
) {
  my ($default, $label) = @$case;

  my $schema = schema_with(
    word => {
      data_type => 'varchar', size => 20, is_nullable => 0,
      default_value => $default,
    },
  );

  lives_ok { DBIO::SQLite::Deploy->new(schema => $schema)->install }
    "$label: a table with the default <$default> deploys"
    or next;

  # A row that leaves the column out; read back through the schema.
  my $row = $schema->resultset('Note')->create({});
  is($schema->resultset('Note')->find($row->id)->word, $default,
    "$label: and a new row gets <$default>");
}

# A string that looks like a number is still the string. Whether a default is a
# number cannot be seen from the Perl scalar -- '007' and 7 are both digits --
# but the column says it: one with TEXT affinity (the declared type holds CHAR,
# CLOB or TEXT, and no INT) stores text whatever it is given. Written bare,
#
#   code CHAR(3) DEFAULT 007      SQLite reads the number 7, and the column's
#                                 affinity makes the text '7' of it
#   rate TEXT DEFAULT 1.50        the number 1.5, stored as '1.5'
#
# and no row ever gets what was declared. So on such a column the default is
# always the literal in apostrophes. The row is what is asked, for the reason
# given above: DEFAULT 007 is a valid statement.
for my $type (
  [ char    => { data_type => 'char',    size => 5  } ],
  [ varchar => { data_type => 'varchar', size => 10 } ],
  [ text    => { data_type => 'text'                } ],
) {
  my ($name, $column) = @$type;

  my @defaults = ('007', '0', '10', '1.50', '-5');
  my $schema = schema_with(map {
    ( "c$_" => { %$column, is_nullable => 0, default_value => $defaults[$_] } )
  } 0 .. $#defaults);

  lives_ok { DBIO::SQLite::Deploy->new(schema => $schema)->install }
    "$name: columns with numeric-looking defaults deploy"
    or next;

  my $dbh = $schema->storage->dbh;
  my %reported = map { $_->{name} => $_->{dflt_value} }
    @{ $dbh->selectall_arrayref('PRAGMA table_xinfo("note")', { Slice => {} }) };

  my $id  = $schema->resultset('Note')->create({})->id;
  my %got = $schema->resultset('Note')->find($id)->get_columns;

  for my $i (0 .. $#defaults) {
    my $default = $defaults[$i];
    is($reported{"c$i"}, qq{'$default'},
      "$name: the default <$default> is declared as the string literal");
    is($got{"c$i"}, $default,
      "$name: and a new row gets <$default>");
  }
}

# What the fix must leave alone. On a column that does not have TEXT affinity, a
# value that matches install_ddl's numeric rule -- digits, an optional sign, an
# optional fraction -- is written bare, so the database holds a number;
# everything else is a string, including what SQLite would read as a number if
# it stood there bare. `1e3` is the one that shows it: as a string the row gets
# 1e3, as the number 1e3 it would get 1000.0.
{
  my %declared = (
    label => { data_type => 'text',    default_value => 'draft' },
    empty => { data_type => 'text',    default_value => ''      },
    qty   => { data_type => 'integer', default_value => 5       },
    delta => { data_type => 'integer', default_value => -1      },
    ratio => { data_type => 'numeric', default_value => '1.5'   },
    code  => { data_type => 'text',    default_value => '1e3'   },
  );
  my $schema = schema_with(map { $_ => $declared{$_} } sort keys %declared);

  lives_ok { DBIO::SQLite::Deploy->new(schema => $schema)->install }
    'plain strings and numbers deploy';

  my $dbh = $schema->storage->dbh;
  my %reported = map { $_->{name} => $_->{dflt_value} }
    @{ $dbh->selectall_arrayref('PRAGMA table_xinfo("note")', { Slice => {} }) };
  delete $reported{id};

  is_deeply(\%reported, {
    label => q{'draft'},
    empty => q{''},
    qty   => '5',
    delta => '-1',
    ratio => '1.5',
    code  => q{'1e3'},
  }, 'a number in a numeric column is declared bare, everything else as a string literal');

  my $id = $schema->resultset('Note')->create({})->id;
  my %got = $schema->resultset('Note')->find($id)->get_columns;
  delete $got{id};

  is_deeply(\%got,
    { map { $_ => $declared{$_}{default_value} } keys %declared },
    'and every default arrives as declared');
}

# A string of digits that is not the canonical number stays a string on any
# column, also on one without TEXT affinity: '007' and '1.50' keep their
# quotes, a canonical number goes bare (karr k81).
{
  my %declared = (
    keep  => { data_type => 'blob',    default_value => '007'  },
    frac  => { data_type => 'blob',    default_value => '1.50' },
    qty   => { data_type => 'blob',    default_value => 10     },
    ratio => { data_type => 'numeric', default_value => '1.5'  },
  );
  my $schema = schema_with(map { $_ => $declared{$_} } sort keys %declared);

  lives_ok { DBIO::SQLite::Deploy->new(schema => $schema)->install }
    'digits that are not a canonical number deploy on a column without TEXT affinity';

  my $dbh = $schema->storage->dbh;
  my %reported = map { $_->{name} => $_->{dflt_value} }
    @{ $dbh->selectall_arrayref('PRAGMA table_xinfo("note")', { Slice => {} }) };
  delete $reported{id};

  is_deeply(\%reported, {
    keep  => q{'007'},
    frac  => q{'1.50'},
    qty   => '10',
    ratio => '1.5',
  }, '007 and 1.50 keep their quotes, canonical numbers go bare');

  my $id = $schema->resultset('Note')->create({})->id;
  my %got = $schema->resultset('Note')->find($id)->get_columns;
  is $got{keep}, '007',  'and the row holds the text 007, not the number 7';
  is $got{frac}, '1.50', 'and the text 1.50, not 1.5';
}

# ---------------------------------------------------------------------------
# A database that was deployed before
# ---------------------------------------------------------------------------
#
# Until the default of a text column became a string literal, install_ddl wrote
# `code VARCHAR(10) DEFAULT 10`. Such a table meets a schema that now deploys
# DEFAULT '10', and SQLite changes a default by rebuilding the table. So what
# the upgrade does with it has to depend on whether the two are one default:
#
#   DEFAULT 10   and '10'    every new row gets the text 10 either way --
#                            nothing to do, and no table rebuilt for it
#   DEFAULT 007  and '007'   the old table gives 7, the new one 007 -- a
#                            change, and the rebuild is the fix arriving
#
# Each table is written here the way the older install_ddl wrote it, and holds
# two rows from before: one that took the old default, one with a value of its
# own.
sub older_database {
  my ($sql_type, $column, $default) = @_;

  my $schema = schema_with(
    code => { %$column, is_nullable => 0, default_value => $default },
  );
  my $dbh = $schema->storage->dbh;
  $dbh->do(qq{
    CREATE TABLE "note" (
      "id" INTEGER PRIMARY KEY NOT NULL,
      "code" $sql_type NOT NULL DEFAULT $default
    )
  });
  $dbh->do(q{INSERT INTO "note" ("id") VALUES (1)});
  $dbh->do(q{INSERT INTO "note" ("id", "code") VALUES (2, 'kept')});

  return ($schema, DBIO::SQLite::Deploy->new(schema => $schema));
}

sub codes {
  my ($schema) = @_;
  return { map { $_->[0] => $_->[1] } @{ $schema->storage->dbh->selectall_arrayref(
    q{SELECT "id", "code" FROM "note" ORDER BY "id"}) } };
}

# One default, spelled in two ways: an integer as SQLite itself would write it
# -- no leading zero, no plus sign, no -0 -- of at most 18 digits.
for my $case (
  [ 'VARCHAR(10)', { data_type => 'varchar', size => 10 }, '10' ],
  [ 'TEXT',        { data_type => 'text' },                '-5' ],
  [ 'CHAR(3)',     { data_type => 'char', size => 3 },     '0'  ],
  [ 'TEXT',        { data_type => 'text' },                '999999999999999999' ],
) {
  my ($sql_type, $column, $default) = @$case;
  my $label = "$sql_type DEFAULT $default against '$default'";
  my ($schema, $deploy) = older_database($sql_type, $column, $default);

  my $diff = $deploy->diff;
  ok(!$diff->has_changes, "$label: nothing to upgrade")
    or diag $diff->summary;
  is($deploy->upgrade, undef, "$label: and upgrade leaves the table alone");

  # What makes that the right answer: the row the schema promises is the row
  # the old table gives.
  $schema->storage->dbh->do(q{INSERT INTO "note" ("id") VALUES (3)});
  is_deeply(codes($schema), { 1 => $default, 2 => 'kept', 3 => $default },
    "$label: a new row gets <$default> from the old table");
}

# Two defaults. The last column is what the row that took the old default
# holds: that is what the old table made of the digits.
for my $case (
  [ 'VARCHAR(10)', { data_type => 'varchar', size => 10 }, '007',  '7'   ],
  [ 'TEXT',        { data_type => 'text' },                '1.50', '1.5' ],

  # The bound. Past 64 bit SQLite reads a bare integer as a REAL, so this is
  # not the digits spelled another way.
  [ 'TEXT', { data_type => 'text' }, '9223372036854775808', '9.22337203685478e+18' ],

  # And what the bound gives up, on purpose: 19 digits that fit into 64 bit.
  # The old table stored them as declared, the rebuild changes nothing a row
  # can see, and it happens all the same -- telling this one from the line
  # above takes arithmetic on a string of digits, for a default nobody has.
  [ 'TEXT', { data_type => 'text' }, '1000000000000000000', '1000000000000000000' ],
) {
  my ($sql_type, $column, $default, $old_row) = @$case;
  my $label = "$sql_type DEFAULT $default against '$default'";
  my ($schema, $deploy) = older_database($sql_type, $column, $default);

  is_deeply(codes($schema), { 1 => $old_row, 2 => 'kept' },
    "$label: the old table gave <$old_row>");

  my $diff = $deploy->diff;
  ok($diff->has_changes, "$label: is a change");

  lives_ok { $deploy->upgrade } "$label: the upgrade applies"
    or next;

  $schema->storage->dbh->do(q{INSERT INTO "note" ("id") VALUES (3)});
  is_deeply(codes($schema), { 1 => $old_row, 2 => 'kept', 3 => $default },
    "$label: the rows from before are as they were, a new one gets <$default>");

  my $again = $deploy->diff;
  ok(!$again->has_changes, "$label: and nothing is left to upgrade")
    or diag $again->summary;
}

# The rule is about columns that store text. In any other column `10` and
# '10' stay two defaults for the diff: there the declared default is the bare
# number, a quoted one is not what install_ddl writes, and in a column without
# affinity the two are not even the same value (the integer, the text). The
# target is built by hand -- the live table as introspected, with the default
# of its column in apostrophes.
for my $sql_type ('INTEGER', 'NUMERIC', 'REAL', 'BLOB') {
  my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1, PrintError => 0 });
  $dbh->do(qq{
    CREATE TABLE "note" (
      "id" INTEGER PRIMARY KEY NOT NULL,
      "qty" $sql_type NOT NULL DEFAULT 10
    )
  });

  my $live   = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;
  my $target = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;

  ok(!DBIO::SQLite::Diff->new(source => $live, target => $target)->has_changes,
    "$sql_type DEFAULT 10: the table does not differ from itself");

  my ($qty) = grep { $_->{column_name} eq 'qty' } @{ $target->{columns}{note} };
  is($qty->{default_value}, '10', "$sql_type DEFAULT 10: is read as the bare 10");
  $qty->{default_value} = q{'10'};

  ok(DBIO::SQLite::Diff->new(source => $live, target => $target)->has_changes,
    "$sql_type DEFAULT 10 against '10': is a change, the column does not store text");
}

done_testing;

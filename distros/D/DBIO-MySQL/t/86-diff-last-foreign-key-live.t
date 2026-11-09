use strict;
use warnings;
use Test::More;

# LIVE half of karr k86: DBIO::MySQL::Deploy->upgrade drops the last foreign
# key of a table when the schema no longer has it.
#
# WHY IT MATTERS. A table without a foreign key is not named among the foreign
# keys of a model at all, and the diff used to look only at the tables that are
# (t/40 has the reason and the offline half). So when the only foreign key of a
# table left the schema, an upgrade said "nothing to do" and the constraint
# stayed: the database went on refusing rows the schema allowed, and went on
# refusing to drop or empty the table it referenced. t/40 pins what the diff
# says for two models; that a server takes the statement and the constraint is
# then gone is what this file shows.
#
# What this file claims, through upgrade() of a schema against a database that
# has an earlier version of it:
#   1. the only foreign key of a table, gone from the schema, is dropped, in
#      one statement and nothing beside it;
#   2. the server no longer has it, and takes the row it refused before;
#   3. the foreign key of another table, which stayed in the schema, is still
#      there and still refuses its row;
#   4. the next diff has nothing left to say.
# The row is tried before the upgrade as well, where it must be refused: that
# it goes in afterwards is then the upgrade's doing and not the fixture's.
#
# NOT claimed, and the schema is built to stay clear of it:
#   - the index the server makes for a foreign key whose column the schema has
#     no index over: the diff drops it after the constraint (karr k94, t/90).
#     Every referencing column here has an index of the schema's own anyway;
#   - the order of the tables in the install DDL (karr k84): a moniker here
#     sorts after the one its table references.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here: upgrade() is a
# statement about a whole database -- it drops every table the schema does not
# name -- and the database the DSN names is shared with the rest of the suite.
# The account has to be allowed CREATE DATABASE, which a diff needs anyway for
# its temporary database (_dbio_tmp_*, probed up front: karr k105).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use DiffTempDbProbe qw(temp_db_skip_reason);

my $DB = "dbio_k86_$$";

my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_database() };
  }
}

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
}
if (my $why = temp_db_skip_reason($raw)) { plan skip_all => $why }
note sprintf 'server %s, DBD::%s %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'),
  $dbd, "DBD::$dbd"->VERSION, $DB;

# ---------------------------------------------------------------------------
# The schema, in the two versions it goes through
# ---------------------------------------------------------------------------
# One version of the schema, connected to the database of this test:
#   Moniker => { table => ..., columns => [ names, all integers, id first ],
#                index => { name => [columns] },                  # mysql_index
#                fk    => [ column => Moniker => its column ] }   # belongs_to
# install_ddl writes the tables in the order of their monikers and a foreign
# key into its CREATE TABLE (karr k84), so a moniker sorts after the one it
# references: Author, Book, Review.
my $version = 0;
sub schema_version {
  my (%sources) = @_;
  my $ns = 'K86Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $moniker (sort keys %sources) {
    my $def   = $sources{$moniker};
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($def->{table});
    my ($id, @others) = @{ $def->{columns} };
    $class->add_columns(
      $id => { data_type => 'integer', is_auto_increment => 1 },
      map { $_ => { data_type => 'integer' } } @others,
    );
    $class->set_primary_key($id);
    $class->mysql_index($_ => { columns => $def->{index}{$_} }) for sort keys %{ $def->{index} // {} };
    if (my $fk = $def->{fk}) {
      my ($column, $to, $to_column) = @$fk;
      $class->belongs_to("rel_$to" => "${ns}::Result::$to", { "foreign.$to_column" => "self.$column" });
    }
    $ns->register_class($moniker => $class);
  }
  # Every connection of the schema works in this test's database, whatever
  # the DSN names.
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

my %AUTHOR = (Author => { table => 'author', columns => ['id'] });
# `book` has one foreign key, and an index of the schema's own over its column.
sub book {
  my (@fk) = @_;
  return (Book => {
    table => 'book', columns => [ 'id', 'author_id' ],
    index => { key_book_author => ['author_id'] },
    (@fk ? (fk => \@fk) : ()),
  });
}
my %REVIEW = (Review => {
  table => 'review', columns => [ 'id', 'book_id' ],
  index => { key_review_book => ['book_id'] },
  fk    => [ book_id => Book => 'id' ],
});

# The foreign keys the server has in this test's database:
#   'table.column' => 'referenced table.column'
sub server_fks {
  return { map { ("$_->[0].$_->[1]" => "$_->[2].$_->[3]") } @{ $raw->selectall_arrayref(
    'SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME '
  . 'FROM information_schema.KEY_COLUMN_USAGE '
  . 'WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL', undef, $DB) } };
}

# The indexes of a table as the server lists them, the primary key left out:
# name => [ columns in their order ].
sub server_keys {
  my ($table) = @_;
  my %got;
  for my $row (@{ $raw->selectall_arrayref(
    'SELECT INDEX_NAME, COLUMN_NAME FROM information_schema.STATISTICS '
  . 'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? ORDER BY INDEX_NAME, SEQ_IN_INDEX', undef, $DB, $table,
  ) }) {
    my ($name, $column) = @$row;
    push @{ $got{$name} }, $column unless $name eq 'PRIMARY';
  }
  return \%got;
}

# A row goes in / is refused because the row it references is not there.
sub goes_in {
  my ($rs, $row, $name) = @_;
  ok eval { $rs->create($row); 1 }, $name or diag "refused: $@";
}
sub is_refused {
  my ($rs, $row, $name) = @_;
  my $went_in = eval { $rs->create($row); 1 };
  my $error   = "$@";
  ok !$went_in && $error =~ /foreign key constraint fails/, $name
    or diag $went_in ? 'the row went in' : "refused for another reason: $error";
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# Claim 4: the diff of the schema against the database it was just installed
# into or upgraded to has nothing left.
sub nothing_left {
  my ($schema, $name) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $diff && !$diff->has_changes, $name
    or diag $diff ? explain [ map { $_->as_sql } @{ $diff->operations } ] : "the diff failed: $@";
}

# ---------------------------------------------------------------------------
# 0. The starting point: `book` references `author`, `review` references
#    `book`, installed.
# ---------------------------------------------------------------------------
my $schema = schema_version(%AUTHOR, book(author_id => Author => 'id'), %REVIEW);

unless (ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the starting schema installs') {
  diag "the install failed, and nothing below can be asked: $@";
  done_testing;
  exit;   # END drops what was created
}
is_deeply server_fks(), { 'book.author_id' => 'author.id', 'review.book_id' => 'book.id' },
  'to begin with each of the two tables has its one foreign key';
is_deeply server_keys('book'), { key_book_author => ['author_id'] },
  '... and `book` the index of the schema over the referencing column, and none of the server\'s';

my $author = $schema->resultset('Author')->create({});
goes_in $schema->resultset('Book'), { author_id => $author->id }, 'a book of an author that is there goes in';
is_refused $schema->resultset('Book'), { author_id => $author->id + 1000 },
  'control: while the foreign key is there, a book of an author that is not there is refused';
nothing_left $schema, '... and the diff against the schema finds nothing left';

# ---------------------------------------------------------------------------
# 1. The only foreign key of `book` gone from the schema
# ---------------------------------------------------------------------------
$schema->storage->disconnect;
$schema = schema_version(%AUTHOR, book(), %REVIEW);

# The constraint has the name the server gave it at install.
my $deploy = DBIO::MySQL::Deploy->new(schema => $schema);
my $diff   = eval { $deploy->upgrade(allow_destructive => 1) };
diag "upgrade failed: $@" if $@;
is_deeply [ $diff ? map { $_->as_sql } @{ $diff->operations } : () ],
  [ 'ALTER TABLE `book` DROP FOREIGN KEY `book_author_id_fk`;' ],
  'removed: upgrade drops the only foreign key of the table, and does nothing else';

is_deeply server_fks(), { 'review.book_id' => 'book.id' },
  '... and the server no longer has it, while the one of `review` is still there';
is_deeply server_keys('book'), { key_book_author => ['author_id'] },
  '... and the index over the column is still there';

goes_in $schema->resultset('Book'), { author_id => $author->id + 1000 },
  '... the book it refused goes in';
is_refused $schema->resultset('Review'), { book_id => 1_000_000 },
  '... and the foreign key that stayed still refuses a review of a book that is not there';
nothing_left $schema, '... and the next diff has nothing left';

note 'warned during the run: ' . join ' | ', map { s/\s+\z//r } @warnings if @warnings;

$schema->storage->disconnect;
drop_database();
$raw->disconnect;
undef $raw;

done_testing;

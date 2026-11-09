use strict;
use warnings;
use Test::More;

# t/48-ddl-qualified-name.t -- a source named database.table (karr k43, core
# conformance case ddl-qualified-source-name). Offline: no DBD, no DSN, no
# server; the live half is t/48-ddl-qualified-name-live.t.
#
# WHY IT MATTERS. table('other.t') once became one table literally called
# `other.t` in the connected database (and then, as a stopgap, a refusal),
# while a query through the SQLMaker reads `other`.`t`: a table nobody could
# reach. The name is database.table, and the table is made in that database.
#
# Claims:
#   1. install_ddl writes it CREATE TABLE `other`.`t` -- never `other.t` as one
#      identifier -- and a plain table next to it stays as it was;
#   2. local_only leaves it out: the scratch database of a diff gets the tables
#      of the current database alone, since the diff reads nothing else;
#   3. qualified_tables lists them once each, with their database, and not a
#      view or a table without a dot;
#   4. the Deploy class hands that scratch install local_only, the live one not;
#   5. split_table_name splits at the one dot and refuses what names nothing.

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::ClickHouse::DDL;
use DBIO::ClickHouse::Deploy;
use DBIO::ClickHouse::DDL::Emit qw(split_table_name create_table);

my $n = 0;
sub schema_of {
  my @spec = @_;
  my $schema = 'My::CH::Qual' . ++$n;
  { no strict 'refs'; @{"${schema}::ISA"} = ('DBIO::Schema'); }
  while (my ($name, $code) = splice @spec, 0, 2) {
    my $class = "${schema}::Result::$name";
    { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Core'); }
    $code->($class, $schema);
    $schema->register_class($name => $class);
  }
  return $schema;
}
my $table = sub {
  my ($name) = @_;
  return sub {
    my ($class) = @_;
    $class->table($name);
    $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
    $class->set_primary_key('id');
  };
};

# --- 1. the statement --------------------------------------------------------
my $schema = schema_of(Q => $table->('other.t'), Plain => $table->('plain'));
my $ddl = DBIO::ClickHouse::DDL->install_ddl($schema);
like $ddl, qr/CREATE TABLE `other`\.`t` \(/, 'database.table is written `other`.`t`';
unlike $ddl, qr/`other\.t`/, '... and never as one identifier with a dot in it';
like $ddl, qr/CREATE TABLE `plain` \(/, 'a table without a dot is untouched';

# --- 2. local_only -----------------------------------------------------------
my $local = DBIO::ClickHouse::DDL->install_ddl($schema, { local_only => 1 });
unlike $local, qr/other/, 'local_only leaves the table of another database out';
like $local, qr/CREATE TABLE `plain`/, '... and keeps the others';

# --- 3. qualified_tables -----------------------------------------------------
my $two = schema_of(A => $table->('db1.a'), B => $table->('db1.a'), C => $table->('db2.c'),
                    D => $table->('d'));
is_deeply [ DBIO::ClickHouse::DDL->qualified_tables($two) ],
  [ [ 'db1.a', 'db1' ], [ 'db2.c', 'db2' ] ],
  'the qualified tables, once each, with their database';
is_deeply [ DBIO::ClickHouse::DDL->qualified_tables(schema_of(D => $table->('d'))) ], [],
  'none without a dot';

# --- 4. the Deploy class -----------------------------------------------------
{
  my $deploy = DBIO::ClickHouse::Deploy->new(schema => $schema);
  local $deploy->{_local_only} = 1;
  unlike $deploy->_ddl_class->install_ddl($schema, { local_only => 1 }), qr/other/,
    'the scratch install of the Deploy is the local one';
}

# --- 5. the split ------------------------------------------------------------
is_deeply [ split_table_name('other.t') ], [ 'other', 't' ], 'split at the dot';
is_deeply [ split_table_name('t') ], [ undef, 't' ], 'no dot: the table alone';
for my $bad ('a.b.c', '.t', 'db.') {
  eval { split_table_name($bad) };
  like "$@", qr/\Q$bad\E.*refused/s, "'$bad' names nothing and is refused";
}
like create_table(database => 'other', name => 't', columns => ['`id` Int32']),
  qr/\ACREATE TABLE `other`\.`t` \(/, 'create_table takes the database apart from the name';

done_testing;

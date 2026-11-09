use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;
use DBIO::MySQL::Diff::Table;
use DBIO::MySQL::Diff::Column;

# karr k78 / k96: one helper renders every DEFAULT -- install (DDL), a new table
# of a diff (Diff::Table) and ADD / MODIFY COLUMN (Diff::Column).
#
# WHY IT MATTERS. The four places wrote DEFAULT '<value>' without looking at the
# value:
#   * an apostrophe ended the literal (DEFAULT 'it's'), and a backslash is an
#     escape on both servers in their default sql_mode (measured MySQL 8.0.30
#     and MariaDB 11.8.9: 'a\\b' is the value a\b), so it has to be doubled;
#   * the diff read CURRENT_TIMESTAMP from the catalog as a plain value and
#     wrote DEFAULT 'CURRENT_TIMESTAMP' -- a string, which the server refuses
#     for a timestamp (1067).
# A scalar reference is written as it is (the schema's own expression); a
# catalog default that is an expression says so with default_is_expression
# (DBIO::MySQL::Introspect::Columns). The live half is t/113.

# --- install (DDL) -----------------------------------------------------------

{
  package K78::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package K78::Schema::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('MySQL::Result');
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    note    => { data_type => 'varchar', size => 40, default_value => "it's" },
    path    => { data_type => 'varchar', size => 40, default_value => 'C:\\tmp\\x' },
    code    => { data_type => 'char',    size => 5,  default_value => '007' },
    hits    => { data_type => 'integer', default_value => 0 },
    created => { data_type => 'timestamp', is_nullable => 1, default_value => \'CURRENT_TIMESTAMP' },
  );
  __PACKAGE__->set_primary_key('id');
}
K78::Schema->register_class(Item => 'K78::Schema::Result::Item');

my $ddl = DBIO::MySQL::DDL->install_ddl('K78::Schema');
like $ddl, qr/`note` [^\n]*? NOT NULL DEFAULT 'it''s'/, 'install: an apostrophe is doubled';
like $ddl, qr/`path` [^\n]*? NOT NULL DEFAULT 'C:\\\\tmp\\\\x'/, 'install: a backslash is doubled';
like $ddl, qr/`code` [^\n]*? NOT NULL DEFAULT '007'/, 'install: a string that looks like a number stays a string';
like $ddl, qr/`hits` [^\n]*? NOT NULL DEFAULT '0'/, 'install: a number is still written as before';
like $ddl, qr/`created` \w+ DEFAULT CURRENT_TIMESTAMP,/, 'install: a scalar reference is written as it is';

# --- diff: new table ---------------------------------------------------------

sub table_sql {
  my (@cols) = @_;
  my @ops = DBIO::MySQL::Diff::Table->diff({}, { t => { table_name => 't' } }, { t => \@cols });
  return $ops[0]->as_sql;
}

like table_sql({ column_name => 'a', data_type => 'timestamp', column_type => 'timestamp',
                 default_value => 'CURRENT_TIMESTAMP', default_is_expression => 1 }),
  qr/`a` timestamp DEFAULT CURRENT_TIMESTAMP\n/,
  'new table: a catalog expression is not quoted (this was DEFAULT \'CURRENT_TIMESTAMP\')';
like table_sql({ column_name => 'a', data_type => 'datetime', column_type => 'datetime(3)',
                 default_value => 'current_timestamp(3)', default_is_expression => 1 }),
  qr/`a` datetime\(3\) DEFAULT current_timestamp\(3\)\n/,
  '... with its precision';
like table_sql({ column_name => 'a', data_type => 'varchar', column_type => 'varchar(40)',
                 default_value => 'uuid()', default_is_expression => 1 }),
  qr/`a` varchar\(40\) DEFAULT \(uuid\(\)\)\n/,
  '... any other expression is parenthesised, as both servers demand';
like table_sql({ column_name => 'a', data_type => 'varchar', column_type => 'varchar(40)', default_value => "it's" }),
  qr/`a` varchar\(40\) DEFAULT 'it''s'\n/, 'new table: a literal with an apostrophe';
like table_sql({ column_name => 'a', data_type => 'varchar', column_type => 'varchar(40)', default_value => 'a\\b' }),
  qr/`a` varchar\(40\) DEFAULT 'a\\\\b'\n/, '... and a backslash';
like table_sql({ column_name => 'a', data_type => 'varchar', column_type => 'varchar(40)',
                 default_value => 'CURRENT_TIMESTAMP', default_is_expression => 0 }),
  qr/DEFAULT 'CURRENT_TIMESTAMP'\n/, '... and the string CURRENT_TIMESTAMP of a string column stays a string';

# --- diff: ADD and MODIFY COLUMN ---------------------------------------------

sub column_sql {
  my ($action, $info) = @_;
  return DBIO::MySQL::Diff::Column->new(
    action => $action, table_name => 't', column_name => 'a', new_info => $info,
  )->as_sql;
}

for my $action (qw(add modify)) {
  my $verb = uc $action;
  is column_sql($action, { column_type => 'timestamp', default_value => 'CURRENT_TIMESTAMP', default_is_expression => 1 }),
    "ALTER TABLE `t` $verb COLUMN `a` timestamp DEFAULT CURRENT_TIMESTAMP;",
    "$verb COLUMN: a catalog expression is not quoted";
  is column_sql($action, { column_type => 'varchar(40)', default_value => "it's" }),
    "ALTER TABLE `t` $verb COLUMN `a` varchar(40) DEFAULT 'it''s';",
    "$verb COLUMN: an apostrophe is doubled";
  is column_sql($action, { column_type => 'varchar(40)', default_value => 'a\\b' }),
    "ALTER TABLE `t` $verb COLUMN `a` varchar(40) DEFAULT 'a\\\\b';",
    "$verb COLUMN: a backslash is doubled";
  is column_sql($action, { column_type => 'int(11)', default_value => \'7' }),
    "ALTER TABLE `t` $verb COLUMN `a` int(11) DEFAULT 7;",
    "$verb COLUMN: a scalar reference is written as it is";
}

# --- an expression that becomes a string of the same text is a change --------

{
  my @c = DBIO::MySQL::Diff::Column->diff(
    { t => [ { column_name => 'a', column_type => 'varchar(40)', default_value => 'uuid()', default_is_expression => 1 } ] },
    { t => [ { column_name => 'a', column_type => 'varchar(40)', default_value => 'uuid()', default_is_expression => 0 } ] },
    { t => {} }, { t => {} },
  );
  is scalar @c, 1, 'the same text as expression on one side and literal on the other is a change';
  my @same = DBIO::MySQL::Diff::Column->diff(
    { t => [ { column_name => 'a', column_type => 'varchar(40)', default_value => 'uuid()', default_is_expression => 1 } ] },
    { t => [ { column_name => 'a', column_type => 'varchar(40)', default_value => 'uuid()', default_is_expression => 1 } ] },
    { t => {} }, { t => {} },
  );
  is scalar @same, 0, '... and the same on both sides is none';
}

done_testing;

use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;
use DBIO::MySQL::Diff;
use DBIO::MySQL::Identifier ();

# karr k89, carried on by karr k120: a source name with a dot is never the
# table literally called `db.t`.
#
# WHY IT MATTERS. The DDL once quoted a name as ONE identifier (karr k77), so
# table('db.t') silently created a table literally called `db.t` in the current
# database, while a query through the SQLMaker reads `db`.`t`: a table nobody
# could reach, and no error. k89 refused the name; k120 supports it: the name
# is database.table, written `db`.`t`, and the install (DBIO::MySQL::Deploy)
# refuses a database the server does not have, naming table and database
# (t/167). What stays from k89 is the part that mattered: no table with a dot
# in its name is made by accident, and a name that names nothing is refused.
#
# Claims:
#   1. install_ddl writes table('db.t'), the literal \'db.t' and the "db.t"
#      form as the table t of the database db -- CREATE TABLE `db`.`t`, its
#      indexes ON `db`.`t` -- never as one identifier with a dot in it;
#   2. a name with two dots, an empty half, or a view with a dot throws a
#      DBIO::Exception naming it, and renders nothing;
#   3. a name without a dot is untouched (a dot in a COLUMN name is not this
#      rule's business);
#   4. the temporary database of a diff gets the tables of the current database
#      only (local_only), and the diff target leaves a table of another
#      database out;
#   5. a dotted table that only the live database has is legal MySQL and no
#      reason to refuse: the diff drops it like any other;
#   6. a foreign key to or from a table of another database is refused, not
#      left out silently;
#   7. drop_ddl names the table the install made, `db`.`t`.

sub schema_with {
  my ($tag, $table, $view, %opt) = @_;
  my $schema = "QualTest${tag}::Schema";
  my $result = "QualTest${tag}::Schema::Result::T";
  eval <<"PERL" or die $@;
package $schema;
use DBIO 'Schema';
__PACKAGE__->load_components('MySQL');
package $result;
use DBIO 'Core', -mysql;
1;
PERL
  if ($view) {
    $result->table_class('DBIO::ResultSource::View');
    $result->table($table);
    $result->result_source_instance->view_definition('SELECT 1 AS id');
  }
  else {
    $result->table($table);
  }
  $result->add_columns(id => { data_type => 'int' }, 'a.b' => { data_type => 'int', is_nullable => 1, accessor => 'a_b' });
  $result->set_primary_key('id') unless $view;
  $result->mysql_index(by_ab => { columns => ['a.b'] }) if $opt{index};
  $schema->register_class(T => $result);
  return $schema;
}

my $n = 0;

# 1.
for my $case (
  [ 'db.t',   'table' ],
  [ \'db.t',  'literal table' ],
) {
  my ($name, $label) = @$case;
  my $schema = schema_with(++$n, $name, 0, index => 1);
  my $ddl = DBIO::MySQL::DDL->install_ddl($schema);
  like($ddl, qr/CREATE TABLE `db`\.`t` \(/, "1: a $label is created in its database");
  like($ddl, qr/CREATE INDEX `by_ab` ON `db`\.`t` /, '1: ... its index is made on it');
  unlike($ddl, qr/`db\.t`/, '1: ... and no table with the dot in its name');

  my $local = DBIO::MySQL::DDL->install_ddl($schema, { local_only => 1 });
  unlike($local // '', qr/\bt\b/, '4: the temporary database of a diff does not get it');

  is_deeply [ DBIO::MySQL::DDL->qualified_tables($schema) ], [ [ 'db.t', 'db' ] ],
    '... and the DDL class lists it with its database';
  like(DBIO::MySQL::DDL->drop_ddl($schema), qr/DROP TABLE IF EXISTS `db`\.`t`;/, '7: drop_ddl drops that table');

  # the compiled model of the schema, as DBIO::Schema::ModelCompiler gives it
  my $compiled = { tables => { 'db.t' => {
    table_name => 'db.t', primary_key => ['id'],
    columns => [ { column_name => 'id', native_type => 'INT', not_null => 1, is_pk => 1 } ],
  } } };
  my $target = eval { DBIO::MySQL::Diff->target_from_compiled($compiled) };
  is($@, '', "4: the diff target takes a schema with a table of another database ($label)");
  is_deeply([ sort keys %{ $target->{tables} } ], [], '4: ... and leaves it out');
}

# 2.
for my $case (
  [ 'a.b.c', 'a name with two dots', 0 ],
  [ '.t',    'a name with an empty database', 0 ],
  [ 'db.',   'a name with an empty table', 0 ],
  [ 'db.v',  'a view with a dot', 1 ],
) {
  my ($name, $label, $view) = @$case;
  my $schema = schema_with(++$n, $name, $view);
  my $ddl;
  eval { $ddl = DBIO::MySQL::DDL->install_ddl($schema); 1 };
  my $err = $@;
  ok(ref $err && $err->isa('DBIO::Exception'), "2: install_ddl refuses $label (DBIO::Exception)")
    or diag defined $ddl ? $ddl : "$err";
  like("$err", qr/\Q$name\E/, '... and names it');
  is($ddl, undef, '... nothing is rendered');
}

# 3. no dot: untouched
{
  my $schema = schema_with(++$n, 'plain_t');
  my $ddl = DBIO::MySQL::DDL->install_ddl($schema);
  like($ddl, qr/CREATE TABLE `plain_t` \(\n  `id` int NOT NULL,\n  `a\.b` int/,
    '3: a name without a dot is installed (a dotted column name stays legal)');
  is_deeply [ DBIO::MySQL::DDL->qualified_tables($schema) ], [], '... and is no table of another database';
  my $target = DBIO::MySQL::Diff->target_from_compiled({ tables => { plain_t => {
    table_name => 'plain_t', primary_key => ['id'],
    columns => [ { column_name => 'id', native_type => 'INT', not_null => 1, is_pk => 1 } ],
  } } });
  ok($target->{tables}{plain_t}, 'target_from_compiled takes a name without a dot');
}

# 5. a dotted table that exists only in the live database
{
  my $source = {
    tables  => { 'db.t' => { table_name => 'db.t' } },
    columns => { 'db.t' => [ { column_name => 'id', data_type => 'int', column_type => 'int', not_null => 1 } ] },
    indexes => {}, foreign_keys => {},
  };
  my $target = DBIO::MySQL::Diff->target_from_compiled({ tables => {} });
  my $sql = eval { DBIO::MySQL::Diff->new(source => $source, target => $target)->as_sql };
  is($@, '', '5: a dotted table only the live database has does not make the diff throw');
  like($sql, qr/DROP TABLE `db\.t`;/, '... it is dropped, by its true name');
}

# 6. a foreign key across databases
{
  my $schema = "QualFk::Schema";
  eval <<'PERL' or die $@;
package QualFk::Schema;
use DBIO 'Schema';
__PACKAGE__->load_components('MySQL');
package QualFk::Schema::Result::Parent;
use DBIO 'Core', -mysql;
__PACKAGE__->table('other.parent');
__PACKAGE__->add_columns(id => { data_type => 'int' });
__PACKAGE__->set_primary_key('id');
package QualFk::Schema::Result::Child;
use DBIO 'Core', -mysql;
__PACKAGE__->table('child');
__PACKAGE__->add_columns(id => { data_type => 'int' }, parent_id => { data_type => 'int' });
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(parent => 'QualFk::Schema::Result::Parent', 'parent_id');
QualFk::Schema->register_class(Parent => 'QualFk::Schema::Result::Parent');
QualFk::Schema->register_class(Child => 'QualFk::Schema::Result::Child');
1;
PERL
  my $ddl = eval { DBIO::MySQL::DDL->install_ddl($schema) };
  like("$@", qr/foreign key of child to other\.parent is refused/, '6: a key to a table of another database is refused');
  is($ddl, undef, '... nothing is rendered');
}

# the helpers
{
  is_deeply [ DBIO::MySQL::Identifier::split_table_name('o.t') ], [ 'o', 't' ], 'split_table_name: database and table';
  is_deeply [ DBIO::MySQL::Identifier::split_table_name('t') ], [ undef, 't' ], '... a table alone';
  is(DBIO::MySQL::Identifier::quote_table('we`ird.t'), '`we``ird`.`t`', 'quote_table quotes both halves');
  is(DBIO::MySQL::Identifier::quote_table('t'), '`t`', '... and a plain table');
}

done_testing;

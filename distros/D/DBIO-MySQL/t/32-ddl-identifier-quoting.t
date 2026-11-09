use strict;
use warnings;
use Test::More;

use_ok 'DBIO::MySQL::Identifier';
use DBIO::MySQL::DDL;
use DBIO::MySQL::Deploy;
use DBIO::MySQL::Diff::Table;
use DBIO::MySQL::Diff::Column;
use DBIO::MySQL::Diff::Index;
use DBIO::MySQL::Diff::ForeignKey;

# karr k77: every identifier this driver writes into a DDL statement is in
# backticks, and a backtick inside it is doubled.
#
# WHY IT MATTERS. DBIO::MySQL::DDL used to quote with core's
# DBIO::SQL::Util::_quote_ident, which is ANSI quoting: a plain name stays
# bare, anything else goes into double quotes. On MySQL and MariaDB both are
# wrong. A bare `order`, `key` or `group` is a reserved word and the server
# answers 1064; "my-col" is a string literal unless the session runs in
# ANSI_QUOTES, and a string where a name belongs is 1064 again. So a schema
# with a table `order` could not be installed, and since diff and upgrade
# deploy the schema into a temporary database first, it could not be upgraded
# either. The diff operations did use backticks, but wrote the name between
# them as it came: a name with a backtick in it ended the quoting early.
#
# What this file claims:
#   1. install_ddl writes every name in backticks -- of a table, a column, the
#      primary key, a unique key, a foreign key and the table and column it
#      references, an index and a view -- and leaves the definition of a view,
#      which is the user's SQL, as it is;
#   2. the four diff operations do the same for every name they write, a name
#      with a backtick in it included;
#   3. so does the temporary database of a diff;
#   4. the rule itself: always backticks, a backtick doubled, nothing else
#      touched.
# The statements are compared whole. Whether a server takes them is the live
# half, t/85-ddl-identifier-quoting-live.t.

# ---------------------------------------------------------------------------
# 1. install_ddl
# ---------------------------------------------------------------------------
{
  package DDLQuoteTest::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DDLQuoteTest::Schema::Result::Group;
  use DBIO 'Core', -mysql;

  __PACKAGE__->table('group');
  __PACKAGE__->add_columns(
    key => { data_type => 'int', is_auto_increment => 1, accessor => 'group_key' },
  );
  __PACKAGE__->set_primary_key('key');
}
{
  package DDLQuoteTest::Schema::Result::Order;
  use DBIO 'Core', -mysql;

  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id       => { data_type => 'int', is_auto_increment => 1 },
    key      => { data_type => 'varchar', size => 20, accessor => 'order_key' },
    group    => { data_type => 'int', accessor => 'group_id' },
    'my-col' => { data_type => 'int', is_nullable => 1, accessor => 'my_col' },
    'we`ird' => { data_type => 'int', is_nullable => 1, accessor => 'weird' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(index => ['key', 'my-col']);
  __PACKAGE__->mysql_index(rank => { columns => ['group', 'we`ird'] });
  __PACKAGE__->mysql_index('uniq`rank' => { unique => 1, using => 'BTREE', columns => ['key'] });
  __PACKAGE__->belongs_to(
    grp => 'DDLQuoteTest::Schema::Result::Group', { 'foreign.key' => 'self.group' },
  );
}
{
  package DDLQuoteTest::Schema::Result::Desc;
  use DBIO 'Core', -mysql;

  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('desc');
  __PACKAGE__->result_source_instance->view_definition('SELECT `key`, "group" FROM `order`');
  __PACKAGE__->add_columns(key => { data_type => 'varchar', size => 20, accessor => 'order_key' });
}
DDLQuoteTest::Schema->register_class(Group => 'DDLQuoteTest::Schema::Result::Group');
DDLQuoteTest::Schema->register_class(Order => 'DDLQuoteTest::Schema::Result::Order');
DDLQuoteTest::Schema->register_class(Desc  => 'DDLQuoteTest::Schema::Result::Desc');

is(DBIO::MySQL::DDL->install_ddl('DDLQuoteTest::Schema') . "\n", <<'DDL',
CREATE TABLE `group` (
  `key` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order` (
  `id` int NOT NULL AUTO_INCREMENT,
  `key` varchar(20) NOT NULL,
  `group` int NOT NULL,
  `my-col` int,
  `we``ird` int,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index` (`key`, `my-col`),
  CONSTRAINT `order_group_fk` FOREIGN KEY (`group`) REFERENCES `group`(`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `rank` ON `order` (`group`, `we``ird`);

CREATE UNIQUE INDEX `uniq``rank` ON `order` (`key`) USING BTREE;

CREATE VIEW `desc` AS SELECT `key`, "group" FROM `order`;
DDL
  'install_ddl: every name in backticks, a backtick in a name doubled, the view definition untouched');

# ---------------------------------------------------------------------------
# 2. The diff operations
# ---------------------------------------------------------------------------
# Every statement each of the four classes can write, for one set of names:
# the table, a second table it references, two columns and the name of an
# index and of a foreign key.
sub diff_statements {
  my (%n) = @_;
  my @cols = (
    { column_name => $n{pk},  data_type => 'int', column_type => 'int(11)', not_null => 1, is_pk => 1 },
    { column_name => $n{col}, data_type => 'int', column_type => 'int(11)', not_null => 1 },
  );
  my %fk = (
    constraint_name => $n{fk}, from_columns => [ $n{col} ],
    to_table => $n{other}, to_columns => [ $n{pk} ],
  );
  my %index = (index_name => $n{index}, is_unique => 0, columns => [ $n{pk}, $n{col} ], origin => 'c');
  my %there = ($n{table} => { table_name => $n{table} });

  return [ map { $_->as_sql } (
    # CREATE TABLE with its primary key and its foreign key, and DROP TABLE
    DBIO::MySQL::Diff::Table->diff({}, {%there}, { $n{table} => [@cols] }, { $n{table} => [ {%fk} ] }),
    DBIO::MySQL::Diff::Table->diff({%there}, {}),
    # ADD COLUMN, MODIFY COLUMN, DROP COLUMN
    DBIO::MySQL::Diff::Column->diff(
      { $n{table} => [ $cols[0] ] }, { $n{table} => [@cols] }, {%there}, {%there}),
    DBIO::MySQL::Diff::Column->diff(
      { $n{table} => [@cols] },
      { $n{table} => [ $cols[0], { %{ $cols[1] }, data_type => 'bigint', column_type => 'bigint(20)' } ] },
      {%there}, {%there}),
    DBIO::MySQL::Diff::Column->diff(
      { $n{table} => [@cols] }, { $n{table} => [ $cols[0] ] }, {%there}, {%there}),
    # CREATE INDEX, DROP INDEX
    DBIO::MySQL::Diff::Index->diff({}, { $n{table} => { $n{index} => {%index} } }),
    DBIO::MySQL::Diff::Index->diff({ $n{table} => { $n{index} => {%index} } }, {}),
    # ADD CONSTRAINT ... FOREIGN KEY, DROP FOREIGN KEY
    DBIO::MySQL::Diff::ForeignKey->diff(
      { $n{table} => [] }, { $n{table} => [ {%fk} ] }, {%there}, {%there}),
    DBIO::MySQL::Diff::ForeignKey->diff(
      { $n{table} => [ {%fk} ] }, { $n{table} => [] }, {%there}, {%there}),
  ) ];
}

# Reserved words and a name that is no plain word. The diff operations wrote
# these correctly before k77 as well; they are here so that it stays that way.
is_deeply diff_statements(
  table => 'order', other => 'group', pk => 'key', col => 'my-col', index => 'rank', fk => 'desc',
), [
  "CREATE TABLE `order` (\n"
    . "  `key` int(11) NOT NULL,\n"
    . "  `my-col` int(11) NOT NULL,\n"
    . "  PRIMARY KEY (`key`),\n"
    . "  CONSTRAINT `desc` FOREIGN KEY (`my-col`) REFERENCES `group`(`key`)\n"
    . ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
  'DROP TABLE `order`;',
  'ALTER TABLE `order` ADD COLUMN `my-col` int(11) NOT NULL;',
  'ALTER TABLE `order` MODIFY COLUMN `my-col` bigint(20) NOT NULL;',
  'ALTER TABLE `order` DROP COLUMN `my-col`;',
  'CREATE INDEX `rank` ON `order` (`key`, `my-col`);',
  'DROP INDEX `rank` ON `order`;',
  'ALTER TABLE `order` ADD CONSTRAINT `desc` FOREIGN KEY (`my-col`) REFERENCES `group`(`key`);',
  'ALTER TABLE `order` DROP FOREIGN KEY `desc`;',
], 'diff operations: reserved words and a name with a hyphen are in backticks';

# A backtick in every name. Written as it came, each of them ended the quoting
# after its first half.
is_deeply diff_statements(
  table => 'or`der', other => 'gr`oup', pk => 'k`ey', col => 'my`col', index => 'ra`nk', fk => 'de`sc',
), [
  "CREATE TABLE `or``der` (\n"
    . "  `k``ey` int(11) NOT NULL,\n"
    . "  `my``col` int(11) NOT NULL,\n"
    . "  PRIMARY KEY (`k``ey`),\n"
    . "  CONSTRAINT `de``sc` FOREIGN KEY (`my``col`) REFERENCES `gr``oup`(`k``ey`)\n"
    . ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
  'DROP TABLE `or``der`;',
  'ALTER TABLE `or``der` ADD COLUMN `my``col` int(11) NOT NULL;',
  'ALTER TABLE `or``der` MODIFY COLUMN `my``col` bigint(20) NOT NULL;',
  'ALTER TABLE `or``der` DROP COLUMN `my``col`;',
  'CREATE INDEX `ra``nk` ON `or``der` (`k``ey`, `my``col`);',
  'DROP INDEX `ra``nk` ON `or``der`;',
  'ALTER TABLE `or``der` ADD CONSTRAINT `de``sc` FOREIGN KEY (`my``col`) REFERENCES `gr``oup`(`k``ey`);',
  'ALTER TABLE `or``der` DROP FOREIGN KEY `de``sc`;',
], 'diff operations: a backtick in a name is doubled, in every statement and every position';

# ---------------------------------------------------------------------------
# 3. The temporary database of a diff
# ---------------------------------------------------------------------------
# Its name starts with temp_db_prefix, which is the caller's.
{
  package DDLQuoteTest::Dbh;
  sub new { bless { did => [] }, shift }
  sub do  { push @{ $_[0]{did} }, $_[1]; 1 }
}
{
  my $deploy = DBIO::MySQL::Deploy->new(schema => 'DDLQuoteTest::Schema', temp_db_prefix => 'tmp`db-');
  my $dbh    = DDLQuoteTest::Dbh->new;
  my $name   = $deploy->_create_temp_db($dbh);
  $deploy->_drop_temp_db($dbh, $name);

  like $name, qr/\Atmp`db-\d+_\d+\z/, 'the temporary database is named after temp_db_prefix';
  (my $quoted = $name) =~ s/`/``/;
  is_deeply $dbh->{did}, [ "CREATE DATABASE `$quoted`", "DROP DATABASE IF EXISTS `$quoted`" ],
    '... and created and dropped under that name, its backtick doubled';
}

# ---------------------------------------------------------------------------
# 4. The rule
# ---------------------------------------------------------------------------
{
  my $quote = \&DBIO::MySQL::Identifier::quote_ident;

  is $quote->('users'),    '`users`',    'a plain name is quoted too: no list of reserved words to keep';
  is $quote->('order'),    '`order`',    'a reserved word';
  is $quote->('my-col'),   '`my-col`',   'a name that is no plain word';
  is $quote->('we`ird'),   '`we``ird`',  'a backtick in the name is doubled';
  is $quote->('`'),        '````',       '... a name that is nothing but one as well';
  is $quote->('a`b`c'),    '`a``b``c`',  '... and every one of several';
  is $quote->('say "hi"'), '`say "hi"`', 'a double quote is no special character between backticks';
  is $quote->('a\\b'),     '`a\\b`',     'neither is a backslash';
  # One identifier in, one identifier out: the helper does not read a dot as
  # the separator of a qualified name.
  is $quote->('db.t'),     '`db.t`',     'a dot is part of the name';

  my $name = 'we`ird';
  $quote->($name);
  is $name, 'we`ird', 'the name handed in is left as it was';
}

done_testing;

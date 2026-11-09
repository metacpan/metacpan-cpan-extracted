use strict;
use warnings;
use Test::More;

use DBIO::SQLite::DDL;

# sqlite_index documents `expression` (replaces `columns`) for expression
# indexes. install_ddl used to read only unique/columns/where, so an
# expression-only index came out as `CREATE INDEX "idx" ON "t" ();` -- a SQL
# syntax error at deploy. The generated DDL must execute against SQLite.

BEGIN {
  eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';
}

{
  package ExprIdxTest::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package ExprIdxTest::Schema::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('SQLite::Result');

  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    role => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->sqlite_index('idx_users_name_lower' => {
    expression => 'lower(name)',
  });
  __PACKAGE__->sqlite_index('idx_users_name_lower_uniq' => {
    expression => 'lower(name)',
    unique     => 1,
    where      => "role != 'suspended'",
  });
  __PACKAGE__->sqlite_index('idx_users_role' => { columns => ['role'] });
}
ExprIdxTest::Schema->register_class(User => 'ExprIdxTest::Schema::Result::User');

my $ddl = DBIO::SQLite::DDL->install_ddl('ExprIdxTest::Schema');

like $ddl, qr/ON "users" \(lower\(name\)\);/,
  'expression emitted in place of columns, as the schema gives it';
unlike $ddl, qr/\(\)/, 'no empty column list';
like $ddl, qr/UNIQUE INDEX "idx_users_name_lower_uniq" ON "users" \(lower\(name\)\) WHERE role != 'suspended';/,
  'expression combines with unique and where';
like $ddl, qr/INDEX "idx_users_role" ON "users" \("role"\);/,
  'plain columns index: its columns are names, and quoted';

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1 });
$dbh->do($_) for grep { /\S/ } split /;\s*\n/, $ddl;

my %idx = map { $_->[0] => 1 }
  @{ $dbh->selectall_arrayref(q{SELECT name FROM sqlite_master WHERE type = 'index'}) };
ok $idx{idx_users_name_lower}, 'expression index exists in sqlite_master';
ok $idx{idx_users_name_lower_uniq}, 'unique partial expression index exists';

done_testing;

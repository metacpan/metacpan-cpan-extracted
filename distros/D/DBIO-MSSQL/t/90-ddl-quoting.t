use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::DDL qw(_quote_ident);
use DBIO::MSSQL::Diff::Table;
use DBIO::MSSQL::Diff::Column;
use DBIO::MSSQL::Diff::Index;
use DBIO::MSSQL::Diff::ForeignKey;

# karr k71 (ADR 0060 cases ddl-default-string-apostrophe, ddl-default-digit-string,
# ddl-ident-reserved-word, ddl-qualified-source-name; ddl-default-expression,
# ddl-ident-mixed-case and ddl-ident-special-chars stay right).
#
# WHY: a name the server reads as a keyword ("order", "user", "group", "end")
# makes CREATE TABLE a syntax error; a default the DDL writes raw changes
# meaning ("it's" opens a string, '007' becomes 7). One function names every
# identifier, in the DDL and in the diff ops.

{
  package QuDdl::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');

  package QuDdl::Schema::Result::Order;
  use base 'DBIO::Core';
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer' },
    user  => { data_type => 'varchar', size => 20, is_nullable => 1 },
    group => { data_type => 'varchar', size => 20, is_nullable => 1 },
    end   => { data_type => 'varchar', size => 20, is_nullable => 1 },
    camelCol => { data_type => 'varchar', size => 20, is_nullable => 1 },
    note  => { data_type => 'varchar', size => 20, default_value => "it's" },
    code  => { data_type => 'char', size => 5, default_value => '007' },
    count => { data_type => 'integer', default_value => 7 },
    neg   => { data_type => 'numeric', size => [5,2], default_value => '-1.50' },
    stamp => { data_type => 'timestamp', default_value => \'CURRENT_TIMESTAMP' },
  );
  __PACKAGE__->set_primary_key('id');

  package QuDdl::Schema::Result::Plain;
  use base 'DBIO::Core';
  __PACKAGE__->table('plain');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 20 },
  );
  __PACKAGE__->set_primary_key('id');
}
QuDdl::Schema->register_class(Order     => 'QuDdl::Schema::Result::Order');
QuDdl::Schema->register_class(Plain     => 'QuDdl::Schema::Result::Plain');

my $ddl = DBIO::MSSQL::DDL->install_ddl('QuDdl::Schema');

# the function
is _quote_ident('plain'),     'plain',       'a plain name stays bare';
is _quote_ident('a_b1'),      'a_b1',        '... with digits and underscore';
is _quote_ident('order'),     '[order]',     'a reserved word is bracketed';
is _quote_ident('GROUP'),     '[GROUP]',     '... in any case';
is _quote_ident('End'),       '[End]',       '... and its case is kept';
is _quote_ident('MixedCase'), 'MixedCase',   'mixed case needs no bracket: the server keeps the case of a bare name';
is _quote_ident('other.t'),   '[other.t]',   'a dot is part of the name (of a column or an index; a table with one is refused, t/94)';
is _quote_ident('a b'),       '[a b]',       'a space';
is _quote_ident('we]ird'),    '[we]]ird]',   'a closing bracket is doubled';
is _quote_ident('1abc'),      '[1abc]',      'a leading digit';

# the DDL
like $ddl, qr/CREATE TABLE \[order\] \(/, 'the reserved table name is bracketed';
like $ddl, qr/^  \[user\] nvarchar\(20\)/m,  'column user';
like $ddl, qr/^  \[group\] nvarchar\(20\)/m, 'column group';
like $ddl, qr/^  \[end\] nvarchar\(20\)/m,   'column end';
like $ddl, qr/^  camelCol nvarchar/m,        'mixed case column exact';
like $ddl, qr/PRIMARY KEY \(id\)/,           'a plain name is not bracketed';

# defaults
like $ddl, qr/DEFAULT N'it''s'/,     'apostrophe doubled, national literal for nvarchar';
like $ddl, qr/^  code nchar\(5\) NOT NULL DEFAULT N'007'/m,
  'a digit string with a leading zero stays a string';
unlike $ddl, qr/DEFAULT 007\b/, '... not a number';
like $ddl, qr/DEFAULT 7\b/,     'a number stays raw';
like $ddl, qr/DEFAULT -1\.50\b/, 'a negative decimal string stays raw';
like $ddl, qr/DEFAULT CURRENT_TIMESTAMP/, 'a scalar ref stays an expression';

# the diff ops use the same function
my $t = DBIO::MSSQL::Diff::Table->new(
  action => 'create', table_name => 'order',
  columns => [ { column_name => 'group', data_type => 'nvarchar', size => 20,
                 not_null => 1, is_pk => 1 } ],
  foreign_keys => [],
);
like $t->as_sql, qr/CREATE TABLE \[order\] \(\n  \[group\] nvarchar/, 'Diff::Table create';
is(DBIO::MSSQL::Diff::Table->new(action => 'drop', table_name => 'user')->as_sql,
  'DROP TABLE [user];', 'Diff::Table drop');
like(DBIO::MSSQL::Diff::Index->new(action => 'create', table_name => 'order',
       index_name => 'Idx', index_info => { columns => ['group'] })->as_sql,
  qr/INDEX Idx ON \[order\] \(\[group\]\)/, 'Diff::Index');
like(DBIO::MSSQL::Diff::ForeignKey->new(action => 'add', table_name => 'order',
       constraint_name => 'FK_order_user',
       fk_info => { from_columns => ['user'], to_table => 'group', to_columns => ['end'] })->as_sql,
  qr/ALTER TABLE \[order\] ADD CONSTRAINT FK_order_user FOREIGN KEY \(\[user\]\) REFERENCES \[group\]\(\[end\]\)/,
  'Diff::ForeignKey');

done_testing;

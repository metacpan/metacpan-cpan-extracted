use strict;
use warnings;
use Test::More;

use DBIO::Sybase::DDL;
use DBIO::Sybase::Diff;
use DBIO::Sybase::Diff::Table;
use DBIO::Sybase::Diff::Column;
use DBIO::Sybase::Diff::Index;
use DBIO::Sybase::Diff::ForeignKey;
use DBIO::Sybase::Quote qw(quote_ident is_keyword);

# Identifiers that are ASE keywords (karr k92). `create table dummy (id int)` is
# Msg 156 on ASE: the table of DBIO::Test::Schema::Dummy was written bare,
# because core's _quote_ident leaves a name that looks like an identifier
# alone, and `"name"` is not the way out -- it needs `set quoted_identifier
# on` (Msg 102 without), which a login does not have. [name] parses always.
#
# CLAIM, for every statement the driver writes (DDL and the diff operations):
# a name that is an ASE keyword, or no simple identifier, is written in square
# brackets, with a ] in it doubled, and in no other way (no double quotes); a
# simple name that is no keyword stays bare, as it always was. The keyword
# list is measured, t/96-quote-ident-live.t sends every word of it to a
# server.

# --- the function --------------------------------------------------------
is quote_ident($_), $_, "'$_' is written bare" for qw(artist cd_track _x t1 Name);
is quote_ident('dummy'),  '[dummy]',  'dummy, the keyword that started this, is bracketed';
is quote_ident('DUMMY'),  '[DUMMY]',  '... in any case';
is quote_ident('Order'),  '[Order]',  'order, in any case';
is quote_ident("$_"),     "[$_]",     "$_ is bracketed" for qw(key user index check group view);
is quote_ident('my col'), '[my col]', 'a name with a blank is bracketed';
is quote_ident('a]b'),    '[a]]b]',   '... a ] in it is doubled';
is quote_ident('1abc'),   '[1abc]',   '... one that starts with a digit is bracketed';
is quote_ident('a"b'),    '[a"b]',    '... a double quote is left alone, in brackets';
ok is_keyword('Dummy') && !is_keyword('artist') && !is_keyword('int') && !is_keyword('left'),
  'is_keyword: dummy yes, in any case; a plain name, a type name and an SQL-92 word no';

# --- names ASE refuses even in brackets (karr k92) -------------------------
# # and @ lead a temporary table or a variable (Msg 11717, 16366), a dot reads
# as owner.name (Msg 2734): the quoter says so, naming name and reason, where
# it passed the server's error on.
for my $bad ('#foo', '@v', 'a.b', 'dbo.artist', '[x].y') {
  my $err = eval { quote_ident($bad); 1 } ? '' : "$@";
  isa_ok $@, 'DBIO::Exception' if $err;
  like $err, qr/\ADBIO::Sybase::Quote::quote_ident\(\): DBIO::Sybase: cannot write the name \Q'$bad'\E as an identifier: /,
    "'$bad' is refused, naming the name";
  like $err, qr/(?:starting with # or @|reads a dot as owner\.name)/, '... and the reason';
}
is quote_ident('a#b'), '[a#b]', 'a # inside a name is bracketed, not refused';
{
  package K92::Result::Dotted;
  use base 'DBIO::Core';
  __PACKAGE__->table('main.thing');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  package K92::DottedSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Dotted => 'K92::Result::Dotted');
}
like( (eval { DBIO::Sybase::DDL->install_ddl('K92::DottedSchema'); 1 } ? '' : "$@"),
  qr/cannot write the name 'main\.thing'/, 'install_ddl on a table named with a dot is refused by the quoter' );

# --- DDL ------------------------------------------------------------------
{
  package K92::Result::Dummy;
  use base 'DBIO::Core';
  __PACKAGE__->table('dummy');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer' },
    key   => { data_type => 'varchar', size => 20 },
    user  => { data_type => 'varchar', size => 20, is_nullable => 1 },
    'odd name' => { data_type => 'integer', is_nullable => 1, accessor => 'odd' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(check => ['key']);
  __PACKAGE__->indices(select => ['user']);

  package K92::Result::Order;
  use base 'DBIO::Core';
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer' },
    dummy_id => { data_type => 'integer' },
    index    => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(dummy => 'K92::Result::Dummy', 'dummy_id');

  package K92::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Dummy => 'K92::Result::Dummy');
  __PACKAGE__->register_class(Order => 'K92::Result::Order');
}

{
  my $ddl = DBIO::Sybase::DDL->install_ddl('K92::Schema');

  like $ddl, qr/^CREATE TABLE \[dummy\] \(/m,   'DDL: the table dummy is bracketed';
  like $ddl, qr/^CREATE TABLE \[order\] \(/m,   '... and so is order';
  like $ddl, qr/^  \[key\] VARCHAR\(20\) NOT NULL,$/m, '... a column named key';
  like $ddl, qr/^  \[user\] VARCHAR\(20\) NULL,$/m,    '... a column named user';
  like $ddl, qr/^  \[odd name\] INT NULL/m,             '... a column with a blank';
  like $ddl, qr/^  id INT NOT NULL,$/m,                 '... and id stays bare';
  like $ddl, qr/PRIMARY KEY \(id\)/,                    '... also in the key';
  like $ddl, qr/^CREATE UNIQUE INDEX \[check\] ON \[dummy\] \(\[key\]\);$/m,
    '... a unique constraint named check, on dummy (key)';
  like $ddl, qr/^CREATE INDEX \[select\] ON \[dummy\] \(\[user\]\);$/m,
    '... an index named select';
  like $ddl, qr/^ALTER TABLE \[order\] ADD CONSTRAINT \S+ FOREIGN KEY \(dummy_id\) REFERENCES \[dummy\] \(id\);$/m,
    '... a foreign key from order to dummy';
  unlike $ddl, qr/"/, '... and no double quote anywhere';
  unlike $ddl, qr/(?:TABLE|INDEX|REFERENCES|ON) (?:dummy|order)\b/,
    '... and no keyword bare after TABLE, INDEX, REFERENCES or ON';
}

# --- the diff operations -------------------------------------------------
sub col { my ($n, %o) = @_; +{ column_name => $n, data_type => $o{type} // 'integer', size => $o{size},
  not_null => $o{not_null} // 0, default_value => $o{default}, is_pk => $o{is_pk} // 0 } }

{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    {}, { dummy => { table_name => 'dummy', kind => 'table' } },
    { dummy => [ col('id', not_null => 1, is_pk => 1), col('key', type => 'varchar', size => 5, not_null => 1) ] },
    {},
  );
  like $ops[0]->as_sql, qr/\ACREATE TABLE \[dummy\] \(\n  id INT NOT NULL,\n  \[key\] VARCHAR\(5\) NOT NULL,\n  PRIMARY KEY \(id\)\n\);\z/,
    'Diff Table create: table and column';

  @ops = DBIO::Sybase::Diff::Table->diff(
    { dummy => { table_name => 'dummy', kind => 'table' } }, {}, {}, {},
  );
  is $ops[0]->as_sql, 'DROP TABLE [dummy];', 'Diff Table drop';

  is( DBIO::Sybase::Diff::Table::PrimaryKey::Add->new(
        action => 'add', table_name => 'order', columns => ['key', 'id'])->as_sql,
      'ALTER TABLE [order] ADD PRIMARY KEY ([key], id);', 'Diff primary key add');
  is( DBIO::Sybase::Diff::Table::PrimaryKey::Drop->new(
        action => 'drop', table_name => 'order', constraint_name => 'order_1234', columns => ['id'])->as_sql,
      'ALTER TABLE [order] DROP CONSTRAINT order_1234;', 'Diff primary key drop');
}

{
  my %t = (dummy => { table_name => 'dummy', kind => 'table' });
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { dummy => [ col('id'), col('key', type => 'varchar', size => 5), col('old', default => 1), col('user') ] },
    { dummy => [ col('id'), col('key', type => 'varchar', size => 9), col('select', default => 0, not_null => 1),
                 col('user', default => 3) ] },
    \%t, \%t,
  );
  my $sql = join "\n", map { $_->as_sql } @ops;
  like $sql, qr/^ALTER TABLE \[dummy\] ADD \[select\] INT DEFAULT 0 NOT NULL;$/m, 'Diff column add';
  like $sql, qr/^ALTER TABLE \[dummy\] MODIFY \[key\] VARCHAR\(9\) NULL;$/m,       'Diff column modify';
  like $sql, qr/^ALTER TABLE \[dummy\] REPLACE \[user\] DEFAULT 3;$/m,             'Diff column replace (default only)';
  like $sql, qr/^ALTER TABLE \[dummy\] DROP old;$/m,                               'Diff column drop (old is no keyword)';
  unlike $sql, qr/"/, '... no double quote';

  @ops = DBIO::Sybase::Diff::Column->diff(
    { dummy => [ col('id'), col('key') ] }, { dummy => [ col('id') ] }, \%t, \%t);
  is $ops[0]->as_sql, 'ALTER TABLE [dummy] DROP [key];', 'Diff column drop of a keyword';
}

{
  my $idx = sub { +{ index_name => $_[0], is_unique => $_[1], columns => $_[2] } };
  my @ops = DBIO::Sybase::Diff::Index->diff(
    { dummy => { check => $idx->(check => 0, ['key']), select => $idx->(select => 0, ['user']) } },
    { dummy => { check => $idx->(check => 1, ['key']), group  => $idx->(group => 1, [qw(key user)]) } },
  );
  my %by = map { ref($_) =~ /::(\w+)\z/; $1 => $_->as_sql } @ops;
  is $by{Create}, 'CREATE UNIQUE INDEX [group] ON [dummy] ([key], [user]);', 'Diff index create';
  is $by{Alter},  'DROP INDEX [dummy].[check]; CREATE UNIQUE INDEX [check] ON [dummy] ([key]);', 'Diff index alter';
  is $by{Drop},   'DROP INDEX [dummy].[select];', 'Diff index drop';
}

{
  my $fk = { from_columns => ['key'], to_table => 'order', to_columns => ['index'], constraint_name => 'fk_x' };
  is( DBIO::Sybase::Diff::ForeignKey::Create->new(action => 'create', table => 'dummy', fk => $fk)->as_sql,
      'ALTER TABLE [dummy] ADD CONSTRAINT fk_x FOREIGN KEY ([key]) REFERENCES [order] ([index]);',
      'Diff foreign key create' );
  is( DBIO::Sybase::Diff::ForeignKey::Drop->new(action => 'drop', table => 'dummy', fk => $fk)->as_sql,
      'ALTER TABLE [dummy] DROP CONSTRAINT fk_x;', 'Diff foreign key drop' );
}

done_testing;

use strict;
use warnings;
use Test::More;

# Offline: a string default is a SQL literal, and an apostrophe in it is
# doubled (karr k47).
#
# install_ddl used to write `DEFAULT '$dv'` with the value as it came, so
# default_value => "it's" produced `DEFAULT 'it's'`, which the server refuses,
# and a value holding `'); ...` ended the literal and went on as SQL. A scalar
# ref is literal SQL by contract and stays as written.
#
# The Diff ops are a different case and are pinned here too: their
# default_value comes from the introspected model, i.e. it is the server's
# rdb$default_source text and already a SQL literal ('it''s' with its quotes).
# Quoting it again there would double the quotes; the ops must pass it through.

use DBIO::Firebird::DDL qw(_firebird_default_literal);
use DBIO::Firebird::Diff::Table;
use DBIO::Firebird::Diff::Column;

{
  package DBIO::Firebird::Test::K47Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw/Artist/] });
}

my $schema = 'DBIO::Firebird::Test::K47Schema';
my $info   = $schema->source('Artist')->column_info('name');

# --- the helper ---------------------------------------------------------------
is(_firebird_default_literal('foo'), q{'foo'}, 'plain string: quoted');
is(_firebird_default_literal(13),    q{'13'},  'number: quoted as before (the server converts)');
is(_firebird_default_literal(q{it's}), q{'it''s'}, 'apostrophe is doubled');
is(_firebird_default_literal(q{a'); DROP TABLE x; --}), q{'a''); DROP TABLE x; --'},
  'a would-be terminator stays inside the literal');
is(_firebird_default_literal(q{'}), q{''''}, 'a lone apostrophe');
is(_firebird_default_literal(\'CURRENT_TIMESTAMP'), 'CURRENT_TIMESTAMP',
  'scalar ref: literal SQL, unchanged');

# --- install_ddl --------------------------------------------------------------
{
  local $info->{default_value} = q{it's};
  like(DBIO::Firebird::DDL->install_ddl($schema),
    qr/^  "name" VARCHAR\(100\) DEFAULT 'it''s',?$/m,
    'install_ddl: default "it\'s" is written as \'it\'\'s\'');
}
{
  local $info->{default_value} = \q{'lit'};
  like(DBIO::Firebird::DDL->install_ddl($schema),
    qr/^  "name" VARCHAR\(100\) DEFAULT 'lit',?$/m,
    'install_ddl: a scalar-ref default is untouched');
}

# --- boolean: 0 / 1 / 'true' / 'false' are TRUE / FALSE, the rest is refused (karr k36)
# Firebird 5.0.4 accepts DEFAULT '0' / '1' / 0 / 1 on a BOOLEAN in CREATE TABLE
# and fails every insert that uses it (t/26-boolean-live.t measures it); it
# takes 'true' / 'false' and TRUE / FALSE. Any other value would be the same
# trap, so it is refused when the DDL is generated.
{
  my $b = { data_type => 'boolean' };
  is(_firebird_default_literal($_->[0], $b), $_->[1], "boolean default $_->[0]")
    for [ 0 => 'FALSE' ], [ 1 => 'TRUE' ], [ '0' => 'FALSE' ], [ '1' => 'TRUE' ],
        [ \'0' => 'FALSE' ], [ \'1' => 'TRUE' ],
        [ 'true' => 'TRUE' ], [ 'FALSE' => 'FALSE' ], [ 'True' => 'TRUE' ], [ 'fAlSe' => 'FALSE' ],
        [ \'true' => 'TRUE' ];
  is(_firebird_default_literal(\'(1 = 1)', $b), '(1 = 1)', 'a scalar ref holding other SQL is SQL as written');
  for my $bad ('f', '', 'yes', 2, 'no', 't', ' 1', '0 ', 'null') {
    my $r = eval { _firebird_default_literal($bad, $b, "column 'x' on 't'"); 1 };
    ok !$r && $@ =~ /column 'x' on 't': default_value '\Q$bad\E' on a boolean column is none of 0, 1, 'true', 'false'/,
      "boolean default '$bad' is refused, naming the column";
    isa_ok $@, 'DBIO::Exception' unless $r;
  }
  is(_firebird_default_literal(0, { data_type => 'integer' }), q{'0'},
    'a non-boolean column keeps the quoted literal');
}
{
  local $info->{data_type} = 'boolean';
  local $info->{default_value} = 0;
  like(DBIO::Firebird::DDL->install_ddl($schema),
    qr/^  "name" BOOLEAN DEFAULT FALSE,?$/m, 'install_ddl: boolean default 0 is DEFAULT FALSE');
  local $info->{default_value} = 'True';
  like(DBIO::Firebird::DDL->install_ddl($schema),
    qr/^  "name" BOOLEAN DEFAULT TRUE,?$/m, "install_ddl: boolean default 'True' is DEFAULT TRUE");
  local $info->{default_value} = 'f';
  eval { DBIO::Firebird::DDL->install_ddl($schema) };
  like $@, qr/column 'name' on 'artist': default_value 'f' on a boolean column/, "install_ddl: boolean default 'f' dies, naming column and table";
}

# --- Diff ops take the introspected literal as it is --------------------------
my $lit = q{'it''s'};
my $create = DBIO::Firebird::Diff::Table->new(
  action => 'create', table_name => 't',
  columns => [{ column_name => 'note', data_type => 'varchar', size => 20,
                default_value => $lit }],
  foreign_keys => [],
);
like($create->as_sql, qr/"note" varchar\(20\) DEFAULT 'it''s'/,
  'Diff::Table create: the introspected literal is not quoted a second time');

my $add = DBIO::Firebird::Diff::Column->new(
  action => 'add', table_name => 't', column_name => 'note',
  new_info => { data_type => 'varchar', size => 20, default_value => $lit },
);
like($add->as_sql, qr/ADD "note" varchar\(20\) DEFAULT 'it''s';/,
  'Diff::Column add: same');

my $alter = DBIO::Firebird::Diff::Column->new(
  action => 'alter', table_name => 't', column_name => 'note',
  old_info => { data_type => 'varchar', size => 20, default_value => q{'x'} },
  new_info => { data_type => 'varchar', size => 20, default_value => $lit },
);
like($alter->as_sql, qr/SET DEFAULT 'it''s';/, 'Diff::Column alter: same');

done_testing;

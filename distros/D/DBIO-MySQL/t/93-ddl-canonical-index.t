use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# karr k97 (core k333, ADR 0061): idx and indices write the index declaration
# canonically onto the result source. install_ddl used to read only
# mysql_indexes, so a Cake class with idx/indices got its CREATE TABLE and no
# index at all, silently. The Diff deploys its target model through
# install_ddl into a temp database (DBIO::MySQL::Deploy), so the statements
# asserted here are the ones an upgrade creates.

sub index_stmts {
  my ($schema) = @_;
  my $ddl = DBIO::MySQL::DDL->install_ddl($schema);
  my %by_name;
  for my $stmt (split /\n\n/, $ddl) {
    next unless $stmt =~ /^CREATE\b.*?\bINDEX\s+`(\w+)`\s/;
    $by_name{$1} = $stmt;
  }
  return \%by_name;
}

{
  package CanonIdx::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package CanonIdx::Schema::Result::Doc;
  use DBIO::Cake;
  __PACKAGE__->load_components("MySQL::Result");

  table 'docs';
  col id    => integer auto_inc;
  col bio   => text;
  col name  => varchar(64);
  col slug  => varchar(64);
  primary_key 'id';

  idx idx_name    => ['name'];
  idx idx_slug_u  => ['slug'], type => 'unique';
  idx idx_bio_ft  => ['bio'], mysql => { using => 'FULLTEXT' };
  idx idx_name_bt => ['name', 'slug'], mysql => { using => 'BTREE' };
  __PACKAGE__->indices(idx_ind => ['slug', 'name']);

  # Hand-declared, no canonical twin: stays valid.
  __PACKAGE__->mysql_index(idx_hand => { columns => ['slug'] });
  # Hand-declared and canonical under one name: canonical wins.
  __PACKAGE__->mysql_index(idx_both => { columns => ['slug'], unique => 1 });
  idx idx_both => ['name'];
}
CanonIdx::Schema->register_class(Doc => 'CanonIdx::Schema::Result::Doc');

my $i = index_stmts('CanonIdx::Schema');

is $i->{idx_name},   'CREATE INDEX `idx_name` ON `docs` (`name`);',
  'idx without options produces a CREATE INDEX in install_ddl';
is $i->{idx_slug_u}, 'CREATE UNIQUE INDEX `idx_slug_u` ON `docs` (`slug`);',
  "type => 'unique' renders CREATE UNIQUE INDEX";
is $i->{idx_bio_ft}, 'CREATE FULLTEXT INDEX `idx_bio_ft` ON `docs` (`bio`);',
  'mysql => { using => FULLTEXT } renders the index class';
is $i->{idx_name_bt}, 'CREATE INDEX `idx_name_bt` ON `docs` (`name`, `slug`) USING BTREE;',
  'mysql => { using => BTREE } renders a trailing USING clause';
is $i->{idx_ind},    'CREATE INDEX `idx_ind` ON `docs` (`slug`, `name`);',
  'indices produces a CREATE INDEX too';
is $i->{idx_hand},   'CREATE INDEX `idx_hand` ON `docs` (`slug`);',
  'a hand-declared mysql_index stays valid';
is $i->{idx_both},   'CREATE INDEX `idx_both` ON `docs` (`name`);',
  'on the same name the canonical declaration wins over mysql_index';

# Refusals come from the core reader and must reach the caller.
{
  package CanonIdx::Foreign;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package CanonIdx::Foreign::Result::Doc;
  use DBIO::Cake;
  __PACKAGE__->load_components("MySQL::Result");
  table 'docs';
  col id   => integer auto_inc;
  col name => varchar(64);
  primary_key 'id';
  idx only_pg => ['name'], pg => { where => 'name is not null' };
}
CanonIdx::Foreign->register_class(Doc => 'CanonIdx::Foreign::Result::Doc');

eval { DBIO::MySQL::DDL->install_ddl('CanonIdx::Foreign') };
like $@, qr/only_pg.*'pg'.*none for 'mysql'/s,
  'an entry carrying only a foreign driver block is refused, naming the index';

{
  package CanonIdx::Unknown;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package CanonIdx::Unknown::Result::Doc;
  use DBIO 'Core', -mysql;
  __PACKAGE__->table('docs');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 64 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'bad_key', columns => ['name'], driver => { mysql => { parser => 'ngram' } },
  });
}
CanonIdx::Unknown->register_class(Doc => 'CanonIdx::Unknown::Result::Doc');

eval { DBIO::MySQL::DDL->install_ddl('CanonIdx::Unknown') };
like $@, qr/bad_key.*parser/s,
  'an unknown key in the own mysql block is refused, naming index and key';

done_testing;

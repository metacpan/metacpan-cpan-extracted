use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::DDL;

# A schema is bound to one driver, and the index declaration is per driver
# (karr core k333): install_ddl refuses, loudly and at once, what it would
# otherwise drop silently -- options, a type other than unique, an entry that
# carries only another driver's block, a key the pg block does not know.
# An own, empty pg block is the plain index of the columns.

my $n = 0;
sub ddl_for {
  my ($decl, @extra) = @_;
  my $pkg = 'IdxRefuse' . ++$n;
  eval "package ${pkg}::Schema; use base q(DBIO::Schema); "
     . "package ${pkg}::Schema::Result::T; use base q(DBIO::Core); 1"
    or die $@;
  my $schema = "${pkg}::Schema";
  my $result = "${pkg}::Schema::Result::T";
  $schema->load_components('PostgreSQL');
  $result->load_components('PostgreSQL::Result');
  $result->table('t');
  $result->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    kind => { data_type => 'text' },
  );
  $result->set_primary_key('id');
  $result->result_source_instance->add_index_declaration($decl);
  $schema->register_class(T => $result);
  return DBIO::PostgreSQL::DDL->install_ddl($schema);
}

# --- accepted
like ddl_for({ name => 'i1', columns => ['name'], driver => { pg => {} } }),
  qr/^CREATE INDEX i1 ON t \(name\);$/m, 'an empty own pg block: the plain index';
like ddl_for({ name => 'i2', columns => ['name'], type => 'unique' }),
  qr/^CREATE UNIQUE INDEX i2 ON t \(name\);$/m, 'type unique';
like ddl_for({ name => 'i3', columns => ['name'], type => 'UNIQUE',
    driver => { sqlite => { where => 'x' }, pg => { using => 'hash' } } }),
  qr/^CREATE UNIQUE INDEX i3 ON t USING hash \(name\);$/m,
  'a pg block beside another driver is read';
like ddl_for({ name => 'i4', columns => ['name'] }),
  qr/^CREATE INDEX i4 ON t \(name\);$/m, 'no driver block at all: the plain index';

# --- refused
throws_ok { ddl_for({ name => 'o1', columns => ['name'], options => { parser => 'ngram' } }) }
  qr/index 'o1'.*\boptions\b/s, 'options are refused';

throws_ok { ddl_for({ name => 'ty', columns => ['kind'], type => 'fulltext' }) }
  qr/index 'ty'.*\btype\b.*fulltext/s, 'a type other than unique is refused';

throws_ok { ddl_for({ name => 'lo', columns => ['name'],
    driver => { sqlite => { where => "kind = 'a'" } } }) }
  qr/index 'lo' carries only the 'sqlite' block and none for 'pg'/,
  'only a sqlite block is refused';

throws_ok { ddl_for({ name => 'my', columns => ['name'], unique => 1,
    driver => { mysql => { using => 'hash' } } }) }
  qr/index 'my' carries only the 'mysql' block/, 'only a mysql block is refused';

throws_ok { ddl_for({ name => 'bk', columns => ['name'],
    driver => { pg => { usng => 'gin' } } }) }
  qr/index 'bk': unknown key 'usng' in its 'pg' block/,
  'an unknown key in the pg block is refused';

throws_ok { ddl_for({ name => 'wk', columns => ['name'],
    driver => { pg => { unique => 1 } } }) }
  qr/unknown key 'unique'/, 'unique is the entry\'s, not a pg key';

done_testing;

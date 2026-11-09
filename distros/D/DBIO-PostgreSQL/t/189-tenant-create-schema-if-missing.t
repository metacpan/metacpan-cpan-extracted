use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff::Schema;
use DBIO::PostgreSQL::Diff::Extension;
use DBIO::PostgreSQL::Util qw(create_schema_if_missing);

# OFFLINE test for karr k131 (d): a schema a connection with the connect key
# schema creates is looked up in pg_namespace first.
#
# CLAIM: CREATE SCHEMA [IF NOT EXISTS] checks CREATE on the database even when
# the namespace is there, so a tenant role without that privilege could not
# install into a namespace an administrator made for it. The script and the
# diff of such a connection therefore write the schema only where
# pg_namespace does not have it: a DO block with an existence check. Without
# the key nothing changes (CREATE SCHEMA IF NOT EXISTS, as before).
#
# WHAT RUNS FOR REAL: Util::create_schema_if_missing, DDL->install_ddl,
# Diff::Schema and Diff::Extension as_sql. THE SUBSTITUTION: no server.
# Live half: t/190-tenant-create-schema-if-missing-live.t.

my @LOGIN = ('dbi:Pg:dbname=k131_offline', 'u', 'p');

my $n = 0;
sub schema_class {
  my $pkg = 'K131D::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_schemas(@{ $_[0] });
  $pkg->pg_extensions(@{ $_[1] });
  return $pkg;
}

# the statement
{
  my $sql = create_schema_if_missing('tenant_a');
  like $sql, qr/\ADO \$(\w+)\$\n.*\n\$\1\$\z/s, 'a DO block, one piece';
  like $sql, qr/pg_catalog\.pg_namespace WHERE nspname = 'tenant_a'/,
    '... that asks pg_namespace for the name';
  like $sql, qr/THEN\s+CREATE SCHEMA tenant_a;\s+END IF/,
    '... and creates the schema where it is not';
  unlike $sql, qr/IF NOT EXISTS tenant_a/, '... without IF NOT EXISTS, which is the check that needs CREATE';

  my $odd = create_schema_if_missing(q{Ten'ant});
  like $odd, qr/nspname = 'Ten''ant'/, 'the name is a literal in the check ...';
  like $odd, qr/CREATE SCHEMA "Ten'ant";/, '... and an identifier in the statement';
  my $tag = create_schema_if_missing('a$dbio$b');
  like $tag, qr/\ADO \$(?!dbio\$)\w+\$/, 'a name that holds the dollar tag gets another tag';
}

# install script
{
  my $class = schema_class([ 'extensions' ], [ 'hstore', vector => { schema => 'extensions' } ]);
  my $schema = $class->connect(@LOGIN, { schema => 'tenant_a' });
  my $sql = DBIO::PostgreSQL::DDL->install_ddl($schema);
  my @blocks = $sql =~ /^(DO \$\w+\$\n.*?\n\$\w+\$);$/msg;
  my @created = map { /CREATE SCHEMA (\w+);/ } grep { /pg_namespace/ } @blocks;
  is_deeply [ sort @created ], [ 'extensions', 'tenant_a' ],
    'the install script of a connection with the key: the namespace and the schema of the extension';
  unlike $sql, qr/CREATE SCHEMA IF NOT EXISTS/, '... and no CREATE SCHEMA IF NOT EXISTS is left';

  my $plain = DBIO::PostgreSQL::DDL->install_ddl($class->connect(@LOGIN));
  like $plain, qr/^CREATE SCHEMA IF NOT EXISTS extensions;$/m,
    'without the key the script is what it was';
  unlike $plain, qr/pg_namespace/, '... no lookup';
}

# diff operations
{
  my $op = DBIO::PostgreSQL::Diff::Schema->new(action => 'create', schema_name => 'x');
  is $op->as_sql, 'CREATE SCHEMA x;', 'a schema operation by itself is as it was';

  my @ops = DBIO::PostgreSQL::Diff::Schema->diff({}, { tenant_a => { create_if_missing => 1 }, plain => {} });
  my %sql = map { $_->schema_name => $_->as_sql } @ops;
  like $sql{tenant_a}, qr/pg_namespace WHERE nspname = 'tenant_a'/, 'the diff creates a marked schema with the lookup';
  is $sql{plain}, 'CREATE SCHEMA plain;', '... an unmarked one as before';
}
{
  my $deploy = DBIO::PostgreSQL::Deploy->new(
    schema => schema_class([], [])->connect(@LOGIN, { schema => 'tenant_a' }));
  my $model = $deploy->_mark_namespace({ schemas => { tenant_a => {}, other => {} } });
  ok $model->{schemas}{tenant_a}{create_if_missing}, 'the deploy marks the namespace of its connection';
  ok !$model->{schemas}{other}{create_if_missing}, '... and no other schema';
}
{
  my $info = { declared_schema => 'extensions', create_schema => 1 };
  my $op = DBIO::PostgreSQL::Diff::Extension->new(action => 'create', extension_name => 'vector', extension_info => $info);
  like $op->as_sql, qr/\ADO .*nspname = 'extensions'.*\n\$\w+\$;\nCREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;\z/s,
    'the diff of an extension with create_schema: lookup, then CREATE EXTENSION';
}

done_testing;

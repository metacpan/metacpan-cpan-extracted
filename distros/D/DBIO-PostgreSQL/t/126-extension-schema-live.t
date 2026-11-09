use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k120, point 8 -- pg_extensions names the schema of an extension:
#
#   pg_extensions(pg_trgm => { schema => 'ext_a' })
#
# CREATE EXTENSION ... WITH SCHEMA on install; ALTER EXTENSION ... SET SCHEMA
# on upgrade for a relocatable extension; a refusal, when the diff is built,
# for one that is not relocatable. A list that names no schema never moves an
# extension. Runs in a database of its own: it installs, moves and drops
# extensions.

{
  my $h = LiveServer->control_dbh;
  my %avail = map { $_ => 1 } @{ $h->selectcol_arrayref(
    q{SELECT name FROM pg_catalog.pg_available_extensions WHERE name = 'pg_trgm'}
  ) };
  $h->disconnect;
  plan skip_all => 'extension pg_trgm not available on the server'
    unless $avail{pg_trgm};
}

($dsn, $user, $pass) = PrivatePgDatabase->create('t126');

{
  package K120E::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('k120e_widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
}

my $n = 0;
sub schema_class {
  my ($schemas, @extensions) = @_;
  my $pkg = 'K120E::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_schemas(@$schemas);
  $pkg->pg_extensions(@extensions);
  $pkg->register_class(Widget => 'K120E::Result::Widget');
  return $pkg;
}
sub deploy_for {
  my ($class) = @_;
  return DBIO::PostgreSQL::Deploy->new(schema => $class->connect($dsn, $user, $pass));
}

my $dbh = LiveServer->control_dbh(login => [ $dsn, $user, $pass ]);
sub ext_schema {
  my ($name) = @_;
  return scalar $dbh->selectrow_array(
    q{SELECT n.nspname FROM pg_catalog.pg_extension e
        JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
       WHERE e.extname = ?}, undef, $name);
}
sub ext_actions {
  my ($diff) = @_;
  return {
    map { $_->extension_name => $_->action }
    grep { $_->isa('DBIO::PostgreSQL::Diff::Extension') } @{ $diff->operations }
  };
}

subtest 'install: CREATE EXTENSION ... WITH SCHEMA' => sub {
  my $deploy = deploy_for(schema_class([ 'public', 'ext_a' ], pg_trgm => { schema => 'ext_a' }));
  lives_ok { $deploy->install } 'install lives (the schema is there ahead of the extension)';
  is ext_schema('pg_trgm'), 'ext_a', 'pg_trgm is installed in ext_a';
  my $again = $deploy->diff;
  ok !$again->has_changes, 'a diff after the install has nothing to do'
    or diag $again->as_sql;
};

subtest 'upgrade: a relocatable extension is moved' => sub {
  my $deploy = deploy_for(schema_class([ 'public', 'ext_a', 'ext_b' ], pg_trgm => { schema => 'ext_b' }));
  my $diff = $deploy->diff;
  is_deeply ext_actions($diff), { pg_trgm => 'move' }, 'the diff moves pg_trgm'
    or diag $diff->as_sql;
  like $diff->as_sql, qr/ALTER EXTENSION pg_trgm SET SCHEMA ext_b;/, '... by SET SCHEMA';
  lives_ok { $deploy->apply($diff) } 'apply lives';
  is ext_schema('pg_trgm'), 'ext_b', 'pg_trgm is in ext_b now';
  ok !$deploy->diff->has_changes, 'a second diff has nothing left to do';
};

subtest 'no pg_schemas list: a schema only the extension names is refused' => sub {
  my $pkg = 'K120E::NoList';
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_extensions(pg_trgm => { schema => 'ext_f' });
  throws_ok { deploy_for($pkg)->diff }
    qr/refusing to write the install DDL.*pg_trgm.*ext_f.*pg_schemas/s,
    'refused, naming extension and schema';
};

subtest 'the list form names no schema and never moves' => sub {
  my $deploy = deploy_for(schema_class([ 'public', 'ext_a', 'ext_b' ], 'pg_trgm'));
  my $diff = $deploy->diff;
  ok !exists ext_actions($diff)->{pg_trgm}, 'no operation on pg_trgm'
    or diag $diff->as_sql;
  is ext_schema('pg_trgm'), 'ext_b', '... it stays in ext_b';
};

subtest 'a restricted deploy moves too, and still drops no extension' => sub {
  $dbh->do('CREATE EXTENSION IF NOT EXISTS hstore');   # undeclared, not dropped (k89)
  my $class = schema_class([ 'public', 'ext_c' ], pg_trgm => { schema => 'ext_c' });
  my $deploy = deploy_for($class);
  my $diff = $deploy->diff;
  is_deeply ext_actions($diff), { pg_trgm => 'move' },
    'move for pg_trgm and nothing for the undeclared hstore'
    or diag $diff->as_sql;
  lives_ok { $deploy->upgrade } 'upgrade lives';
  is ext_schema('pg_trgm'), 'ext_c', 'pg_trgm is in ext_c';
  ok defined ext_schema('hstore'), 'hstore is still installed';
};

subtest 'a schema pg_schemas does not declare is refused' => sub {
  my $class = schema_class([ 'public' ], pg_trgm => { schema => 'ext_d' });
  throws_ok { deploy_for($class)->diff }
    qr/refusing to write the install DDL.*pg_trgm.*ext_d/s,
    'refused, naming extension and schema';
};

subtest 'an extension that is not relocatable is refused' => sub {
  # Not relocatable, and not bound to one schema by its control file: it can
  # be created in public here and the declaration names another.
  my $name = $dbh->selectrow_array(
    q{SELECT name FROM pg_catalog.pg_available_extension_versions
       WHERE NOT relocatable AND schema IS NULL AND name != 'plpgsql'
         AND NOT installed ORDER BY name LIMIT 1});
  plan skip_all => 'no non-relocatable extension with a free schema on this server'
    unless defined $name;
  note "using non-relocatable extension $name";

  my $quoted = $dbh->quote_identifier($name);
  eval { $dbh->do("CREATE EXTENSION $quoted WITH SCHEMA public"); 1 }
    or plan skip_all => "cannot create $name here: " . ($@ =~ s/\s+$//r);

  my $class = schema_class([ 'public', 'ext_e' ], $name => { schema => 'ext_e' });
  throws_ok { deploy_for($class)->diff }
    qr/refusing to diff: extension \Q$name\E .*public.*ext_e.*not relocatable/s,
    'diff() refuses, naming extension and both schemas';
  is ext_schema($name), 'public', '... and nothing was moved';
};

$dbh->disconnect;

done_testing;

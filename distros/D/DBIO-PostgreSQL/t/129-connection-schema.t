use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff::Extension;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Util ();

# OFFLINE test for karr k128: the connect key 'schema' on PostgreSQL.
#
#   MyApp::DB->connect($dsn, $user, $pass, { schema => 'tenant_a' })
#
# CLAIM: one schema class serves any number of namespaces, and which one is
# said by the connection alone. The class names no namespace: its tables are
# written without one, and the connection's search_path puts them into its
# namespace. So everything that decides WHERE has to come from the connection,
# for this instance only:
#
#   1. the search_path of every connection -- the sync one and each pool
#      connection -- is the namespace, then the schemas of the declared
#      extensions (public for one that names none; public when none is
#      declared), set before any connect action of the application;
#   2. the install script of such a connection carries itself: the extensions
#      WITH SCHEMA, never in the namespace; CREATE SCHEMA for the namespace;
#      the search_path ahead of the first unqualified object and again as the
#      last statement. PostgreSQL puts an unqualified object into the first
#      schema of the path that EXISTS -- with the namespace missing that is
#      public, without a word -- and the temporary database of a diff is
#      reached by a connection no connect action runs on;
#   3. the deploy of the instance is restricted to the namespace, and a
#      CREATE EXTENSION its diff writes names its schema;
#   4. a declaration that names a namespace of its own (pg_schema, a dotted
#      table name, a pg_schema_class binding) is refused on such a connection,
#      and so is an extension that would go into the namespace;
#   5. nothing of this is written into the class: the same class is connected
#      for tenant_a and tenant_b at once, and without the key it installs what
#      it installed before.
#
# WHAT RUNS FOR REAL: connect_info with the key, the driver's seam
# _set_connection_schema reached through core's _run_connection_actions and
# _run_pool_connect_actions, _do_query, install_ddl, Deploy->_schema_filter
# and ->diff. THE SUBSTITUTIONS: no server -- the sync handle is an object
# that logs do(), the pool connection is the runner core hands the statements
# to, and the two models of a diff are given.

my @LOGIN = ('dbi:Pg:dbname=k128_offline', 'u', 'p');

{
  package K128::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('things');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_index(idx_things_name => { columns => ['name'] });
}
{
  package K128::Result::InAuth;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package K128::Result::Dotted;
  use base 'DBIO::Core';
  __PACKAGE__->table('shared.countries');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package K128::PgSchema::Auth;
  use base 'DBIO::PostgreSQL::PgSchema';
  __PACKAGE__->pg_enum(role_type => [qw( admin user )]);
}

my $n = 0;
sub schema_class {
  my (%o) = @_;
  my $pkg = 'K128::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL') unless $o{no_component};
  $pkg->pg_schemas(@{ $o{schemas} })           if $o{schemas};
  $pkg->pg_extensions(@{ $o{extensions} })     if $o{extensions};
  $pkg->pg_search_path(@{ $o{search_path} })   if $o{search_path};
  $pkg->pg_schema_class(@{ $o{schema_class} }) if $o{schema_class};
  my %sources = %{ $o{sources} // { Thing => 'K128::Result::Thing' } };
  $pkg->register_class($_ => $sources{$_}) for sort keys %sources;
  return $pkg;
}
sub in_namespace {
  my ($class, $namespace, %attrs) = @_;
  return $class->connect(@LOGIN, { schema => $namespace, %attrs });
}
sub script { DBIO::PostgreSQL::DDL->install_ddl($_[0]) }
sub statements { (my $sql = script($_[0])) =~ s/\n\z//; [ split /\n\n/, $sql ] }
sub filter_of  { scalar DBIO::PostgreSQL::Deploy->new(schema => $_[0])->_schema_filter }
sub pos_of { my ($sql, $re) = @_; $sql =~ $re ? $-[0] : undef }

# ---------------------------------------------------------------------------
# The rule of the path, said once.
# ---------------------------------------------------------------------------

for my $case (
  [ 'no extension declared: the namespace, then public',
    [ 'tenant_a', [], {} ], [qw( tenant_a public )] ],
  [ 'an extension that names no schema stands for public',
    [ 'tenant_a', [ 'vector' ], {} ], [qw( tenant_a public )] ],
  [ 'every extension in a schema of its own: no public',
    [ 'tenant_a', [ 'vector', 'pgcrypto' ], { vector => 'extensions', pgcrypto => 'extensions' } ],
    [qw( tenant_a extensions )] ],
  [ 'mixed: each schema once, in the order of the extensions',
    [ 'tenant_a', [ 'pgcrypto', 'vector', 'hstore' ], { vector => 'extensions' } ],
    [qw( tenant_a public extensions )] ],
  [ 'the namespace stands once, in front',
    [ 'public', [ 'vector' ], {} ], [qw( public )] ],
) {
  my ($what, $args, $want) = @$case;
  my @got = eval { DBIO::PostgreSQL::Util::connection_search_path(@$args) };
  is_deeply \@got, $want, "path: $what" or diag $@;
}

# ---------------------------------------------------------------------------
# 1. The seam: every connection gets the path, ahead of the application's own
#    connect actions.
# ---------------------------------------------------------------------------

{
  package K128::Handle;
  sub new { bless { log => [] }, $_[0] }
  sub do  { push @{ $_[0]{log} }, $_[1]; '0E0' }
  # karr k142: the control schemas of an extension without a declared schema
  # are asked for; a server that knows none of them answers no rows (public)
  sub selectall_arrayref { [] }
}

# The statements the sync connection is sent when it is set up.
sub sync_setup {
  my ($schema) = @_;
  my $storage = $schema->storage;
  my $handle  = K128::Handle->new;
  $storage->_dbh($handle);
  $storage->_conn_pid($$);
  local $storage->{_in_do_block} = 1;   # dbh_do hands the handle on as it is
  my $ok  = eval { $storage->_run_connection_actions; 1 };
  my $err = $@;
  $storage->_dbh(undef);
  return $ok ? $handle->{log} : "died: $err";
}

# The statements a pool connection is sent when it is set up.
sub pool_setup {
  my ($schema) = @_;
  my @sent;
  return "died: $@"
    unless eval { $schema->storage->_run_pool_connect_actions(sub {
        # the control-schema question (karr k142) is no statement sent; no rows
        return [] if $_[0] =~ /pg_available_extension_versions/;
        push @sent, $_[0];
      }); 1 };
  return \@sent;
}

{
  my $class = schema_class();
  my $schema = in_namespace($class, 'tenant_a', on_connect_do => [ 'SET TIME ZONE UTC' ]);

  is $schema->storage->connection_schema, 'tenant_a', 'the key is on the storage';
  isa_ok $schema->storage, 'DBIO::PostgreSQL::Storage', '... which is the driver the class declared';

  is_deeply sync_setup($schema),
    [ 'SET search_path TO tenant_a, public', 'SET TIME ZONE UTC' ],
    'sync connection: the path of the namespace, then the application\'s on_connect_do';
  is_deeply pool_setup($schema),
    [ 'SET search_path TO tenant_a, public', 'SET TIME ZONE UTC' ],
    'pool connection: the same statements, on the pool connection';
}
{
  my $class = schema_class(
    schemas    => [ 'extensions' ],
    extensions => [ 'pgcrypto', vector => { schema => 'extensions' } ],
  );
  is_deeply sync_setup(in_namespace($class, 'tenant_a')),
    [ 'SET search_path TO tenant_a, public, extensions' ],
    'the schemas of the declared extensions follow the namespace';
  is_deeply pool_setup(in_namespace($class, 'tenant_b')),
    [ 'SET search_path TO tenant_b, public, extensions' ],
    '... for another connection of the same class its own namespace';
}
{
  my $class = schema_class(extensions => [ vector => { schema => 'Ext' } ], schemas => [ 'Ext' ]);
  is_deeply pool_setup(in_namespace($class, 'Tenant-A')),
    [ 'SET search_path TO "Tenant-A", "Ext"' ],
    'the names are written as identifiers, by the rule of every other name';
}
{
  my $class = schema_class(no_component => 1);
  $class->storage_type('+DBIO::PostgreSQL::Storage');
  is_deeply pool_setup(in_namespace($class, 'tenant_a')),
    [ 'SET search_path TO tenant_a, public' ],
    'a schema without the component declares no extension: the namespace, then public';
}
{
  my $storage = DBIO::PostgreSQL::Storage->new;
  $storage->connect_info([ @LOGIN, { schema => 'tenant_a' } ]);
  my @sent;
  eval { $storage->_run_pool_connect_actions(sub { push @sent, $_[0] }); 1 } or diag $@;
  is_deeply \@sent, [ 'SET search_path TO tenant_a, public' ],
    'a storage without a schema class: the namespace, then public';
}
{
  my $schema = schema_class()->connect(@LOGIN);
  is_deeply pool_setup($schema), [],
    'a connection without the key is sent no search_path';
}

# ---------------------------------------------------------------------------
# 2. The install script of a connection with a namespace carries itself.
# ---------------------------------------------------------------------------

{
  my $class  = schema_class(search_path => [qw( auth public )]);
  my $stmts  = statements(in_namespace($class, 'tenant_a'));
  my $sql    = join "\n\n", @$stmts;

  like $stmts->[0], qr/\ADO .*nspname = 'tenant_a'.*CREATE SCHEMA tenant_a;/s,
    'the namespace is created, first of all';
  is $stmts->[1], 'SET search_path TO tenant_a, public;',
    '... and the path set behind it, ahead of every object';
  like $stmts->[2], qr/\ACREATE TABLE things \(/,
    '... the table is written without a namespace';
  like $sql, qr/^CREATE INDEX idx_things_name ON things /m, '... and so is its index';
  is scalar(grep { /\ASET search_path/ } @$stmts), 1,
    'the path of the connection is set once, at the head of the script (karr k121)';
  unlike $stmts->[-1], qr/search_path/,
    '... and the script does not close with it';
  unlike $sql, qr/search_path TO auth/,
    '... pg_search_path of the class is not read on such a connection';
  unlike $sql, qr/tenant_a\./, 'no name in the script is qualified with the namespace';
}
{
  my $class = schema_class(
    schemas    => [ 'extensions' ],
    extensions => [ 'pgcrypto', vector => { schema => 'extensions' } ],
  );
  my $sql = script(in_namespace($class, 'tenant_a'));

  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;$/m,
    'an extension that names no schema is created WITH SCHEMA public';
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;$/m,
    '... one that names a schema, in that schema';
  unlike $sql, qr/^CREATE EXTENSION (?![^;]*WITH SCHEMA)/m,
    '... and none is left to the search_path';

  my @at = map { pos_of($sql, $_) } (
    qr/^CREATE EXTENSION IF NOT EXISTS vector /m,
    qr/nspname = 'tenant_a'/,
    qr/^SET search_path TO tenant_a, public, extensions;$/m,
    qr/^CREATE TABLE things /m,
  );
  ok !(grep { !defined } @at) && $at[0] < $at[1] && $at[1] < $at[2] && $at[2] < $at[3],
    'order: the extensions, the namespace, the path, the tables'
    or diag $sql;
  is scalar(() = $sql =~ /nspname = 'extensions'/g), 1,
    'the schema of the extension is created once';
}
{
  my $class = schema_class(schemas => [qw( tenant_a other )]);
  my $sql   = script(in_namespace($class, 'tenant_a'));
  is scalar(() = $sql =~ /nspname = 'tenant_a'/g), 1,
    'a namespace pg_schemas names as well is created once';
  like $sql, qr/nspname = 'other'/,
    '... and pg_schemas alone refuses nothing: its other schema is created';
}

# The same class, two namespaces at once, and without the key what it was.
{
  my $class = schema_class(
    schemas     => [ 'extensions' ],
    extensions  => [ vector => { schema => 'extensions' } ],
    search_path => [qw( extensions public )],
  );
  my $plain = script($class);

  my $schema_a = in_namespace($class, 'tenant_a');
  my $schema_b = in_namespace($class, 'tenant_b');
  my ($sql_a, $sql_b) = (script($schema_a), script($schema_b));

  (my $a_as_b = $sql_a) =~ s/tenant_a/tenant_b/g;
  is $sql_b, $a_as_b, 'two connections of one class: the scripts differ in the namespace only';
  like $sql_a, qr/nspname = 'tenant_a'/, '... each creates its own';
  unlike $sql_a, qr/tenant_b/, '... and names no other';

  is script($class->connect(@LOGIN)), $plain,
    'a connection without the key installs what the class installs';
  unlike $plain, qr/search_path/,
    '... and writing no pg_search_path (karr k121)';
  unlike $plain, qr/tenant_/, '... and without a trace of the connections beside it';

  is_deeply [ $class->pg_schemas ], [ 'extensions' ], 'pg_schemas of the class is what was declared';
  is_deeply [ $class->pg_search_path ], [qw( extensions public )], '... and so is pg_search_path';
  is_deeply scalar $class->pg_extension_schemas, { vector => 'extensions' }, '... and the extension schemas';

  # 3. The deploy of the instance.
  is_deeply filter_of($schema_a), [ 'tenant_a' ],
    'deploy of the tenant_a connection: restricted to tenant_a';
  is_deeply filter_of($schema_b), [ 'tenant_b' ],
    '... of the tenant_b connection, at the same time: to tenant_b';
  is_deeply filter_of($class->connect(@LOGIN)),
    [ 'extensions' ], '... and without the key: to pg_schemas, as declared';
  is_deeply filter_of($class),
    [ 'extensions' ], '... as for the class itself';
}
{
  my $class = schema_class();
  is_deeply filter_of(in_namespace($class, 'tenant_a')),
    [ 'tenant_a' ], 'a class that declares no pg_schemas is restricted by the connection all the same';
  is filter_of($class->connect(@LOGIN)), undef,
    '... and unrestricted without the key';
}

# The diff of such a deploy: restricted, so it drops no extension -- and a
# CREATE EXTENSION it writes says where, since the session that applies it
# has the namespace first in its search_path.
{
  package K128::Deploy;
  use base 'DBIO::PostgreSQL::Deploy';
  # The extension protocol (ADR 0066) runs for declared extensions and needs
  # a connection and the installed state; this fake has neither.
  sub _dbh { {} }
  sub _extension_control_schemas { {} }
  sub _installed_extensions { +{ map { $_ => { installed => 0 } } @{ $_[1] } } }
  sub _introspect_current { +{ extensions => {
    other => { extension_name => 'other', version => '1.0', schema_name => 'public' },
    moved => { extension_name => 'moved', version => '1.0', schema_name => 'elsewhere', relocatable => 1 },
  } } }
  sub _build_target_model { $_[0]->_mark_extension_schemas({ extensions => {
    hstore => { extension_name => 'hstore', version => '1.8', schema_name => 'public' },
    vector => { extension_name => 'vector', version => '0.8', schema_name => 'extensions' },
    moved  => { extension_name => 'moved',  version => '1.0', schema_name => 'public' },
  } }) }
}
{
  my $class = schema_class(
    schemas    => [ 'extensions' ],
    extensions => [ 'hstore', 'moved', vector => { schema => 'extensions' } ],
  );
  my $diff = K128::Deploy->new(schema => in_namespace($class, 'tenant_a'))->diff;
  my $sql  = $diff->as_sql;

  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;$/m,
    'diff on such a connection: an extension that names no schema is created WITH SCHEMA public';
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;$/m,
    '... a declared one in its schema';
  unlike $sql, qr/DROP EXTENSION/, '... and no extension is dropped: the deploy is restricted';
  unlike $sql, qr/ALTER EXTENSION moved/,
    '... an extension that names no schema is still never moved';

  my $plain = K128::Deploy->new(schema => $class->connect(@LOGIN))->diff->as_sql;
  like $plain, qr/^CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;$/m,
    q{without the key the diff writes CREATE EXTENSION WITH SCHEMA public, as the install does};
}

# ---------------------------------------------------------------------------
# 4. Refused on a connection with a namespace.
# ---------------------------------------------------------------------------

{
  my $class = schema_class(
    schemas    => [ 'tenant_a' ],
    extensions => [ vector => { schema => 'tenant_a' } ],
  );
  throws_ok { script(in_namespace($class, 'tenant_a')) }
    qr/refusing to write the install DDL: extension vector .*tenant_a/s,
    'refused: an extension declared in the namespace of the connection';
  lives_ok { script(in_namespace($class, 'tenant_b')) }
    '... the same class installs for a connection that works elsewhere';
}
{
  my $class = schema_class(extensions => [ 'vector' ]);
  throws_ok { script(in_namespace($class, 'public')) }
    qr/refusing to write the install DDL: extension vector .*public/s,
    'refused: an extension without a schema on a connection that works in public';
}
{
  my $class = schema_class(
    schemas => [ 'auth' ],
    sources => { Thing => 'K128::Result::Thing', User => 'K128::Result::InAuth' },
  );
  throws_ok { script(in_namespace($class, 'tenant_a')) }
    qr/refusing to write the install DDL: .*\bUser\b.*\bauth\b.*\btenant_a\b/s,
    'refused: a result class with a pg_schema, naming source, schema and namespace';
  lives_ok { script($class->connect(@LOGIN)) } '... without the key it installs';
}
{
  my $class = schema_class(
    sources => { Thing => 'K128::Result::Thing', Country => 'K128::Result::Dotted' },
  );
  throws_ok { script(in_namespace($class, 'tenant_a')) }
    qr/refusing to write the install DDL: .*\bCountry\b.*shared\.countries.*\btenant_a\b/s,
    'refused: a table name that carries its schema';
  lives_ok { script($class->connect(@LOGIN)) } '... without the key it installs';
}
{
  my $class = schema_class(
    schemas      => [ 'auth' ],
    schema_class => [ auth => 'K128::PgSchema::Auth' ],
  );
  throws_ok { script(in_namespace($class, 'tenant_a')) }
    qr/refusing to write the install DDL: .*pg_schema_class.*\bauth\b.*K128::PgSchema::Auth.*\btenant_a\b/s,
    'refused: a pg_schema_class binding, naming binding, class and namespace';
  lives_ok { script($class->connect(@LOGIN)) } '... without the key it installs';
}
{
  my $class = schema_class(schemas => [ 'auth' ]);
  lives_ok { script(in_namespace($class, 'tenant_a')) }
    'not refused: pg_schemas entries alone';
}

done_testing;

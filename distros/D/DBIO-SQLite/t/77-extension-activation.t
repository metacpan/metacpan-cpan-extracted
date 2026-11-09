use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use File::Temp ();
use DBIO::SQLite::Extension;

# OFFLINE test: what the declared extensions want of a new connection (ADR
# 0066: activation; karr k85).
#
# WHY: a SQLite extension is not in the file, so every connection has to load
# its library again, and loading is a call on the handle, not a statement. The
# declaration is the one place an application writes it; a schema that
# declares nothing must be sent exactly what it was sent before, a library that
# cannot be loaded must say which one, and loading must not stay switched on
# for the SQL that follows.
#
# What this file claims:
#   1. the activation is the libraries of the declaration, merged by core in
#      the name order of the extensions; no declaration, or declared extensions
#      without a library, is no activation at all and the connection is not
#      touched;
#   2. what cannot be composed (two libraries for one name) refuses;
#   3. the driver assertion is checked when the connection is set up, not at
#      connect;
#   4. the library is loaded through the handle: enable, load, disable, one
#      library after the other; a failing load names the library and still
#      switches loading off; a pool connection (statements only) refuses;
#   5. a real connection with a library that is not there dies with a clear
#      error naming it -- not DBD::SQLite's "not an error";
#   6. with a real loadable library (compiled here, skipped when there is no
#      C compiler): every connection has its function, loading is off
#      afterwards in SQL, and an extension's own probe sees it in the model.

{
  package T77::Handle;
  sub new { bless { log => [], fail => $_[1] }, $_[0] }
  sub sqlite_enable_load_extension { push @{ $_[0]{log} }, "enable $_[1]"; 1 }
  sub sqlite_load_extension {
    push @{ $_[0]{log} }, "load $_[1]";
    die "sqlite_load_extension failed with error not an error at x\n" if $_[0]{fail} && $_[0]{fail} eq $_[1];
    1;
  }
  sub FETCH { 1 }

  package T77::Lib;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub driver { 'DBIO::SQLite' }
  sub name   { 'libx' }
  sub activation { { load => { libx => 'x_one' } } }

  package T77::LibClash;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub driver { 'DBIO::SQLite' }
  sub name   { 'libclash' }
  sub activation { { load => { libx => 'x_other' } } }

  package T77::Foreign;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub driver { 'DBIO::PostgreSQL' }
  sub name   { 'foreign' }
  sub activation { { load => 'foreign' } }
}
$INC{"T77/$_.pm"} = __FILE__ for qw( Lib LibClash Foreign );

my $n = 0;
sub schema_class {
  my (@extensions) = @_;
  my $pkg = 'T77::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('SQLite');
  $pkg->sqlite_extensions(@extensions) if @extensions;
  return $pkg;
}

# the storage holds its schema weakly: keep the schema alive for the test
my @KEEP;
sub storage_of {
  my $schema = schema_class(@_)->connect('dbi:SQLite::memory:');
  push @KEEP, $schema;
  return $schema->storage;
}

# --- 1. the activation -----------------------------------------------------------
is storage_of()->_extension_activation, undef, 'no declaration: no activation';
is storage_of('fts5', 'rtree', 'json1')->_extension_activation, undef,
  'declared extensions without a library: none either';
is_deeply storage_of(vec0 => { library => '/opt/vec0.so' })->_extension_activation,
  { load => ['/opt/vec0.so'], search_path => [] }, 'a library is the activation';
is_deeply storage_of(zz => { library => 'zlib' }, 'fts5', aa => { library => 'alib' })->_extension_activation,
  { load => [ 'alib', 'zlib' ], search_path => [] }, 'libraries in the name order of the extensions, whatever the order of the declaration';
is_deeply storage_of(fts5 => { library => 'fts5ext' })->_extension_activation,
  { load => ['fts5ext'], search_path => [] }, 'an extension of the family can come from a library as well';
is_deeply storage_of(libx => { class => 'T77::Lib' })->_extension_activation,
  { load => ['x_one'], search_path => [] }, 'a class of its own supplies its activation';

{
  # a schema class that does not load the component at all (the storage is chosen by its type)
  my $pkg = 'T77::Bare';
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->storage_type('+DBIO::SQLite::Storage');
  my $schema = $pkg->connect('dbi:SQLite::memory:');
  is $schema->storage->_extension_activation, undef, 'a schema class without the component declares none';
  lives_ok { $schema->storage->dbh } '... and connects as before';
}

# --- 2. cannot compose --------------------------------------------------------------
{
  my $storage = storage_of(libx => { class => 'T77::Lib' }, libclash => { class => 'T77::LibClash' });
  throws_ok { $storage->_extension_activation }
    qr/Activation cannot compose: 'libx' is loaded from 'x_other' by libclash and from 'x_one' by libx/,
    'two libraries for one name refuse';
}

# --- 3. the driver assertion ------------------------------------------------------------
{
  my $schema;
  lives_ok { $schema = schema_class(foreign => { class => 'T77::Foreign' })->connect('dbi:SQLite::memory:') }
    'connect does not check the driver assertion: a class of another driver does not stop it';
  throws_ok { $schema->storage->_extension_activation }
    qr/Extension 'foreign' \(T77::Foreign\) belongs to the driver DBIO::PostgreSQL, but the schema's driver is DBIO::SQLite/,
    '... the first use of the connection refuses, naming both drivers';
}

# --- 4. through the handle ----------------------------------------------------------------
sub setup_log {
  my ($storage, $fail) = @_;
  my $handle = T77::Handle->new($fail);
  $storage->_dbh($handle);
  my $ok  = eval { $storage->_apply_connection_schema; 1 };
  my $err = $@;
  $storage->_dbh(undef);
  return $ok ? $handle->{log} : { died => "$err", log => $handle->{log} };
}

is_deeply setup_log(storage_of()), [], 'no declaration: the handle is not touched';
is_deeply setup_log(storage_of('fts5')), [], '... nor with extensions that load nothing';
is_deeply setup_log(storage_of(b => { library => 'blib' }, a => { library => 'alib' })), [
  'enable 1', 'load alib', 'enable 0',
  'enable 1', 'load blib', 'enable 0',
], 'every library: enable, load, disable, in name order';
{
  my $got = setup_log(storage_of(b => { library => 'blib' }, a => { library => 'alib' }), 'alib');
  like $got->{died}, qr/Cannot load the SQLite extension library 'alib': .*not an error/,
    'a library that fails to load dies, naming it';
  is_deeply $got->{log}, [ 'enable 1', 'load alib', 'enable 0' ], '... loading is switched off again, and the next library is not tried';
}
{
  my $storage = storage_of(a => { library => 'alib' });
  local $storage->{_pool_connect_runner} = sub { };
  throws_ok { $storage->_apply_connection_schema }
    qr/statement runner of an async pool.*\(alib\)/s,
    'a connection of an async pool has no handle to load into: it refuses, naming the libraries';
  my $none = storage_of();
  local $none->{_pool_connect_runner} = sub { };
  lives_ok { $none->_apply_connection_schema } '... but a pool connection of a schema without libraries is fine';
}

# --- 5. a library that is not there ------------------------------------------------------------
{
  my $schema = schema_class(ghost => { library => '/nonexistent/dbio-k85/ghost' })->connect('dbi:SQLite::memory:');
  throws_ok { $schema->storage->dbh }
    qr{Cannot load the SQLite extension library '/nonexistent/dbio-k85/ghost':},
    'a real connection: the library that cannot be loaded is named';
  ok !$schema->storage->connected, '... and the connection is not left half set up';
}

# --- 6. a real loadable library -------------------------------------------------------------------
my $dir = File::Temp->newdir;
my $so  = "$dir/dbioprobe.so";
my $built = do {
  my $c = "$dir/dbioprobe.c";
  if (open my $fh, '>', $c) {
    print {$fh} <<'C';
#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1
static void probe(sqlite3_context *c, int n, sqlite3_value **v) { sqlite3_result_text(c, "loaded", -1, SQLITE_STATIC); }
int sqlite3_dbioprobe_init(sqlite3 *db, char **err, const sqlite3_api_routines *api) {
  SQLITE_EXTENSION_INIT2(api);
  return sqlite3_create_function(db, "dbio_ext_probe", 0, SQLITE_UTF8, 0, probe, 0, 0);
}
C
    close $fh;
  }
  my @inc = ('/usr/include');
  push @inc, eval { require File::ShareDir; File::ShareDir::dist_dir('DBD-SQLite') } || ();
  my $ok = 0;
  for my $inc (@inc) {
    next unless -f "$inc/sqlite3ext.h";
    local $ENV{LC_ALL} = 'C';
    $ok = system("cc -shared -fPIC -I'$inc' -o '$so' '$c' >/dev/null 2>&1") == 0 && -f $so;
    last if $ok;
  }
  $ok;
};

SKIP: {
  skip 'no C compiler or sqlite3ext.h to build a loadable library', 9 unless $built;

  {
    package T77::Probe;
    use base 'DBIO::SQLite::Extension';
    sub name { 'dbioprobe' }
    # the probe of an extension that is a function: the database answers
    sub inspect {
      my ($class, $ctx) = @_;
      my ($answer) = eval { $ctx->{dbh}->selectrow_array('SELECT dbio_ext_probe()') };
      return { function => 'dbio_ext_probe', answers => $answer };
    }
  }
  $INC{'T77/Probe.pm'} = __FILE__;

  my $class = schema_class(dbioprobe => { library => $so, class => 'T77::Probe' });
  my $schema = $class->connect('dbi:SQLite::memory:');
  my $dbh = $schema->storage->dbh;
  is $dbh->selectrow_array('SELECT dbio_ext_probe()'), 'loaded', 'the connection has the function of the library';

  throws_ok { $dbh->selectrow_array(q{SELECT load_extension('dbioprobe')}) } qr/not authorized|authoriz/i,
    'loading is switched off again: SQL load_extension() is refused';

  $schema->storage->disconnect;
  is $schema->storage->dbh->selectrow_array('SELECT dbio_ext_probe()'), 'loaded', 'a reconnect loads it again';

  my $other = $class->connect('dbi:SQLite::memory:');
  is $other->storage->dbh->selectrow_array('SELECT dbio_ext_probe()'), 'loaded', 'another connection too';

  my $plain = schema_class()->connect('dbi:SQLite::memory:');
  throws_ok { $plain->storage->dbh->selectrow_array('SELECT dbio_ext_probe()') } qr/no such function/,
    'a schema that declares nothing has no such function';

  # the probe sees the library through the deploy
  require DBIO::SQLite::Deploy;
  $schema->storage->dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY)');
  my $diff = do { local $SIG{__WARN__} = sub {}; DBIO::SQLite::Deploy->new(schema => $schema)->diff };
  is_deeply $diff->source->{extensions}{dbioprobe}, { function => 'dbio_ext_probe', answers => 'loaded' },
    'the probe of an extension that is a function answers over the connection of the deploy';
  is_deeply $diff->target->{extensions}{dbioprobe}, { function => 'dbio_ext_probe', answers => 'loaded' },
    '... and is in the model of both sides';

  my $list = DBIO::SQLite::Extension->resolve_list($class);
  is_deeply [ map { $_->{options} } $list->entries ], [ { library => $so } ], 'the library is an option of the entry';

  is_deeply [ sort @{ $schema->storage->dbh->selectcol_arrayref(q{SELECT name FROM sqlite_master WHERE type = 'table'}) } ],
    ['artist'], 'the extension left nothing in the file';
}

done_testing;

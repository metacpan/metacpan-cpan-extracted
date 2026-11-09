use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::Storage;

# OFFLINE test for karr k121 (point 4, maintainer's decision 2026-10-22):
# pg_search_path is set on every connection of the schema.
#
# CLAIM: the declaration has its effect through the connection. The install
# script no longer ends with SET search_path (t/168), so a declared path
# reached nobody; now the storage sets it, by the one seam that already sets
# the path of a namespace connection (_apply_connection_schema, run by core
# ahead of on_connect_do/on_connect_call on the sync and on every pool
# connection). The rules:
#
#   1. declared, no connect key: SET search_path TO <declared>, then the
#      schemas the declared extensions name (an extension without a schema
#      adds nothing: the user writes public if wanted), then the schemas of
#      the extensions' activation; each schema once, at its first place;
#   2. not declared: nothing is sent (the default 'public' is no declaration);
#   3. the connect key wins: the namespace path, pg_search_path is not read;
#   4. the application's on_connect_do runs after it, so it can still win;
#   5. an entry that is no name is refused at connect, not written twice
#      quoted; $user is written as it is.
#
# SUBSTITUTIONS: no server; the sync handle logs do(), the pool connection is
# the runner core hands the statements to (as t/129).

my @LOGIN = ('dbi:Pg:dbname=k121_offline', 'u', 'p');

{
  package K121P4::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('things');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}

my $n = 0;
sub schema_class {
  my (%o) = @_;
  my $pkg = 'K121P4::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_schemas(@{ $o{schemas} })         if $o{schemas};
  $pkg->pg_extensions(@{ $o{extensions} })   if $o{extensions};
  $pkg->pg_search_path(@{ $o{search_path} }) if $o{search_path};
  $pkg->register_class(Thing => 'K121P4::Result::Thing');
  return $pkg;
}

{
  package K121P4::Handle;
  sub new { bless { log => [] }, $_[0] }
  sub do  { push @{ $_[0]{log} }, $_[1]; '0E0' }
}
sub sync_setup {
  my ($schema) = @_;
  my $storage = $schema->storage;
  my $handle  = K121P4::Handle->new;
  $storage->_dbh($handle);
  $storage->_conn_pid($$);
  local $storage->{_in_do_block} = 1;
  my $ok  = eval { $storage->_run_connection_actions; 1 };
  my $err = $@;
  $storage->_dbh(undef);
  return $ok ? $handle->{log} : "died: $err";
}
sub pool_setup {
  my ($schema) = @_;
  my @sent;
  return "died: $@"
    unless eval { $schema->storage->_run_pool_connect_actions(sub { push @sent, $_[0] }); 1 };
  return \@sent;
}
sub both {
  my ($schema, $want, $what) = @_;
  is_deeply sync_setup($schema), $want, "sync: $what";
  is_deeply pool_setup($schema), $want, "pool: $what";
}

both(schema_class(search_path => [qw( a b )])->connect(@LOGIN),
  [ 'SET search_path TO a, b' ], 'a declared path is set on the connection');

both(schema_class(search_path => [ 'MySchema', '$user', 'public' ])->connect(@LOGIN),
  [ 'SET search_path TO "MySchema", "$user", public' ],
  'entries are written as identifiers, $user as the server reads it');

both(schema_class()->connect(@LOGIN), [], 'no declaration: nothing is sent');
both(schema_class(search_path => ['public'])->connect(@LOGIN),
  [ 'SET search_path TO public' ], 'a declaration of public is a declaration');

both(schema_class(
    search_path => [qw( a b )], schemas => [ 'extensions' ],
    extensions  => [ 'pgcrypto', vector => { schema => 'extensions' } ],
  )->connect(@LOGIN),
  [ 'SET search_path TO a, b, extensions' ],
  'the schema a declared extension names stays in the path, behind the declared entries; one without a schema adds none');

both(schema_class(
    search_path => [qw( a extensions )], schemas => [ 'extensions' ],
    extensions  => [ vector => { schema => 'extensions' } ],
  )->connect(@LOGIN),
  [ 'SET search_path TO a, extensions' ], 'a schema stands once, at its first place');

both(schema_class(search_path => [qw( auth public )])->connect(@LOGIN, { schema => 'tenant_a' }),
  [ 'SET search_path TO tenant_a, public' ],
  'with the connect key the namespace path is set and pg_search_path is not read');

both(schema_class(search_path => [qw( a b )])
    ->connect(@LOGIN, { on_connect_do => [ 'SET search_path TO mine' ] }),
  [ 'SET search_path TO a, b', 'SET search_path TO mine' ],
  'the application\'s on_connect_do runs after the declared path and wins');

for my $bad ('"quoted"', '') {
  my $schema = schema_class(search_path => [ 'a', $bad ])->connect(@LOGIN);
  like sync_setup($schema), qr/\Adied: .*pg_search_path entry/s,
    "an entry that is no name (" . ($bad eq '' ? 'empty' : $bad) . ") is refused at connect";
}

is_deeply [ DBIO::PostgreSQL->pg_search_path ], ['public'], 'the getter keeps its default';
ok !schema_class()->pg_search_path_declared, 'a class that declares none says so';
ok schema_class(search_path => ['public'])->pg_search_path_declared,
  '... and one that declares public says so';

done_testing;

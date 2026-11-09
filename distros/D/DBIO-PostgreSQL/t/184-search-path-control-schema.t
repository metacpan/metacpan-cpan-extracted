use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Util qw(connection_search_path);

# OFFLINE test for karr k142 (b), maintainer's decision: the search_path of a
# connection with the connect key `schema` follows the same rule as the
# CREATE EXTENSION of the install: the schema the declaration names, else the
# one the control file fixes, else public.
#
# CLAIM: without it, `age` (control file: ag_catalog) is installed in
# ag_catalog, but the path of the connection says `public` for it, so the
# connection cannot find the extension's objects unqualified. The rule must
# hold for the pure function, and the storage must ask the server only for
# extensions that name no schema themselves (a declared schema wins and costs
# no query).
#
# SUBSTITUTIONS: no server; _pool_connect_rows is stubbed and logs its SQL.

# --- Util -----------------------------------------------------------------

is_deeply [ connection_search_path('t', ['age'], {}) ], [ 't', 'public' ],
  'no control argument: an extension without a schema stands for public (offline install_ddl)';
is_deeply [ connection_search_path('t', ['age'], {}, [], { age => 'ag_catalog' }) ],
  [ 't', 'ag_catalog' ],
  'the schema the control file fixes stands for an extension that names none';
is_deeply [ connection_search_path('t', ['age'], { age => 'mine' }, [], { age => 'ag_catalog' }) ],
  [ 't', 'mine' ], 'a declared schema wins over the control file';
is_deeply [ connection_search_path('t', [ 'pgcrypto', 'age' ], {}, [], { age => 'ag_catalog' }) ],
  [ 't', 'public', 'ag_catalog' ],
  'an extension the control file does not fix stands for public, in declaration order';
is_deeply [ connection_search_path('t', ['age'], {}, ['ag_catalog', 'public'], { age => 'ag_catalog' }) ],
  [ 't', 'ag_catalog', 'public' ], 'a schema stands once, at its first place';

# --- Storage --------------------------------------------------------------

{
  package K142Off::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('things');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}

my $n = 0;
sub storage_for {
  my (%o) = @_;
  my $pkg = 'K142Off::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_schemas(@{ $o{schemas} })       if $o{schemas};
  $pkg->pg_extensions(@{ $o{extensions} }) if $o{extensions};
  $pkg->register_class(Thing => 'K142Off::Result::Thing');
  return $pkg->connect('dbi:Pg:dbname=k142_offline', 'u', 'p')->storage;
}

my (@asked, $rows);
{
  no warnings 'redefine';
  *DBIO::PostgreSQL::Storage::_pool_connect_rows = sub {
    my ($self, $sql) = @_;
    push @asked, $sql;
    return $rows;
  };
}
my $act = { search_path => [] };

@asked = (); $rows = [ [ 'age', 'ag_catalog' ] ];
is_deeply [ storage_for(extensions => ['age'])->_connection_search_path('t', $act) ],
  [ 't', 'ag_catalog' ],
  'age without a declared schema: the path holds ag_catalog, as the install put it there';
is scalar @asked, 1, 'one question to the server';
like $asked[0], qr/pg_available_extension_versions.*'age'/s,
  '... about the control file of age';

@asked = (); $rows = [ [ 'age', 'ag_catalog' ] ];
is_deeply [ storage_for(extensions => [ age => { schema => 'mine' } ], schemas => ['mine'])
    ->_connection_search_path('t', $act) ],
  [ 't', 'mine' ], 'a declared schema wins';
is scalar @asked, 0, '... and the server is not asked when every schema is declared';

@asked = (); $rows = [ [ 'age', 'ag_catalog' ] ];
storage_for(extensions => [ 'age', vector => { schema => 'ext' } ], schemas => ['ext'])
  ->_connection_search_path('t', $act);
unlike $asked[0] // '', qr/vector/, 'only extensions without a declared schema are asked for';

@asked = (); $rows = undef;
is_deeply [ storage_for(extensions => ['age'])->_connection_search_path('t', $act) ],
  [ 't', 'public' ],
  'a runner that returns no rows (ev) falls back to public instead of dying';

@asked = (); $rows = [];
is_deeply [ storage_for()->_connection_search_path('t', $act) ], [ 't', 'public' ],
  'no extension declared: public';
is scalar @asked, 0, '... and nothing is asked';

done_testing;

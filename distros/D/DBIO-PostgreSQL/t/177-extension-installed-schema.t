use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::DDL;

# OFFLINE test for karr k144, text level.
#
# The temporary database of a diff creates an extension the declaration gives
# no schema (and whose control file fixes none) in the schema the database
# under diff has it in: the deploy hands that to install_ddl as the option
# extension_installed_schemas (extension name => schema). Otherwise the
# temporary database had it in public and a column of its type was ext.citext
# there and public.citext here.
#
# WHAT IT PINS:
#   - the installed schema is created ahead of the extension and named;
#   - a declared schema and a schema the control file fixes win over it;
#   - public needs no CREATE SCHEMA;
#   - it needs no pg_schemas entry (it is the database's, not a declaration);
#   - an extension it does not name stays in public;
#   - the namespace of a connection still refuses an extension in it.

my $n = 0;
sub fresh_schema {
  my (%o) = @_;
  my $pkg = 'ExtInstalled' . ++$n . '::Schema';
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_schemas(@{ $o{schemas} }) if $o{schemas};
  $pkg->pg_extensions(@{ $o{extensions} }) if $o{extensions};
  return $pkg;
}

sub ddl { my ($schema, %o) = @_; [ grep { /EXTENSION|CREATE SCHEMA/ } split /\n+/, DBIO::PostgreSQL::DDL->install_ddl($schema, %o) ] }

{
  my $s = fresh_schema(extensions => ['citext'], schemas => ['public']);
  is_deeply ddl($s, extension_installed_schemas => { citext => 'ext' }),
    [ 'CREATE SCHEMA IF NOT EXISTS ext;', 'CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA ext;' ],
    'an extension the database holds in ext is created in ext, the schema ahead of it, pg_schemas not naming it';

  is_deeply ddl($s, extension_installed_schemas => { citext => 'public' }),
    [ 'CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;' ],
    'installed in public: no CREATE SCHEMA';

  is_deeply ddl($s, extension_installed_schemas => { other => 'ext' }),
    [ 'CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;' ],
    'an extension the option does not name stays in public';

  is_deeply ddl($s),
    [ 'CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;' ],
    'without the option nothing changes';
}

{
  my $s = fresh_schema(extensions => ['citext'], schemas => ['public', 'gis']);
  $s->pg_extensions(citext => { schema => 'gis' });
  is_deeply ddl($s, extension_installed_schemas => { citext => 'ext' }),
    [ 'CREATE SCHEMA IF NOT EXISTS gis;', 'CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA gis;' ],
    'a declared schema wins over the installed one';
}

{
  my $s = fresh_schema(extensions => ['age']);
  is_deeply ddl($s, extension_control_schemas => { age => 'ag_catalog' },
      extension_installed_schemas => { age => 'elsewhere' }),
    [ 'CREATE EXTENSION IF NOT EXISTS age;' ],
    'the schema a control file fixes wins over the installed one';
}

done_testing;

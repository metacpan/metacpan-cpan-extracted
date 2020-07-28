use Test2::V0;
use Test2::Tools::QuickDB;
use File::Spec;

my @ENV_VARS;

# Contaminate the ENV vars to make sure things work even when these are all
# set.
BEGIN {
    @ENV_VARS = qw{
        DBI_USER DBI_PASS DBI_DSN
        PGAPPNAME PGCLIENTENCODING PGCONNECT_TIMEOUT PGDATABASE PGDATESTYLE
        PGGEQO PGGSSLIB PGHOST PGHOSTADDR PGKRBSRVNAME PGLOCALEDIR PGOPTIONS
        PGPASSFILE PGPASSWORD PGPORT PGREQUIREPEER PGREQUIRESSL PGSERVICE
        PGSERVICEFILE PGSSLCERT PGSSLCOMPRESSION PGSSLCRL PGSSLKEY PGSSLMODE
        PGSSLROOTCERT PGSYSCONFDIR PGTARGETSESSIONATTRS PGTZ PGUSER
    };
    $ENV{$_} = 'fake' for @ENV_VARS;
}

skipall_unless_can_db('PostgreSQL');

sub DRIVER() { 'PostgreSQL' }

my $file = __FILE__;
$file =~ s/postgresql\.t$/Pool.pm/;
$file = File::Spec->rel2abs($file);
require $file;

done_testing;

package TestApp::DBI::Connector;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use File::Spec;
use DBI;

use Log::Log4perl qw(:easy);
use YAML::Syck;

use base qw( Apache2::Controller::DBI::Connector );

use File::Temp qw( tempdir );

my $tmpdir = tempdir( CLEANUP => 1 );

my $sqlfile = File::Spec->catfile( 
    $tmpdir, "A2C_Test_DBI_Connector.sqlite" 
);

my @dbi_args = ( "dbi:SQLite:dbname=$sqlfile", '', '', {
    RaiseError => 1,
    PrintError => 0,
    PrintWarn  => 0,
  # AutoCommit => 0,
});

sub dbi_connect_args {
    my ($self) = @_;
    DEBUG "DBI ARGS:\n".Dump(\@dbi_args);
    return @dbi_args;
}

sub dbi_cleanup { 1 }

1;

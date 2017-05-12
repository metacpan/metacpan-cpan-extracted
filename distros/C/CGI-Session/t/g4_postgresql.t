# $Id$

use strict;


my %dsn;
if ($ENV{DBI_DSN} && ($ENV{DBI_DSN} =~ m/^dbi:Pg:/)) {
    %dsn = (
        DataSource  => $ENV{DBI_DSN},
        User        => $ENV{DBI_USER},
        Password    => $ENV{DBI_PASS},
    );
}
else {
    %dsn = (
        DataSource  => $ENV{CGISESS_PG_DSN},
        User        => $ENV{CGISESS_PG_USER},
        Password    => $ENV{CGISESS_PG_PASS},
    );
}

%dsn = (%dsn, TableName => 'sessions', IdColName => 'id', DataColName => 'a_session');

use File::Spec;
use Test::More;
use CGI::Session::Test::Default;

unless ( $dsn{DataSource} ) {
    plan(skip_all=>"DataSource is not known");
    exit(0);
}

for ( "DBI", "DBD::Pg" ) {
    eval "require $_";
    if ( $@ ) {
        plan(skip_all=>"$_ is NOT available");
        exit(0);
    }
}

my $dbh = DBI->connect($dsn{DataSource}, $dsn{User}, $dsn{Password}, {RaiseError=>0, PrintError=>0});
unless ( $dbh ) {
    plan(skip_all=>"Couldn't establish connection with the PostgreSQL server");
    exit(0);
}

my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $dsn{TableName}");

if ( defined $count ) {
    $dbh->do("drop table $dsn{TableName}");
}

if( $dbh->do(qq|
    CREATE TABLE $dsn{TableName} (
        $dsn{IdColName} CHAR(32) NOT NULL PRIMARY KEY,
        $dsn{DataColName} TEXT NULL
    )|) ) {
    #print STDERR "Created table. \n";
} else {
    plan(skip_all=>$dbh->errstr);
    exit(0);
}

my $t = CGI::Session::Test::Default->new(
    dsn => "dr:postgresql",
    args=>{Handle=>$dbh, TableName=>$dsn{TableName}, IdColName => $dsn{IdColName}, DataColName => $dsn{DataColName} });

plan tests => $t->number_of_tests;
$t->run();


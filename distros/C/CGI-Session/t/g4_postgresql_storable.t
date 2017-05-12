# $Id$

use strict;


my %dsn;
if ($ENV{DBI_DSN} && $ENV{DBI_DSN} =~ m/^dbi:Pg:/) {
    %dsn = (
        DataSource  => $ENV{DBI_DSN},
        Password    => $ENV{CGISESS_PG_PASS} || undef,
        TableName   => 'sessions'
    );
}
else {
    %dsn = (
        DataSource  => $ENV{CGISESS_PG_DSN},
        User        => $ENV{CGISESS_PG_USER} || $ENV{USER},
        Password    => $ENV{CGISESS_PG_PASS} || undef,
        TableName   => 'sessions'
    );
}


use File::Spec;
use Test::More;
use CGI::Session::Test::Default;

unless ( $dsn{DataSource} ) {
    plan(skip_all=>"DataSource is not known");
    exit(0);
}

for ( "DBI", "DBD::Pg", "Storable" ) {
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

eval {
    $dbh->do(qq|drop table $dsn{TableName}|)
};
unless( $dbh->do(qq|
    CREATE TABLE $dsn{TableName} (
        id CHAR(32) NOT NULL PRIMARY KEY,
        a_session BYTEA NULL
    )|) ) {
    plan(skip_all=>$dbh->errstr);
    exit(0);
}


my $t = CGI::Session::Test::Default->new(
    dsn => "dr:postgresql;serializer:storable",
    args=>{Handle=>$dbh, TableName=>$dsn{TableName}, ColumnType=>'binary'});

plan tests => $t->number_of_tests;
$t->run();

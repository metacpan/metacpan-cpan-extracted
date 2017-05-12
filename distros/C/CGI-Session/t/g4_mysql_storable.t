# $Id$

use strict;


my %dsn;
if (defined $ENV{DBI_DSN} && ($ENV{DBI_DSN} =~ m/^dbi:mysql:/)) {
    %dsn = (
        DataSource  => $ENV{DBI_DSN},
        Password    => $ENV{CGISESS_MYSQL_PASS} || undef,
        TableName   => 'sessions'
    );
}
else {
    %dsn = (
        DataSource  => $ENV{CGISESS_MYSQL_DSN},
        User        => $ENV{CGISESS_MYSQL_USER}     || $ENV{USER},
        Password    => $ENV{CGISESS_MYSQL_PASS}     || undef,
        Socket      => $ENV{CGISESS_MYSQL_SOCKET}   || undef,
        TableName   => 'sessions'
    );
}


use File::Spec;
use Test::More;
use CGI::Session::Test::Default;

for (qw/DBI DBD::mysql Storable/) {
    eval "require $_";
    if ( $@ ) {
        plan(skip_all=>"$_ is NOT available");
        exit(0);
    }
}



require CGI::Session::Driver::mysql;
my $dsnstring = CGI::Session::Driver::mysql->_mk_dsnstr(\%dsn);

my $dbh;
eval { $dbh = DBI->connect($dsnstring, $dsn{User}, $dsn{Password}, {RaiseError=>0, PrintError=>1}) };
unless ( $dbh ) {
    plan(skip_all=>"Couldn't establish connection with the MySQL server: " . (DBI->errstr || $@));
    exit(0);
}

my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $dsn{TableName}");
unless ( defined $count ) {
    unless( $dbh->do(qq|
        CREATE TABLE $dsn{TableName} (
            id CHAR(32) NOT NULL PRIMARY KEY,
            a_session TEXT NULL
        )|) ) {
        plan(skip_all=>$dbh->errstr);
        exit(0);
    }
}


my $t = CGI::Session::Test::Default->new(
    dsn => "dr:mysql;ser:Storable",
    args=>{Handle=>$dbh, TableName=>$dsn{TableName}});

plan tests => $t->number_of_tests;
$t->run();

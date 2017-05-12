# $Id$

use strict;


my %dsn;
if ($ENV{DBI_DSN} && ($ENV{DBI_DSN} =~ m/^dbi:mysql:/)) {
    %dsn = (
        DataSource  => $ENV{DBI_DSN},
        User        => $ENV{DBI_USER},
        Password    => $ENV{DBI_PASS},
        TableName   => 'sessions'
    );
}
else {
    %dsn = (
        DataSource  => $ENV{CGISESS_MYSQL_DSN},
        User        => $ENV{CGISESS_MYSQL_USER},
        Password    => $ENV{CGISESS_MYSQL_PASS},
        Socket      => $ENV{CGISESS_MYSQL_SOCKET},
        TableName   => 'sessions'
    );
}


use File::Spec;
use Test::More;
use CGI::Session::Test::Default;

for (qw/DBI DBD::mysql/) {
    eval "require $_";
    if ( $@ ) {
        plan(skip_all=>"$_ is NOT available");
        exit(0);
    }
}



require CGI::Session::Driver::mysql;
my $dsnstring = CGI::Session::Driver::mysql->_mk_dsnstr(\%dsn);

my $dbh;
eval { $dbh = DBI->connect($dsnstring, $dsn{User}, $dsn{Password}, {RaiseError=>0, PrintError=>0}) };
if ( $@ ) {
    plan(skip_all=>"Couldn't establish connection with the MySQL server: " . (DBI->errstr || $@));
    exit(0);
}

my $count;
eval { ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $dsn{TableName}") };
unless ( defined $count ) {
    unless( $dbh->do(qq|
        CREATE TABLE $dsn{TableName} (
            id CHAR(32) NOT NULL PRIMARY KEY,
            a_session TEXT NULL
        )|) ) {
        plan(skip_all=>"Couldn't create $dsn{TableName}: " . $dbh->errstr);
        exit(0);
    }
}


my $t = CGI::Session::Test::Default->new(
    dsn => "dr:mysql",
    args=>{Handle=>$dbh, TableName=>$dsn{TableName}});


plan tests => $t->number_of_tests + 2;
$t->run();

{
	# This used to test setting the global variable $CGI::Session::MySQL::TABLE_NAME.
	# However, since V 4.29_1, changes to CGI::Session::Driver's new() method mean
	# the unless test in CGI::Session::Driver::mysql's table_name() method was not executed,
	# and so $CGI::Session::MySQL::TABLE_NAME is never used. That 'unless' has been deleted.
	# V 4.32 explicitly documents this new situation. Moral: Don't use global variables.
	# This test was introduced in V 4.00_09.

    my $obj;
    eval {
        require CGI::Session::Driver::mysql;
        $obj = CGI::Session::Driver::mysql->new( {Handle=>$dbh} );
        $obj -> table_name('my_sessions');
    };
    is($@,'', 'survived eval');
    is($obj->table_name, 'my_sessions', "setting table name through the table_name() method works");
}





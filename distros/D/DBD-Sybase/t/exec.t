#!perl
#
# $Id: exec.t,v 1.9 2005/10/01 13:05:13 mpeppler Exp $

use lib 'blib/lib';
use lib 'blib/arch';

use lib 't';
use _test;

use strict;

#use Test::More qw(no_plan);
use Test::More tests => 22;


BEGIN { use_ok('DBI', ':sql_types');
        use_ok('DBD::Sybase');}


use vars qw($Pwd $Uid $Srv $Db);


#DBI->trace(3);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

#DBI->trace(3);
my $dbh = DBI->connect("dbi:Sybase:server=$Srv;database=$Db", $Uid, $Pwd, {PrintError=>1});
#exit;
ok(defined($dbh), 'Connect');

if(!$dbh) {
    warn "No connection - did you set the user, password and server name correctly in PWD?\n";
    for (4 .. 22) {
	ok(0);
    }
    exit(0);
}


$SIG{__WARN__} = sub { print @_; };
my $sth = $dbh->prepare("exec sp_helpindex \@objname = ?");
ok(defined($sth), 'Prepare sp_helpindex');

my $rc;

$rc = $sth->execute("sysusers");

ok(defined($rc), "exec sysusers");

get_all_results($sth);

#$dbh->do("use tempdb");
$dbh->do("set arithabort off");
$dbh->do("if object_id('dbitest') != NULL drop proc dbitest");
$rc = $dbh->do(qq{
create proc dbitest \@one varchar(20), \@two int, \@three numeric(5,2), \@four smalldatetime, \@five float output
as
    select \@one, \@two, \@three, \@four
    select * from master..sysprocesses

    return \@two
});

ok(defined($rc), "$rc (create proc)\n");

$sth = $dbh->prepare("exec dbitest \@one = ?, \@two = ?, \@three = ?, \@four = ?, \@five = ? output");
#$rc = $sth->execute("one", 2, 3.2, "jan 1 2001", 5.4);
ok(defined($sth), "prepare dbitest");
$sth->bind_param(1, "one");
$sth->bind_param(2, 2, SQL_INTEGER);
$sth->bind_param(3, 3.2, SQL_DECIMAL);
$sth->bind_param(4, "jan 1 2001");
$sth->bind_param(5, 5.4, SQL_FLOAT);
$rc = $sth->execute();
ok(defined($rc), "execute dbitest 1");
#DBI->trace(4);
get_all_results($sth);

$rc = $sth->execute("one", 25, 333.2, "jan 1 2001", 5.4);
ok(defined($rc), "exec dbitest 2");
get_all_results($sth);

$rc = $sth->execute(undef, 25, 3.2234, "jan 3 2001", 5.4);
ok(defined($rc), "exec dbitest 3");
my @out = $sth->func('syb_output_params');
ok($out[0] == 5.4, "out param 1");

#print "@out\n";
#do {
#    local $^W = 0;
#    while(my $d = $sth->fetch) {
#	print "@$d\n";
#    }
#} while($sth->{syb_more_results});

# test various failure modes:

$sth->{syb_do_proc_status} = 1;
$dbh->{syb_flush_finish} = 0;

$rc = $sth->execute(undef, 0, 3.2234, "jan 3 2001", 5.4);
ok(defined($rc), "execute fail mode 1");
get_all_results($sth);
#DBI->trace(3);
$rc = $sth->execute("raise", 1, 3.2234, "jan 3 2001", 5.4);
ok(defined($rc), "execute fail mode 2");
get_all_results($sth);
$rc = $sth->execute(undef, 0, 3.2234, "jan 3 2001", 5.4);
#DBI->trace(0);
ok(defined($rc), "execute fail mode 3");
get_all_results($sth);

$dbh->{syb_flush_finish} = 1;
$rc = $sth->execute(undef, 0, 3.2234, "jan 3 2001", 5.4);
ok(defined($rc), "execute fail mode 4");
get_all_results($sth);
#DBI->trace(3);
$rc = $sth->execute(undef, 1, 3.2234, "jan 3 2001", 5.4);
ok(defined($rc), "execute fail mode 5");
get_all_results($sth);
#DBI->trace(0);
$rc = $sth->execute(undef, 0, 3.2234, "jan 3 2001", 5.4);
ok(defined($rc), "execute fail mode 6");
get_all_results($sth);


$dbh->do("drop proc dbitest");

$dbh->do("if object_id('dbitest') != NULL drop proc dbitest");
$rc = $dbh->do(qq{
create proc dbitest \@one varchar(20), \@two int, \@three numeric(5,2), \@four smalldatetime --, \@five float = null output
as
    select \@one, \@two, \@three, \@four

});

ok(defined($rc), "$rc (create proc)\n");

$sth = $dbh->prepare("exec dbitest ?, ?, ?, ?");
$sth->bind_param(1, 'String 1', SQL_VARCHAR);
$sth->bind_param(2, 1, SQL_INTEGER);
$sth->bind_param(3, 3.25, SQL_DECIMAL);
$sth->bind_param(4, '2005-06-27', SQL_DATETIME);

for (0 .. 1) {
    $sth->execute('String 1', 1, 3.25, '2005-06-27');
    while(my $row = $sth->fetch) {
	ok($row->[2] == 3.25, "Implicit finish handling");
    }
}

$dbh->{syb_do_proc_status} = 1;
$sth = $dbh->prepare("exec dbitest ?, ?, ?, ?");
$sth->bind_param(1, 'String 1', SQL_VARCHAR);
$sth->bind_param(2, 1, SQL_INTEGER);
$sth->bind_param(3, 3.25, SQL_DECIMAL);
$sth->bind_param(4, '2005-06-27', SQL_DATETIME);

for (0 .. 1) {
    $sth->execute('String 1', 1, 3.25, '2005-06-27');
    while(my $row = $sth->fetch) {
	ok($row->[2] == 3.25, "Implicit finish handling");
    }
}

$dbh->do("drop proc dbitest");

sub get_all_results {
    my $sth = shift;

    do {
	while(my $d = $sth->fetch) {
	    #print "@$d\n";
	    ;
	}
    } while($sth->{syb_more_results});
}

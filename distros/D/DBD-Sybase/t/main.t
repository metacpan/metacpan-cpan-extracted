#!perl
#
# $Id: main.t,v 1.21 2010/04/07 20:53:38 mpeppler Exp $

# Base DBD Driver Test

use lib 't';
use _test;

use strict;

use Test::More tests=>38; 
#use Test::More qw(no_plan);

use Data::Dumper;

BEGIN { use_ok('DBI');
        use_ok('DBD::Sybase');}

use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

my($switch) = DBI->internal;
#DBI->trace(2); # 2=detailed handle trace

print "Switch: $switch->{'Attribution'}, $switch->{'Version'}\n";

print "Available Drivers: ",join(", ",DBI->available_drivers()),"\n";

my $dbh = DBI->connect("dbi:Sybase:$Srv;database=$Db", $Uid, $Pwd, {PrintError => 0});

ok(defined($dbh), 'Connect');
if(!$dbh) {
    warn "No connection - did you set the user, password and server name correctly in PWD?\n";
    for (4 .. 33) {
      ok(0);
    }
    exit(0);
}

print "Connect to server version: ", $dbh->{syb_server_version}, "\n";

my $rc;

$rc = $dbh->do("use master");
ok(defined($rc), 'use master');

my $sth;

$sth = $dbh->prepare("select * from sysusers");
ok(defined($sth), 'prepare select sysusers');

$rc = $sth->execute;
ok(defined($rc), 'execute');
ok($sth->{NUM_OF_FIELDS} > 0, 'FIELDS');
ok(@{$sth->{NAME}} > 0, 'NAME');
ok(@{$sth->{NULLABLE}} > 0, 'NULLABLE');

my $rows = 0;
while(my @dat = $sth->fetchrow) {
    ++$rows;
    foreach (@dat) {
	$_ = '' unless defined $_;
    }
    print "@dat\n";
}
ok($rows == $sth->rows, 'rows');
undef $sth;
$sth = $dbh->prepare("select * from sys_users");
ok(defined($rc), 'prepare');

$rc = $sth->execute;
ok(!defined($rc), 'execute (fail)');
ok($sth->err == 208, 'error code');

$sth = $dbh->prepare("select * from sysusers");
ok(defined($sth), 'prepare');

$rc = $sth->execute;
ok($rc, 'execute');
my @fields = @{$sth->{NAME}};
$rows = 0;
my $d;
my $ok = 1;
while($d = $sth->fetchrow_hashref) {
    ++$rows;
    foreach (@fields) {
	if(!exists($d->{$_})) {
	    $ok = 0;
	}
	my $t = $d->{$_} || '';
	print "$t ";
    }
    print "\n";
}
ok($ok, 'fetch');
ok($rows == $sth->rows, 'rows');

undef $sth;

$dbh->{LongReadLen} = 32000;

$dbh->{syb_quoted_identifier} = 1;

$rc = $dbh->do('create table #tmp("TR Number" int, "Answer Code" char(2))');
ok($rc, 'quoted identifier');

$rc = $dbh->do(qq(insert #tmp ("TR Number", "Answer Code") values(123, 'B')));
ok($rc, 'quoted identifier insert');

$dbh->{syb_quoted_identifier} = 0;

# Test multiple result sets, varying column names
$sth = $dbh->prepare("
select uid, name from sysusers where uid = -2
select spid, kpid, uid from master..sysprocesses where spid = \@\@spid
");
ok($sth, 'prepare multiple');
$rc = $sth->execute;
ok($rc, 'execute multiple');

my $result_set = 0;
do {
    while(my $row = $sth->fetchrow_hashref) {
	if($result_set == 1) {
	    ok(keys(%$row) == 3, 'number of columns, second result set');
	    ok($row->{spid} > 0, 'spid column in second result set');
	}
    }
    ++$result_set;
} while($sth->{syb_more_results});

# Test last_insert_id:
SKIP: {
    skip 'requires DBI 1.43', 1 unless $DBI::VERSION > 1.42;
    # This will only work w/ DBI >= 1.43
    $dbh->do("create table #idtest(id numeric(9,0) identity, c varchar(20))");
    $dbh->do("insert #idtest (c) values ('123456')");
#    DBI->trace(10);
    my $value = $dbh->last_insert_id(undef,undef,undef,undef);
    ok($value > 0, 'last insert id');
}

#my $ti = $dbh->type_info_all;
#foreach
my @type_info = $dbh->type_info(DBI::SQL_CHAR);
ok(@type_info >= 1, 'type_info');

ok(exists($type_info[0]->{DATA_TYPE}), 'type_info DATA_TYPE');

SKIP: {
    skip 'requires DBI 1.34', 3 unless $DBI::VERSION >= 1.34;
    my $sth = $dbh->prepare("select * from master..sysprocesses");
    $sth->execute;
    my @desc = $sth->syb_describe;
    ok($desc[0]->{NAME} eq 'spid', 'describe NAME');
    ok($desc[0]->{STATUS} =~ /CS_UPDATABLE/, 'describe STATUS');
    ok($desc[0]->{TYPE} == 8, 'describe TYPE');
}

$sth = $dbh->prepare(q|select uid, suser_name(uid), cpu, physical_io
from master..sysprocesses
order by uid
compute sum(cpu), sum(physical_io) by uid
		       |
);

ok($sth, "Prepare compute");
$rc = $sth->execute;
ok($rc, "execute compute");
my %seen_result_type_width;
while(my $row = $sth->fetch) {
    local $^W = 0;
    print "$sth->{syb_result_type}: @$row\n";
    $seen_result_type_width{ $sth->{syb_result_type} }->{ scalar @$row } = 1;
}
use Data::Dumper;
is_deeply( \%seen_result_type_width, {
    '4040' => { '4' => 1 }, # regular rows have 4 columns
    '4045' => { '2' => 1 }  # compute row has 2
}) or print Dumper(\%seen_result_type_width);

$sth->finish;


# Test new datatypes available with ASE 12.5.3
#

if($dbh->{syb_server_version} ge '12.5.3') {
    my $sth = $dbh->prepare("select convert(date, getdate()), convert(time, getdate())");
    $sth->execute;
    while(my $r = $sth->fetch) {
	    print "@$r\n";
    }
}

# Test new datatypes available with ASE 15
#

SKIP: {
    skip 'requires ASE 15 ', 2 if $dbh->{syb_server_version} lt '15' || $dbh->{syb_server_version} eq 'Unknown' || $dbh->{syb_server_version} eq 'MS-SQL';
    $dbh->{PrintError} = 1;
    my $sth = $dbh->prepare("select convert(unsigned smallint, power(2, 15)), convert(bigint, power(convert(bigint, 2), 32))");
    my $rc = $sth->execute;
    if ($rc) {
      while(my $r = $sth->fetch) {
        print "@$r\n";
        ok($r->[0] == 32768, "unsigned smallint");
        ok($r->[1] == 4294967296, "bigint");
      }
    } else {
      ok(0 == 1, "unsigned smallint");
      ok(0 == 1, "bigint");
    }
}

SKIP: {
    skip 'requires ASE 15.5 ', 4 if $dbh->{syb_server_version} lt '15.5' || $dbh->{syb_server_version} eq 'Unknown' || $dbh->{syb_server_version} eq 'MS-SQL';
    $dbh->{PrintError} = 1;
    $dbh->syb_date_fmt('LONGMS');
    my $sth = $dbh->prepare("select current_bigdatetime(), current_bigtime()");
    $sth->execute;
    while(my $r = $sth->fetch) {
      print "@$r\n";
      ok(1 == 1, "bigdatetime");
      ok(1 == 1, "bigtime");
    }

    $dbh->syb_date_fmt('ISO');

    my $sth = $dbh->prepare("select current_bigdatetime(), current_bigtime()");
    $sth->execute;
    while(my $r = $sth->fetch) {
      print "@$r\n";
      ok(1 == 1, "bigdatetime");
      ok(1 == 1, "bigtime");
    }

}


$dbh->disconnect;



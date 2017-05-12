#!perl
#
# $Id: xblob.t,v 1.12 2007/03/01 17:17:44 mpeppler Exp $

use lib 't';

use strict;

use _test;

use Test::More tests=>11; #qw(no_plan);

use vars qw($Pwd $Uid $Srv $Db $loaded);

BEGIN { use_ok('DBI');
        use_ok('DBD::Sybase');}

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

#DBI->trace(3);
my $dbh = DBI->connect("dbi:Sybase:server=$Srv;database=$Db", $Uid, $Pwd, {PrintError=>1});
#exit;
ok($dbh, 'Connect');

if(!$dbh) {
    warn "No connection - did you set the user, password and server name correctly in PWD?\n";
    for (4 .. 11) {
	ok(0);
    }
    exit(0);
}

$dbh->do("if object_id('blob_test') != NULL drop table blob_test");
my $rc = $dbh->do("create table blob_test(id int, data image null, foo varchar(30))");
ok($rc, 'Create table');

open(IN, "t/screen.jpg") || die "Can't open t/screen.jpg: $!";
binmode(IN);
my $image;
{
    local $/;
    $image = <IN>;
}
close(IN);
my $heximg = unpack('H*', $image);
$rc = $dbh->do("insert blob_test(id, data, foo) values(1, '', 'screen.jpg')");
ok($rc, 'Insert image');

#DBI->trace(3);
my $sth = $dbh->prepare("select id, data from blob_test");
#$sth->{syb_no_bind_blob} = 1;
$sth->execute;
while($sth->fetch) {
#    my $d;
#    $sth->func(2, \$d, 0, 'ct_get_data');
    
    $sth->func('CS_GET', 2, 'ct_data_info') || print $sth->errstr, "\n";
}
$sth->func('ct_prepare_send') || print $sth->errstr, "\n";
$sth->func('CS_SET', 2, {total_txtlen => length($image), log_on_update=>1}, 'ct_data_info') || print $sth->errstr, "\n";
$sth->func($image, length($image), 'ct_send_data') || print $sth->errstr, "\n";
$sth->func('ct_finish_send') || print $sth->errstr, "\n";

$dbh->{LongReadLen} = 100000;
$sth = $dbh->prepare("select id, data from blob_test");
#$dbh->{LongReadLen} = 100000;
#DBI->trace(3);
$sth->{syb_no_bind_blob} = 1;
$sth->execute;
my $heximg2 = '';
my $size = 0;
while(my $d = $sth->fetch) {
    my $data;
#    open(OUT, ">/tmp/mp_conf.jpg") || die "Can't open /tmp/mp_conf.jpg: $!";
    while(1) {
	my $read = $sth->func(2, \$data, 1024, 'ct_get_data');
	$heximg2 .= unpack('H*', $data);
	$size += $read;
	last unless $read == 1024;
#	print OUT $data;
    }
#    close(OUT);
}

#warn "Got $size bytes\n";

ok($heximg eq $heximg2, 'Images are the same');

mkdir("./tmp", 0755);
open(ONE, ">./tmp/hex1");
binmode(ONE);
print ONE $heximg;
close(ONE);
open(TWO, ">./tmp/hex2");
binmode(TWO);
print TWO $heximg2;
close(TWO);

$rc = $dbh->do("drop table blob_test");

ok($rc, 'Drop table');

SKIP: {
    skip 'Requires DBI 1.34', 4 unless $DBI::VERSION >= 1.34;
    my $rc = $dbh->do("create table blob_test(id int, data image null, foo varchar(30))");
    ok($rc, 'Creat table');

    open(IN, "t/screen.jpg") || die "Can't open t/screen.jpg: $!";
    binmode(IN);
    my $image;
    {
	local $/;
	$image = <IN>;
    }
    close(IN);
    my $heximg = unpack('H*', $image);
    $rc = $dbh->do("insert blob_test(id, data, foo) values(1, '', 'screen.jpg')");
    ok($rc, 'Insert image');


#DBI->trace(3);
    my $sth = $dbh->prepare("select id, data from blob_test");
#$sth->{syb_no_bind_blob} = 1;
    $sth->execute;
    while($sth->fetch) {
	#    my $d;
	#    $sth->func(2, \$d, 0, 'ct_get_data');
    
	$sth->syb_ct_data_info('CS_GET', 2) || print $sth->errstr, "\n";
    }
    $sth->syb_ct_prepare_send() || print $sth->errstr, "\n";
    $sth->syb_ct_data_info('CS_SET', 2, {total_txtlen => length($image), log_on_update=>1}) || print $sth->errstr, "\n";
    $sth->syb_ct_send_data($image, length($image)) || print $sth->errstr, "\n";
    $sth->syb_ct_finish_send() || print $sth->errstr, "\n";

#DBI->trace(4);
    $dbh->{LongReadLen} = 100000;
    $sth = $dbh->prepare("select id, data from blob_test");
    #$dbh->{LongReadLen} = 100000;
    #DBI->trace(0);
    #DBI->trace(3);
    $sth->{syb_no_bind_blob} = 1;
    $sth->execute;
    my $heximg2 = '';
    my $size = 0;
    while(my $d = $sth->fetch) {
	my $data;
	#    open(OUT, ">/tmp/mp_conf.jpg") || die "Can't open /tmp/mp_conf.jpg: $!";
	while(1) {
	    my $read = $sth->syb_ct_get_data(2, \$data, 1024);
	    $heximg2 .= unpack('H*', $data);
	    $size += $read;
	    last unless $read == 1024;
	    #	print OUT $data;
	}
	#    close(OUT);
    }

#warn "Got $size bytes\n";

    ok($heximg eq $heximg2, 'Images are the same');
    
    mkdir("./tmp");
    open(ONE, ">./tmp/hex1");
    binmode(ONE);
    print ONE $heximg;
    close(ONE);
    open(TWO, ">./tmp/hex2");
    binmode(TWO);
    print TWO $heximg2;
    close(TWO);

    $rc = $dbh->do("drop table blob_test");
					
    ok($rc, 'Drop table');
}

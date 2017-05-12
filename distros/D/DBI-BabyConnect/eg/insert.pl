#!/usr/bin/perl

#BEGIN { $ENV{BABYCONNECT} = '/opt/DBI-BabyConnect/configuration'; }

use strict;

use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",1);

my $dbb =
    $bbconn-> dbdriver =~ /Oracle/i ? 'ora' :
    $bbconn-> dbdriver =~ /Mysql/i ? 'mysql' :
    die "UNKNOWN DATA BASE WITH DRIVER $bbconn->dbdriver IS NOT SUPPORTED!\n";
my $SYSDATE = $dbb eq 'ora' ? 'SYSDATE' : 'SYSDATE()';

$bbconn->raiseerror(0);
$bbconn->printerror(1);
$bbconn->autocommit(0);
$bbconn->autorollback(1);

for (my $i=1; $i<=6; $i++) {
	my $lookup =  unpack('H*',pack('Ncs', time, $$ & 0xff, rand(0xffff)));

	my $sql = qq{
		INSERT INTO TABLE1 
		(LOOKUP,DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T) 
		VALUES 
		(?,?,?,?,'bin data',SYSDATE())
		};
	$bbconn-> sqlbnd($sql,$lookup,'data string',1000+$i,'binary code');
}

for (my $i=1; $i<=20; $i++) {
	my $lookup =  unpack('H*',pack('Ncs', time, $$ & 0xff, rand(0xffff)));

	my $sql = qq{
		INSERT INTO TABLE2 
		(LOOKUP,DATASTRING,DATANUM,PCODE_SREF,BIN_SREF,RECORDDATE_T) 
		VALUES 
		(?,?,?,?,'bin data',SYSDATE())
		};
	$bbconn-> sqlbnd($sql,$lookup,'data string',1000+$i,'binary code');
}

# No need to disconnect, because we set CALLER_DISCONNECT=0 
#$bbconn-> disconnect();


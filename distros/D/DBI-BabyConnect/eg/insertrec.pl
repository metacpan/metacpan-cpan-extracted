#!/usr/bin/perl

#BEGIN { $ENV{BABYCONNECT} = '/opt/DBI-BabyConnect/configuration'; }

use strict;

use DBI::BabyConnect;

my $bbconn = DBI::BabyConnect->new('BABYDB_001');
$bbconn-> HookError(">>/tmp/error.log");
$bbconn-> HookTracing(">>/tmp/db.log",1);

$bbconn->raiseerror(0);
$bbconn->printerror(1);
$bbconn->autocommit(0);
$bbconn->autorollback(1);

	my $lookup =  unpack('H*',pack('Ncs', time, $$ & 0xff, rand(0xffff)));

	my $dataStr = "This is a flower ...";
	my $img = getImg('flower_red_poinsettia.jpg');
	my %rec = (
		LOOKUP => \$lookup,
		DATASTRING => \$dataStr,
		DATANUM => 2000,
		BIN_SREF => \$img,
		RECORDDATE_T => 'SYSDATE()',
	);

	$bbconn-> insertrec( 'TABLE1', %rec );

sub getImg {
my $binfile = shift;
	open(BINFILE, $binfile) or die "can't open $binfile: $!";
	flock BINFILE,1;
	binmode(BINFILE);
	my $buff;
	my $binimg;
	while (read(BINFILE, $buff, 8 * 2**10)) {
		$binimg .= $buff;
	}
	close(BINFILE);
	return $binimg;
}


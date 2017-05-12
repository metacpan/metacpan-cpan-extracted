#!perl

# perl -w -Iblib/lib -Iblib/arch t/38createescalation.t 

use strict;
use ARS;
require './t/config.cache';

print "1..2\n";


my $ctrl = ars_Login( &CCACHE::SERVER, &CCACHE::USERNAME, &CCACHE::PASSWORD, "","", &CCACHE::TCPPORT );
if (defined($ctrl)) {
	print "ok [1] (login)\n";
} else {
	print "not ok [1] (login $ars_errstr)\n";
	exit(0);
}


#my @objects = sort {lc($a) cmp lc($b)} ars_GetListEscalation( $ctrl );
#die "ars_GetListEscalation( ALL ): $ars_errstr\n" if $ars_errstr;
#my @objects = ( 'zTEST:TimeInterval', 'zTEST:TimeDate' );
my @objects = ( 'ARSperl Test-escalation1' );


$| = 1;


foreach my $obj ( @objects ){
	next if $obj =~ / \((copy|renamed)\)$/;
	my $objNew = "$obj (copy)";
	ars_DeleteEscalation( $ctrl, $objNew );
	copyObject( $ctrl, $obj, $objNew );
}


sub copyObject {
	my( $ctrl, $obj, $objNew ) = @_;
	print '-' x 60, "\n";
#	print "GET ESCALATION $ctnr\n";
	my $wfObj = ars_GetEscalation( $ctrl, $obj );
	die "ars_GetEscalation( $obj ): $ars_errstr\n" if $ars_errstr;

#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;
#my $data = $ctnrObj;
#my $file = '-';
#local *FILE;
#open( FILE, "> $file" ) or die qq{Cannot open \"$file\" for writing: $!\n};
#print FILE Data::Dumper->Dump( [$data], ['ctnrObj'] );
#close FILE;

	$wfObj->{name} = $objNew;

	@{$wfObj->{objPropList}} = grep {$_->{prop} < 90000} @{$wfObj->{objPropList}};
#	foreach my $prop ( @{$ctnrObj->{objPropList}} ){
#		$prop->{value} .= 'xCopy' if $prop->{prop} == 60020 && $prop->{value} ne '';
#	}
	$wfObj->{changeDiary} = "Init";

	my $ret = 1;
	print "CREATE ESCALATION $objNew\n";
	$ret = ars_CreateEscalation( $ctrl, $wfObj );
	if( $ars_errstr ){
		if( $ars_errstr =~ /\[ERROR\]/ ){
			die "ars_CreateEscalation( $objNew ): $ars_errstr\n";
		}else{
			warn "ars_CreateEscalation( $objNew ): $ars_errstr\n";
		}
	}
	printStatus( $ret, 2, 'create escalation' );
}

sub printStatus {
	my( $ret, $num, $text, $err ) = @_;
	if( $ret ){
		print "ok [$num] ($text)\n";
	} else {
		print "not ok [$num] ($text $err)\n";
		exit(0);
	}
}


#ars_Logoff($ctrl);
sleep 5;
exit(0);





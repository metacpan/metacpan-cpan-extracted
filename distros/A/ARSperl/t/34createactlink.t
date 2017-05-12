#!perl

# perl -w -Iblib/lib -Iblib/arch t/34createactlink.t 

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


#my @objects = sort {lc($a) cmp lc($b)} ars_GetListActiveLink( $ctrl );
#die "ars_GetListActiveLink( ALL ): $ars_errstr\n" if $ars_errstr;
my @objects = ( 'ARSperl Test-alink1' );


$| = 1;


foreach my $obj ( @objects ){
	next if $obj =~ / \((copy|renamed)\)$/;
	my $objNew = "$obj (copy)";
	ars_DeleteActiveLink( $ctrl, $objNew );
	copyObject( $ctrl, $obj, $objNew );
}


sub copyObject {
	my( $ctrl, $obj, $objNew ) = @_;
	print '-' x 60, "\n";
#	print "GET ACTIVE LINK $ctnr\n";
	my $wfObj = ars_GetActiveLink( $ctrl, $obj );
	die "ars_GetActiveLink( $obj ): $ars_errstr\n" if $ars_errstr;

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
	print "CREATE ACTIVE LINK $objNew\n";
	$ret = ars_CreateActiveLink( $ctrl, $wfObj );
	if( $ars_errstr ){
		if( $ars_errstr =~ /\[ERROR\]/ ){
			die "ars_CreateActiveLink( $objNew ): $ars_errstr\n";
		}else{
			warn "ars_CreateActiveLink( $objNew ): $ars_errstr\n";
		}
	}
	printStatus( $ret, 2, 'create active link' );
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




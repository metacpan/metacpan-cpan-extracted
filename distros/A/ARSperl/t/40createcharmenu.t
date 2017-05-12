#!perl

# perl -w -Iblib/lib -Iblib/arch t/40createcharmenu.t 

use strict;
use warnings;
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


#my @objects = sort {lc($a) cmp lc($b)} ars_GetListCharMenu( $ctrl );
#die "ars_GetListCharMenu( ALL ): $ars_errstr\n" if $ars_errstr;
#my @objects = ( 'zTEST:CharMenu_List' );
my @objects = ( 'ARSperl Test-menu-search1' );


$| = 1;


foreach my $obj ( @objects ){
	next if $obj =~ / \((copy|renamed)\)$/;
	my $objNew = "$obj (copy)";
	ars_DeleteCharMenu( $ctrl, $objNew );
	copyObject( $ctrl, $obj, $objNew );
}


sub copyObject {
	my( $ctrl, $obj, $objNew ) = @_;
	print '-' x 60, "\n";
#	print "GET MENU $ctnr\n";
	my $wfObj = ars_GetCharMenu( $ctrl, $obj );
	die "ars_GetCharMenu( $obj ): $ars_errstr\n" if $ars_errstr;

#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;
#print Data::Dumper->Dump( [$wfObj], ['wfObj'] );

	$wfObj->{name} = $objNew;

	@{$wfObj->{objPropList}} = grep {$_->{prop} < 90000} @{$wfObj->{objPropList}};
#	foreach my $prop ( @{$ctnrObj->{objPropList}} ){
#		$prop->{value} .= 'xCopy' if $prop->{prop} == 60020 && $prop->{value} ne '';
#	}
	$wfObj->{changeDiary} = "Init";

	my $ret = 1;
	print "CREATE MENU $objNew\n";
	$ret = ars_CreateCharMenu( $ctrl, $wfObj );
	if( $ars_errstr ){
		if( $ars_errstr =~ /\[ERROR\]/ ){
			die "ars_CreateCharMenu( $objNew ): $ars_errstr\n";
		}else{
			warn "ars_CreateCharMenu( $objNew ): $ars_errstr\n";
		}
	}
	printStatus( $ret, 2, 'create menu' );
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





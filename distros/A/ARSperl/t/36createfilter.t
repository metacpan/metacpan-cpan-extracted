#!perl

# perl -w -Iblib/lib -Iblib/arch t/36createfilter.t 

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


#my @objects = sort {lc($a) cmp lc($b)} ars_GetListFilter( $ctrl );
#die "ars_GetListFilter( ALL ): $ars_errstr\n" if $ars_errstr;
my @objects = ( 'ARSperl Test-Filter1' );


$| = 1;


foreach my $obj ( @objects ){
	next if $obj =~ / \((copy|renamed)\)$/;
	my $objNew = "$obj (copy)";
	ars_DeleteFilter( $ctrl, $objNew );
	copyObject( $ctrl, $obj, $objNew );
}


sub copyObject {
	my( $ctrl, $obj, $objNew ) = @_;
	print '-' x 60, "\n";
#	print "GET FILTER $obj\n";
	my $wfObj = ars_GetFilter( $ctrl, $obj );
	die "ars_GetFilter( $obj ): $ars_errstr\n" if $ars_errstr;

#	use Data::Dumper;
#	$Data::Dumper::Sortkeys = 1;
#	print Data::Dumper->Dump( [$wfObj], ['wfObj'] );

	$wfObj->{name} = $objNew;

	@{$wfObj->{objPropList}} = grep {$_->{prop} < 90000} @{$wfObj->{objPropList}};
#	foreach my $prop ( @{$wfObj->{objPropList}} ){
#		$prop->{value} .= 'xCopy' if $prop->{prop} == 60020 && $prop->{value} ne '';
#	}
	$wfObj->{changeDiary} = "Init";

	my $ret = 1;
	print "CREATE FILTER $objNew\n";
	$ret = ars_CreateFilter( $ctrl, $wfObj );
	if( $ars_errstr ){
		if( $ars_errstr =~ /\[ERROR\]/ ){
			die "ars_CreateFilter( $objNew ): $ars_errstr\n";
		}else{
			warn "ars_CreateFilter( $objNew ): $ars_errstr\n";
		}
	}
	printStatus( $ret, 2, 'create filter' );
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





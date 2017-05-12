#!perl

# perl -w -Iblib/lib -Iblib/arch t/32createcontainer.t 

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


#my @containers = sort {lc($a) cmp lc($b)} map {$_->{containerName}} ars_GetListContainer( $ctrl, 0, &ARS::AR_HIDDEN_INCREMENT, &ARS::ARCON_ALL );
#die "ars_GetListContainer( ALL ): $ars_errstr\n" if $ars_errstr;
#my @containers = sort {lc($a) cmp lc($b)} map {$_->{containerName}} grep {$_->{containerType} =~ /guide/} ars_GetListContainer( $ctrl, 0, &ARS::AR_HIDDEN_INCREMENT, &ARS::ARCON_ALL );
#die "ars_GetListContainer( ALL ): $ars_errstr\n" if $ars_errstr;
my @containers = ( 'ARSperl Test-FilterGuide1' );


$| = 1;


foreach my $ctnr ( @containers ){
	next if $ctnr =~ / \((copy|renamed)\)$/;
	my $ctnrNew = "$ctnr (copy)";
	ars_DeleteContainer( $ctrl, $ctnrNew );
	copyContainer( $ctrl, $ctnr, $ctnrNew );
}


sub copyContainer {
	my( $ctrl, $ctnr, $ctnrNew ) = @_;
	print '-' x 60, "\n";
#	print "GET CONTAINER $ctnr\n";
	my $ctnrObj = ars_GetContainer( $ctrl, $ctnr );
	die "ars_GetContainer( $ctnr ): $ars_errstr\n" if $ars_errstr;
#	my $ctnrType = $ctnrObj->{containerType};

#	use Data::Dumper;
#	$Data::Dumper::Sortkeys = 1;
#	print Data::Dumper->Dump( [$ctnrObj], ['ctnrObj'] );

	$ctnrObj->{name} = $ctnrNew;

	@{$ctnrObj->{objPropList}} = grep {$_->{prop} < 90000} @{$ctnrObj->{objPropList}};
	foreach my $prop ( @{$ctnrObj->{objPropList}} ){
		$prop->{value} .= 'xCopy' if $prop->{prop} == 60020 && $prop->{value} ne '';
	}
	$ctnrObj->{changeDiary} = "Init";

	my $ret = 1;
	print "CREATE CONTAINER $ctnrNew\n";
	$ret = ars_CreateContainer( $ctrl, $ctnrObj );
	die "ars_CreateContainer( $ctnrNew ): $ars_errstr\n" if $ars_errstr;
	printStatus( $ret, 2, 'create container' );
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




#!perl

# perl -w -Iblib/lib -Iblib/arch t/35setactlink.t 

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


#my @objects = sort {lc($a) cmp lc($b)} grep {/\(copy\)/} ars_GetListActiveLink( $ctrl );
#die "ars_GetListActiveLink( ALL ): $ars_errstr\n" if $ars_errstr;
my @objects = ( 'ARSperl Test-alink1 (copy)' );


$| = 1;


foreach my $obj ( @objects ){
	next if $obj !~ / \(copy\)$/;
	my $objNew = $obj;
	$objNew =~ s/ \(copy\)$/ (renamed)/;
	ars_DeleteActiveLink( $ctrl, $objNew );
	modifyObject( $ctrl, $obj, $objNew );
}


sub modifyObject {
	my( $ctrl, $name, $newName ) = @_;
	print '-' x 60, "\n";
#	print "GET ACTIVE LINK $obj\n";
	my $wfObj = ars_GetActiveLink( $ctrl, $name );
	die "ars_GetActiveLink( $name ): $ars_errstr\n" if $ars_errstr;

	my $ret = 1;
	print "SET ACTIVE LINK $name\n";
	$ret = ars_SetActiveLink( $ctrl, $name, {name => $newName, enable => 0, order => 327} );
	die "ars_SetActiveLink( $name ): $ars_errstr\n" if $ars_errstr;
	printStatus( $ret, 2, 'set active link' );
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

sub makeRef {
	my( %args ) = @_;
	$args{label} = ''       if !exists $args{label};
	$args{description} = '' if !exists $args{description};
	if( $args{dataType} == 1 ){
		$args{permittedGroups} = [] if !exists $args{permittedGroups};
		$args{value}          = undef  if !exists $args{value};
		$args{value_dataType} = 'null' if !exists $args{value_dataType};
	}
	return \%args;	
}


#ars_Logoff($ctrl);
exit(0);




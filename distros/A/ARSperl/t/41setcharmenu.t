#!perl

# perl -w -Iblib/lib -Iblib/arch t/41setcharmenu.t 

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


#my @objects = sort {lc($a) cmp lc($b)} grep {/\(copy\)/} ars_GetListCharMenu( $ctrl );
#die "ars_GetListCharMenu( ALL ): $ars_errstr\n" if $ars_errstr;
#my @objects = ( 'zTEST:CharMenu_List (copy)' );
my @objects = ( 'ARSperl Test-menu-search1 (copy)' );


$| = 1;


foreach my $obj ( @objects ){
	next if $obj !~ / \(copy\)$/;
	my $objNew = $obj;
	$objNew =~ s/ \(copy\)$/ (renamed)/;
	ars_DeleteCharMenu( $ctrl, $objNew );
	modifyObject( $ctrl, $obj, $objNew );
}


sub modifyObject {
	my( $ctrl, $name, $newName ) = @_;
	print '-' x 60, "\n";
#	print "GET MENU $name\n";
	my $wfObj = ars_GetCharMenu( $ctrl, $name );
	die "ars_GetCharMenu( $name ): $ars_errstr\n" if $ars_errstr;

	my $ret = 1;
	print "SET MENU $name\n";
	$ret = ars_SetCharMenu( $ctrl, $wfObj->{name}, {name => $newName} );
	die "ars_SetCharMenu( $name ): $ars_errstr\n" if $ars_errstr;
	printStatus( $ret, 2, 'set menu' );
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





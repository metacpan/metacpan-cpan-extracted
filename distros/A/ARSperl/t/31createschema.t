#!perl

# perl -w -Iblib/lib -Iblib/arch t/31createschema.t 

use strict;
use ARS;
require './t/config.cache';

print "1..6\n";


my $ctrl = ars_Login( &CCACHE::SERVER, &CCACHE::USERNAME, &CCACHE::PASSWORD, "","", &CCACHE::TCPPORT );
if (defined($ctrl)) {
	print "ok [1] (login)\n";
} else {
	print "not ok [1] (login $ars_errstr)\n";
	exit(0);
}


#my %excl = map {$_ => 1} (
#	'Group',
#	'User', 
#	'Alert Events', 
#	'Application Pending', 
#	'Application Statistics', 
#	'Application Statistics Configuration',
#	'AR System Administrator Preference',
#);
#my @forms = sort {lc($a) cmp lc($b)} grep {$_ ge "BPM:MA:"} grep {/^BPM:/} ars_GetListSchema( $ctrl, 0, 1024 );			# all
#my @forms = sort {lc($a) cmp lc($b)} grep {/^BPM:/} ars_GetListSchema( $ctrl, 0, 1024 );			# all
#die "ars_GetListSchema( ALL ): $ars_errstr\n" if $ars_errstr;
#my @forms = ( 'ARSperl Test', 'ARSperl Test2', 'ARSperl Test-join', 'ARSperl Test3' );
my @forms = ( 'ARSperl Test3' );


$| = 1;


foreach my $form ( @forms ){
	next if $form =~ / \((copy|renamed)\)$/;
	my $formNew = "$form (copy)";
	ars_DeleteSchema( $ctrl, $formNew, 1 );
	copyForm( $ctrl, $form, $formNew );
}

my $formType;

sub copyForm {
	my( $ctrl, $form, $formNew ) = @_;
	print '-' x 60, "\n";
#	print "GET SCHEMA $form\n";
	my $formObj = ars_GetSchema( $ctrl, $form );
	die "ars_GetSchema( $form ): $ars_errstr\n" if $ars_errstr;
	my $formType = $formObj->{schema}{schemaType};
	$formObj->{name} = $formNew;
	$formObj->{changeDiary} = "Init";

	my( $aGetListFields, $aIndexList, $aSortList, $hArchiveInfo, $hAuditInfo );
	$aGetListFields = delete $formObj->{getListFields} if exists($formObj->{getListFields});
	$aIndexList     = delete $formObj->{indexList}     if exists($formObj->{indexList});
	$aSortList      = delete $formObj->{sortList}      if exists($formObj->{sortList});
	$hArchiveInfo   = delete $formObj->{archiveInfo}   if exists($formObj->{archiveInfo});
	$hAuditInfo     = delete $formObj->{auditInfo}     if exists($formObj->{auditInfo});
	$hArchiveInfo->{formName} .= ' (copy)' if $hArchiveInfo;

	foreach my $hProp ( @{$formObj->{objPropList}} ){
		$hProp->{value} .= 'copy' if $hProp->{prop} == 60018 && $hProp->{value};
	}

	my( $ret, $rv ) = ( 1, 0 );


	print "CREATE SCHEMA $formNew\n";
	$ret = ars_CreateSchema( $ctrl, $formObj );
	if( $ars_errstr ){
		my $errTxt = $ars_errstr;
#		$errTxt =~ s/\[WARNING\].*?\(ARERR #50\)/  (admin only)/;
#		$errTxt =~ s/\[WARNING\] rev_ARQualifierStruct: hv_fetch \(hval\) returned null \(ARERR #80020\)//;
		$errTxt =~ s/\[WARNING\].*?\(ARERR #8985\)/  (roles removed)/;
		$errTxt =~ s/\[WARNING\].*?\(ARERR #8981\)/  (app owner property)/;
		if( $errTxt =~ /ARERR/ ){
			print "ars_CreateSchema( $formNew ): $ars_errstr\n";
		}else{
			print $errTxt;
		}
	}


	print "\n";
	printStatus( $ret, 2, 'create schema' );
	sleep 5;

#	ars_DeleteVUI( $ctrl, $formNew, 536870912 );
#	die "ars_DeleteVUI( $formNew, 536870912 ): $ars_errstr\n" if $ars_errstr;


	my @views = ars_GetListVUI( $ctrl, $form, 0 );
	die "ars_GetListVUI( $form ): $ars_errstr\n" if $ars_errstr;

	my( $vuiId_New ) = ars_GetListVUI( $ctrl, $formNew, 0 );
	die "ars_GetListVUI( $formNew ): $ars_errstr\n" if $ars_errstr;


	my $vuiSt = ars_GetVUI( $ctrl, $formNew, $vuiId_New );
	die "ars_GetVUI( $formNew, $vuiId_New ): $ars_errstr\n" if $ars_errstr;
	foreach my $prop ( @{$vuiSt->{props}} ){
		$prop->{value} .= " $vuiId_New" if $prop->{prop} == 20;
	}
	$vuiSt->{vuiName} .= " $vuiId_New";
	print "SET VUI $vuiId_New\n";
	$ret = ars_SetVUI( $ctrl, $formNew, $vuiId_New, $vuiSt );
	die "ars_SetVUI( $formNew, $vuiId_New ): $ars_errstr\n" if $ars_errstr;
	printStatus( $ret, 3, 'set vui' );



	( $ret, $rv ) = ( 1, 0 );
	foreach my $vuiId ( @views ){
		$vuiSt = ars_GetVUI( $ctrl, $form, $vuiId );
		die "ars_GetVUI( $form, $vuiId ): $ars_errstr\n" if $ars_errstr;

		if( $vuiId == $vuiId_New ){ 
			print "SET VUI $vuiId\n";
			$rv = ars_SetVUI( $ctrl, $formNew, $vuiId, $vuiSt );
			die "ars_SetVUI( $formNew, $vuiId ): $ars_errstr\n" if $ars_errstr;
		}else{
			print "CREATE VUI $vuiId\n";
			$rv = ars_CreateVUI( $ctrl, $formNew, $vuiSt );
			die "ars_CreateVUI( $formNew, $vuiId ): $ars_errstr\n" if $ars_errstr;
		}
		$ret &&= $rv;
	}
	printStatus( $ret, 4, 'create vui' );

	my @fieldIds;
	push @fieldIds, sort {$a <=> $b} ars_GetListField( $ctrl, $form, 0,  0b00010000 );  # page_holder
	die "ars_GetListField( $form ): $ars_errstr\n" if $ars_errstr;
	push @fieldIds, sort {$a <=> $b} ars_GetListField( $ctrl, $form, 0, 0b00001000 );  # page
	die "ars_GetListField( $form ): $ars_errstr\n" if $ars_errstr;
	push @fieldIds, sort {$a <=> $b} ars_GetListField( $ctrl, $form, 0, 0b11110000111 );   # other
	die "ars_GetListField( $form ): $ars_errstr\n" if $ars_errstr;
	push @fieldIds, sort {$a <=> $b} ars_GetListField( $ctrl, $form, 0, 0b00100000 );  # table
	die "ars_GetListField( $form ): $ars_errstr\n" if $ars_errstr;
	push @fieldIds, sort {$a <=> $b} ars_GetListField( $ctrl, $form, 0, 0b01000000 );  # column
	die "ars_GetListField( $form ): $ars_errstr\n" if $ars_errstr;

	my %tableLimit;

	( $ret, $rv ) = ( 1, 0 );
	foreach my $fieldId ( @fieldIds ){
		my $fieldSt = ars_GetField( $ctrl, $form, $fieldId );
		die "ars_GetField( $form, $fieldId ): $ars_errstr\n" if $ars_errstr; 

#		test_DisplayInstanceList( $ctrl, $form, $fieldSt );
#		next;

		$fieldSt->{changeDiary} = "COPY";

		if( ($formType ne 'join' && $fieldId <= 8) || $fieldId == 1 ){
			print "SET FIELD $fieldId $fieldSt->{dataType}\n";
			$rv = ars_SetField( $ctrl, $formNew, $fieldId, {
				fieldName => $fieldSt->{fieldName},
				limit     => $fieldSt->{limit},
				displayInstanceList => $fieldSt->{displayInstanceList},
			} );
			warn "ars_SetField( $formNew, $fieldId ): $ars_errstr\n" if $ars_errstr;
		}elsif( ($formType eq 'join' && $fieldId > 1 && $fieldId != 15) || $fieldId > 15 ){
			print "CREATE FIELD $fieldId $fieldSt->{dataType}";
			if( $fieldSt->{dataType} eq 'table' ){
				$tableLimit{$fieldId} = { %{$fieldSt->{limit}} };
				$tableLimit{$fieldId}{qualifier} = $fieldSt->{limit}{qualifier};
				$fieldSt->{limit}{qualifier} = {};
			}

			$rv = ars_CreateField( $ctrl, $formNew, $fieldSt, 1 );
			if( $ars_errstr ){
				my $errTxt = $ars_errstr;
				$errTxt =~ s/\[WARNING\].*?\(ARERR #50\)/  (admin only)/;
				$errTxt =~ s/\[WARNING\].*?\(ARERR #8985\)/  (roles removed)/;
				$errTxt =~ s/\[WARNING\] rev_ARQualifierStruct: hv_fetch \(hval\) returned null \(ARERR #80020\)//;
				if( $errTxt =~ /ARERR/ ){
					print "  ars_CreateField( $formNew, $fieldId ): $ars_errstr\n";
				}else{
					print $errTxt;
				}
			}
			print "\n";
		}
		$ret &&= $rv;
	}
	sleep 5;
	foreach my $fieldId ( keys %tableLimit ){
		print "SET TABLE LIMIT $fieldId\n";
		$rv = ars_SetField( $ctrl, $formNew, $fieldId, {
			option   => 4,               # necessary to avoid ARERR 118
			limit    => $tableLimit{$fieldId},
		} );
		warn "ars_SetField( $formNew, $fieldId ): $ars_errstr\n" if $ars_errstr;
		$ret &&= $rv;
	}

	printStatus( $ret, 5, 'create/set field' );

	my %schemaInfo;
	$schemaInfo{getListFields} = $aGetListFields if $aGetListFields;
	$schemaInfo{indexList}     = $aIndexList     if $aIndexList;
	$schemaInfo{sortList}      = $aSortList      if $aSortList;
#	$schemaInfo{archiveInfo}   = $hArchiveInfo   if $hArchiveInfo;
	$schemaInfo{auditInfo}     = $hAuditInfo     if $hAuditInfo;

	print "SET SCHEMA $formNew\n";
	$ret = ars_SetSchema( $ctrl, $formNew, \%schemaInfo );
	warn "ars_SetSchema( $formNew ): $ars_errstr\n" if $ars_errstr;
	printStatus( $ret, 6, 'set schema' );
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
exit(0);



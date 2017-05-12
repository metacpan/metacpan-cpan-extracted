#
#    ARSperl - An ARS v5-v7 / Perl5 Integration Kit
#
#    Copyright (C) 1995-2007 Joel Murphy, jmurphy@acsu.buffalo.edu
#                            Jeff Murphy, jcmurphy@acsu.buffalo.edu
# 
#    This program is free software; you can redistribute it and/or modify
#    it under the terms as Perl itself. 
#    
#    Refer to the file called "Artistic" that accompanies the source distribution 
#    of ARSperl (or the one that accompanies the source distribution of Perl
#    itself) for a full description.
#
#    Official Home Page: 
#    http://www.arsperl.org
#
#    Mailing List (must be subscribed to post):
#    arsperl@arsperl.org
#

# Routines for grabbing the current error message "stack" 
# by simply referring to the $ars_errstr scalar.


package ARS::ERRORSTR;
sub TIESCALAR {
    bless {};
}
sub FETCH {
    my($s, $i) = (undef, undef);
    my(%mTypes) = ( 0 => "OK", 1 => "WARNING", 2 => "ERROR", 3 => "FATAL",
		    4 => "INTERNAL ERROR",
		   -1 => "TRACEBACK");
    for($i = 0; $i < $ARS::ars_errhash{numItems}; $i++) {

	# If debugging is not enabled, don't show traceback messages

	if($ARS::DEBUGGING == 1) {
	    $s .= sprintf("[%s] %s (ARERR \#%d)",
			  $mTypes{@{$ARS::ars_errhash{messageType}}[$i]},
			  @{$ARS::ars_errhash{messageText}}[$i],
			  @{$ARS::ars_errhash{messageNum}}[$i]);
	    $s .= "\n" if($i < $ARS::ars_errhash{numItems}-1);
	} else {
	    if(@{$ARS::ars_errhash{messageType}}[$i] != -1) {
		$s .= sprintf("[%s] %s (ARERR \#%d)",
			      $mTypes{@{$ARS::ars_errhash{messageType}}[$i]},
			      @{$ARS::ars_errhash{messageText}}[$i],
			      @{$ARS::ars_errhash{messageNum}}[$i]);
		$s .= "\n" if($i < $ARS::ars_errhash{numItems}-1);
	    }
	}
    }
    return $s;
}

package ARS;

require 5.005;
use strict "vars";
require Exporter;
require DynaLoader;
require Carp unless $^S;
use AutoLoader 'AUTOLOAD';
use Config;

require 'ARS/ar-h.pm';
require 'ARS/arerrno-h.pm';
require 'ARS/nparm.pm';

@ARS::ISA = qw(Exporter DynaLoader);
@ARS::EXPORT = qw(isa_int isa_float isa_string ars_LoadQualifier ars_Login 
ars_Logoff ars_GetListField ars_GetFieldByName ars_GetFieldTable 
ars_DeleteEntry ars_GetEntry ars_GetListEntry ars_GetListSchema 
ars_GetListServer ars_GetActiveLink ars_GetCharMenuItems ars_GetSchema 
ars_ExpandCharMenu
ars_GetField ars_simpleMenu ars_GetListActiveLink ars_SetEntry 
ars_perl_qualifier ars_qualifier_ptr ars_Export ars_GetListFilter ars_GetListEscalation 
ars_GetListCharMenu ars_padEntryid 
ars_GetFilter ars_SetFilter
ars_GetListEntryWithFields ars_GetMultipleEntries
ars_GetProfileInfo ars_Import ars_GetCharMenu ars_GetServerStatistics 
ars_GetCurrentServer ars_EncodeDiary 
ars_CreateEntry ars_MergeEntry ars_DeleteFilter
ars_DeleteMultipleFields ars_DeleteActiveLink
ars_DeleteCharMenu
ars_DeleteEscalation ars_DeleteField ars_DeleteSchema
ars_DeleteVUI ars_ExecuteProcess
ars_GetEscalation ars_GetFullTextInfo
ars_GetListGroup ars_GetListSQL ars_GetListUser ars_GetListRole
ars_GetListVUI 
ars_GetServerInfo ars_SetServerInfo
ars_GetEntryBLOB
ars_CreateActiveLink
ars_GetControlStructFields ars_GetVUI
ars_GetListContainer ars_GetContainer ars_DeleteContainer ars_SetServerPort
ars_SetLogging ars_SetSessionConfiguration ars_SetImpersonatedUser
ars_CreateField ars_SetField ars_CreateSchema ars_SetSchema ars_CreateVUI ars_SetVUI
ars_CreateContainer ars_SetContainer ars_CreateCharMenu ars_SetCharMenu
ars_SetActiveLink ars_CreateFilter ars_CreateEscalation ars_SetEscalation
$ars_errstr %ARServerStats %ars_errhash
ars_decodeStatusHistory ars_APIVersion ars_encodeStatusHistory
ars_BeginBulkEntryTransaction ars_EndBulkEntryTransaction
ars_Signal ars_GetTextForErrorMessage ars_DateToJulianDate
ars_GetListLicense ars_ValidateMultipleLicenses
ars_GetServerCharSet ars_GetClientCharSet
ars_GetAlertCount ars_RegisterForAlerts ars_DeregisterForAlerts ars_GetListAlertUser
ars_DecodeAlertMessage ars_CreateAlertEvent ars_VerifyUser
ars_GetListImage ars_GetImage ars_CreateImage ars_SetImage ars_DeleteImage
ars_GetListEntryWithMultiSchemaFields
ars_GetSessionConfiguration
ars_SetOverlayGroup ars_SwitchToBestPracticeMode ars_SwitchToBaseMode
);

$ARS::VERSION   = '2.00';
$ARS::DEBUGGING = 0;

$ARS::logging_file_ptr = 0;


# definitions required for backwards compatibility

if (!defined &ARS::AR_IMPORT_OPT_CREATE) {
	eval 'sub AR_IMPORT_OPT_CREATE { 0; }';
}

if (!defined &ARS::AR_IMPORT_OPT_OVERWRITE) {
	eval 'sub AR_IMPORT_OPT_OVERWRITE { 1; }';
}

bootstrap ARS $ARS::VERSION;
tie $ARS::ars_errstr, ARS::ERRORSTR;

# This HASH is used by the ars_GetServerStatistics call.
# Refer to your ARS API Programmer's Manual or the "ar.h"
# file for an explaination of what each of these stats are.
#
# Usage of this hash would be something like:
#
# %stats = ars_GetServerStatistics($ctrl, 
#          $ARServerStats{'START_TIME'}, 
#          $ARServerStats{'CPU'});
#

%ARS::ARServerStats = (
 'START_TIME'      ,1,
 'BAD_PASSWORD'    ,2,
 'NO_WRITE_TOKEN'  ,3,
 'NO_FULL_TOKEN'   ,4,
 'CURRENT_USERS'   ,5,
 'WRITE_FIXED'     ,6,
 'WRITE_FLOATING'  ,7,
 'WRITE_READ'      ,8,
 'FULL_FIXED'      ,9,
 'FULL_FLOATING'  ,10,
 'FULL_NONE'      ,11,
 'API_REQUESTS'   ,12,
 'API_TIME'       ,13,
 'ENTRY_TIME'     ,14,
 'RESTRUCT_TIME'  ,15,
 'OTHER_TIME'     ,16,
 'CACHE_TIME'     ,17,
 'GET_E_COUNT'    ,18,
 'GET_E_TIME'     ,19,
 'SET_E_COUNT'    ,20,
 'SET_E_TIME'     ,21,
 'CREATE_E_COUNT' ,22,
 'CREATE_E_TIME'  ,23,
 'DELETE_E_COUNT' ,24,
 'DELETE_E_TIME'  ,25,
 'MERGE_E_COUNT'  ,26,
 'MERGE_E_TIME'   ,27,
 'GETLIST_E_COUNT' ,28,
 'GETLIST_E_TIME' ,29,
 'E_STATS_COUNT'  ,30,
 'E_STATS_TIME'   ,31,
 'FILTER_PASSED'  ,32,
 'FILTER_FAILED'  ,33,
 'FILTER_DISABLE' ,34,
 'FILTER_NOTIFY'  ,35,
 'FILTER_MESSAGE' ,36,
 'FILTER_LOG'     ,37,
 'FILTER_FIELDS'  ,38,
 'FILTER_PROCESS' ,39,
 'FILTER_TIME'    ,40,
 'ESCL_PASSED'    ,41,
 'ESCL_FAILED'    ,42,
 'ESCL_DISABLE'   ,43,
 'ESCL_NOTIFY'    ,44,
 'ESCL_LOG'       ,45,
 'ESCL_FIELDS'    ,46,
 'ESCL_PROCESS'   ,47,
 'ESCL_TIME'      ,48,
 'TIMES_BLOCKED'  ,49,
 'NUMBER_BLOCKED' ,50,
 'CPU'            ,51,
 'SQL_DB_COUNT'   ,52,
 'SQL_DB_TIME'    ,53,
 'FTS_SRCH_COUNT' ,54,
 'FTS_SRCH_TIME'  ,55,
 'SINCE_START'    ,56,
 'IDLE_TIME', 57,
 'NET_RESP_TIME', 58,
 'FILTER_FIELDP', 59,
 'ESCL_FIELDP', 60,
 'FILTER_SQL', 61,
 'ESCL_SQL', 62,
 'NUM_THREADS', 63,
 'FILTER_GOTO_ACTION', 64,
 'FILTER_CALL_GUIDE', 65,
 'FILTER_EXIT_GUIDE', 66,
 'FILTER_GOTO_GUIDE_LB', 67,
 'FILTER_FIELDS_SQL', 68,
 'FILTER_FIELDS_PROCESS', 69,
 'FILTER_FIELDS_FLTAPI', 70,
 'ESCL_FIELDS_SQL', 71,
 'ESCL_FIELDS_PROCESS', 72,
 'ESCL_FIELDS_FLTAPI', 73,
 'WRITE_RESTRICTED_READ', 74
);


sub new {
	require 'ARS/OOform.pm';
	require 'ARS/OOmsgs.pm';
	require 'ARS/OOsup.pm';
	return newObject( @_ );
}


# ROUTINE
#   ars_simpleMenu(menuItems, prepend)
#
# DESCRIPTION
#   merges all sub-menus into a single level menu. good for web 
#   interfaces.
#
# RETURNS
#   array of menu items.

sub ars_simpleMenu {
    my($m) = shift;
    my($prepend) = shift;
    my(@m) = @$m;
    my(@ret, @submenu);
    my($name, $val);
    
    while (($name, $val, @m) = @m) {
	if (ref($val)) {
	    @submenu = ars_simpleMenu($val, $name);
	    @ret = (@ret, @submenu);
	} else {
	    if ($prepend) {
		@ret = (@ret, "$prepend/$name", $val);
	    } else {
		@ret = (@ret, $name, $val);
	    }
	}
    }
    @ret;
}

# ROUTINE
#   ars_padEntryid(control, schema, entry-id)
#
# DESCRIPTION
#   this routine will left-pad the entry-id with
#   zeros out to the appropriate number of place (15 max)
#   depending upon if your prefix your entry-id's with
#   anything
#
# RETURNS
#   a new scalar on success
#   undef on error

sub ars_padEntryid {
	my($c) = shift;
	my($schema) = shift;
	my($entry_id) = shift;
	my($field);

	# entry id field is field id #1
	($field = ars_GetField($c, $schema, 1)) ||
	return undef;
	if( $field->{defaultVal} ){
		return $field->{defaultVal}.("0"x($field->{limit}{maxLength}-length($field->{defaultVal})-length($entry_id))).$entry_id;
	}else{
		return ("0"x($field->{limit}{maxLength}-length($entry_id))).$entry_id;
	}	
}

# ROUTINE
#   ars_decodeStatusHistory(field-value)
#
# DESCRIPTION
#   this routine, when given an encoded status history field
#   (returned by GetEntry) will decode it into a hash like:
#
#   $retval[ENUM]->{USER}
#   $retval[ENUM]->{TIME}
#
#   so if you have a status field that has two states: Open and Closed,
#   where Open is enum 0 and Closed is enum 1, this routine will return:
#
#   $retval[0]->{USER} = the user to last selected this enum
#   $retval[1]->{TIME} = the time that this enum was last selected
#
#   You can map from enum values to selection words by using 
#   arsGetField().

sub ars_decodeStatusHistory {
    my ($sval) = shift;
    my ($enum) = 0;
    my ($pair, $ts, $un);
    my (@retval);

    foreach $pair (split(/\003/, $sval)) {
	if($pair ne "") {
	    ($ts, $un) = split(/\004/, $pair);
	    $retval[$enum]->{USER} = $un;
	    $retval[$enum]->{TIME} = $ts;
	} else {
	    # no value for this enumeration
	    $retval[$enum]->{USER} = undef;
	    $retval[$enum]->{TIME} = undef;
	}
	$enum++;
    }

    return @retval;
}

#define AR_DEFN_DIARY_SEP        '\03'     /* diary items separator */
#define AR_DEFN_DIARY_COMMA      '\04'     /* char between date/user/text */

# ROUTINE
#   ars_EncodeDiary(diaryhash1, diaryhash2, ...)
#
# DESCRIPTION
#   given a list of diary hashs (see ars_GetEntry), 
#   encode them into an ars-internal diary string. this can 
#   then be fed into ars_MergeEntry() in order to alter the contents
#   of an existing diary entry.
#
# RETURNS
#   an encoded diary string (scalar) on success
#   undef on failure

sub ars_EncodeDiary {
    my ($diary_string) = undef;
    my ($entry);
    foreach $entry (@_) {
	$diary_string .= $entry->{timestamp}.pack("c",4).$entry->{user}.pack("c",4).$entry->{value};
	$diary_string .= pack("c",3) if ($diary_string);
    }
    return $diary_string;
}

sub insertValueForCurrentTransaction {
	my ($c, $s, $q) = (shift, shift, shift);

	die Carp::longmess("Usage: insertValueForCurrentTransaction(ctrl, schema, qualifier, ...)\n")
	  if(!defined($q));
	
	die Carp::longmess("Usage: insertValueForCurrentTransaction(ctrl, schema, qualifier, ...)\nEven number of arguments must follow 'qualifier'\n")
	  if($#_ % 2 == 1);

	#foreach (field, value) pair {
	#    look up field
	#    if field = text then wrap value in double quotes
	#    if field = numeric then no quotes
	#    search thru qual and change field ref to value
	#}
	# compile new qual
	# pass to Expand2

	if(ref($q) eq "ARQualifierStructPtr") {
		$q = ars_perl_qualifier($c, $q);
		die Carp::longmess("ars_perl_qualifier failed: $ARS::ars_errstr")
		  unless defined($q);
	}
	if(0) {
	while($#_) {
		my ($f, $v) = (shift @_, shift @_);
		my $fh = ars_GetField($c, $s, $f);
		if(($fh->{'dataType'} eq "char") ||
		   ($fh->{'dataType'} eq "diary")) {
			$v = "\"$v\"";
		}
	}
}
	print "walktree..\n";
	walkTree($q);
	exit 0;
}

sub walkTree {
	my $q = shift;
	print "($q) ";
	if(defined($q->{'oper'})) {
		print "oper: ".$q->{'oper'}."\n";
		if($q->{'oper'} eq "not") {
			walkTree($q->{'not'});
			return;
		} elsif($q->{'oper'} eq "rel_op") {
			walkTree($q->{'rel_op'});
			return;
		} else {
			walkTree($q->{'left'});
			walkTree($q->{'right'});
			return;
		}
	}
	else { 
		if(defined($q->{'left'}{'queryCurrent'})) {
			print "l ", $q->{'left'}{'queryCurrent'}, "\n";
		}
		if(defined($q->{'right'}{'queryCurrent'})) {
			print "r ", $q->{'right'}{'queryCurrent'}, "\n";
		}

		foreach (keys %$q) {
			print "key: ", $_,"\n";
			print "val: ", $q->{$_},"\n";
			dumpHash ($q->{$_}) if(ref($q->{$_}) eq "HASH");
		}
	}
}

sub dumpHash {
	my $h = shift;
	foreach (keys %$h) {
		print "key: ", $_,"\n";
		print "val: ", $h->{$_},"\n";
		dumpHash($h->{$_}) if(ref($h->{$_}) eq "HASH");
	}
}	
	
# ars_GetCharMenuItems(ctrl, menuName, qualifier)
#  qual is optional. 
#    if it's specified:
#       menuType must be "query"
#       qualifier must compile against the form that the menu 
#       is written for.

sub ars_GetCharMenuItems {
	my ($ctrl, $menuName, $qual) = (shift, shift, shift);

	if(defined($qual)) {
		my $menu = ars_GetCharMenu($ctrl, $menuName);
		die "ars_GetCharMenuItems failed: $ARS::ars_errstr" 
		  unless defined($menu);
		die "ars_GetCharMenuItems failed: qualifier was specified, but menu is not a 'query' menu" 
		  if($menu->{'menuType'} ne "query");
		
		if(ref($qual) ne "ARQualifierStruct") {
			$qual = ars_LoadQualifier($ctrl, $menu->{'menuQuery'}{'schema'}, $qual);
		}
		return ars_ExpandCharMenu2($ctrl, $menuName, $qual);
	}
	return ars_ExpandCharMenu2($ctrl, $menuName);
}

sub ars_ExpandCharMenu {
	return ars_ExpandCharMenu2(@_);
}

# encodes status history from the same format
# as returned by ars_decodeStatusHistory()

sub ars_encodeStatusHistory {
	my @sh = ();
	while(my $hr = shift) {
		push @sh, $hr->{USER} ? "$hr->{TIME}\cD$hr->{USER}" : "";
	}
	join "\cC", @sh;
}

sub ars_SetOverlayGroup {
	my ($ctrl, $value) = (shift, shift);
	ars_SetSessionConfiguration($ctrl, 12, $value);
	ars_SetSessionConfiguration($ctrl, 13, $value);
}

sub ars_SwitchToBaseMode {
	my $ctrl = shift;
	ars_SetOverlayGroup($ctrl, 0);
}

sub ars_SwitchToBestPracticeMode {
	my $ctrl = shift;
	ars_SetOverlayGroup($ctrl, 1);
}

# As of ARS4.0, these routines (which call ARInitialization and ARTermination)
# need to pass a control struct. this means that we now must move them into
# ars_Login and ars_Logoff in order to have access to that control struct.
# the implications of this are that your script should always call ars_Logoff()
# inorder to ensure that licenses are released (i.e. ARTermination is called)
# as for ARInitialization: this is used for private servers, mostly, and shouldnt
# affect anything by moving it into the ars_Login call.

# call ARInitialization
ARS::__ars_init() if(&ARS::ars_APIVersion() < 4);


1;
__END__


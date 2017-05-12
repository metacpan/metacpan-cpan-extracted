#!/ms/dist/perl5/bin/perl5.8 -w
#
# check_config_params - Cross-verify configuration parameters
#                       and known DB2 constants.
#
# $Id: check_config_params.pl,v 165.1 2009/04/22 14:07:15 biersma Exp $
#

use strict;
use DB2::Admin::Constants;

my $config_params = $DB2::Admin::Constants::config_params;
print "Will verify [" . (keys %$config_params) . "] config parameters\n";

#
# Known obsolete config parameters (from <sqlutil.h> in V7.1)
#
my @obsolete_v71 = qw(SQLF_DBTN_ADSM_MGMTCLASS
		      SQLF_DBTN_ADSM_NODENAME
		      SQLF_DBTN_ADSM_OWNER
		      SQLF_DBTN_ADSM_PASSWD
		      SQLF_DBTN_ADSM_PASSWORD
		      SQLF_DBTN_AGENTHEAP
		      SQLF_DBTN_APPLHEAPSZ_P
		      SQLF_DBTN_BUFFPAGE
		      SQLF_DBTN_DBHEAP
		      SQLF_DBTN_DBHEAP_P
		      SQLF_DBTN_DETS
		      SQLF_DBTN_DL_NUM_BACKUP
		      SQLF_DBTN_INTFLAGS
		      SQLF_DBTN_LOGEXT
		      SQLF_DBTN_LOGFILE
		      SQLF_DBTN_LOGFILSIZ
		      SQLF_DBTN_LOGMAXEXT
		      SQLF_DBTN_MAXTOTFILOP
		      SQLF_DBTN_MULTIPGAL
		      SQLF_DBTN_NEXTACTIVE
		      SQLF_DBTN_SEGPAGES
		      SQLF_DBTN_SORTHEAP
		      SQLF_DBTN_SORTHEAPSZ_P
		      SQLF_DBTN_STMTHEAPSZ_P
		      SQLF_KTN_ADSM_NODENAME
		      SQLF_KTN_ADSM_OWNER
		      SQLF_KTN_ADSM_PASSWORD
		      SQLF_KTN_COMHEAPSZ
		      SQLF_KTN_COMHEAPSZ_P
		      SQLF_KTN_CUINTERVAL
		      SQLF_KTN_IPX_FILESERVER
		      SQLF_KTN_IPX_OBJECTNAME
		      SQLF_KTN_MAX_IDLEAGENTS
		      SQLF_KTN_NUMRC
		      SQLF_KTN_RSHEAPSZ
		      SQLF_KTN_RSHEAPSZ_P
		      SQLF_KTN_SQLENSEG
		      SQLF_KTN_SQLSTMTSZ
                      SQLF_KTN_SVRIOBLK);

my @obsolete_v81 = qw(SQLF_DBTN_ADSM_MGMTCLASS
		      SQLF_DBTN_ADSM_NODENAME
		      SQLF_DBTN_ADSM_OWNER
		      SQLF_DBTN_ADSM_PASSWD
		      SQLF_DBTN_ADSM_PASSWORD
		      SQLF_DBTN_AGENTHEAP
		      SQLF_DBTN_APPLHEAPSZ_P
		      SQLF_DBTN_BUFFPAGE
		      SQLF_DBTN_DBHEAP
		      SQLF_DBTN_DBHEAP_P
		      SQLF_DBTN_DETS
		      SQLF_DBTN_DL_NUM_BACKUP
		      SQLF_DBTN_INTFLAGS
		      SQLF_DBTN_LOCKLIST
		      SQLF_DBTN_LOGEXT
		      SQLF_DBTN_LOGFILE
		      SQLF_DBTN_LOGFILSIZ
		      SQLF_DBTN_LOGMAXEXT
		      SQLF_DBTN_MAXTOTFILOP
		      SQLF_DBTN_MULTIPGAL
		      SQLF_DBTN_NEXTACTIVE
		      SQLF_DBTN_SEGPAGES
		      SQLF_DBTN_SORTHEAP
		      SQLF_DBTN_SORTHEAPSZ_P
		      SQLF_DBTN_STMTHEAPSZ_P
		      SQLF_KTN_COMHEAPSZ
		      SQLF_KTN_COMHEAPSZ_P
		      SQLF_KTN_CUINTERVAL
		      SQLF_KTN_IPX_FILESERVER
		      SQLF_KTN_IPX_OBJECTNAME
		      SQLF_KTN_MAX_IDLEAGENTS
		      SQLF_KTN_NUMRC
		      SQLF_KTN_RSHEAPSZ
		      SQLF_KTN_RSHEAPSZ_P
		      SQLF_KTN_SQLENSEG
		      SQLF_KTN_SQLSTMTSZ
		      SQLF_KTN_SVRIOBLK
		     );

my @obsolete_v82 = qw(SQLF_DBTN_INDEXSORT
		      SQLF_DBTN_STMTHEAP
		      SQLF_DBTN_TERRITORY);

my @obsolete_v95 = qw(SQLF_KTN_MAXAGENTS
		      SQLF_KTN_MAXCAGENTS
		      SQLF_KTN_MIN_PRIV_MEM
		      SQLF_KTN_PRIV_MEM_THRESH
		      SQLF_KTN_UDF_MEM_SZ
		      SQLF_KTN_DOS_RQRIOBLK
		      SQLF_KTN_DIR_TYPE
		      SQLF_KTN_DIR_PATH_NAME
		      SQLF_KTN_DIR_OBJ_NAME
		      SQLF_KTN_ROUTE_OBJ_NAME
		      SQLF_KTN_DFT_CLIENT_COMM
		      SQLF_KTN_DFT_CLIENT_ADPT
		      SQLF_KTN_FCM_NUM_RQD
		      SQLF_KTN_FCM_NUM_CONNECT
		      SQLF_KTN_FCM_NUM_ANCHORS
		      SQLF_KTN_SS_LOGON
		     );

my @ibm_internal = qw(SQLF_DBTN_AUTO_DB_BACKUP
		      SQLF_DBTN_AUTO_DB_BACKUP_EFF
		      SQLF_DBTN_AUTO_MAINT
		      SQLF_DBTN_AUTO_MAINT_EFF
		      SQLF_DBTN_AUTO_PROF_UPD
		      SQLF_DBTN_AUTO_PROF_UPD_EFF
		      SQLF_DBTN_AUTO_REORG
		      SQLF_DBTN_AUTO_REORG_EFF
		      SQLF_DBTN_AUTO_RUNSTATS
		      SQLF_DBTN_AUTO_RUNSTATS_EFF
		      SQLF_DBTN_AUTO_STATS_PROF
		      SQLF_DBTN_AUTO_STATS_PROF_EFF
		      SQLF_DBTN_AUTO_TBL_MAINT
		      SQLF_DBTN_AUTO_TBL_MAINT_EFF
		      SQLF_DBTN_NOTOKEN
		      SQLF_KTN_NOTOKEN
		     );

my $errors = 0;
my $warnings = 0;

#
# ALl entries should have:
# - Type
# - Name
# - Domain
# - Updatable
#
while (my ($param, $info) = each %$config_params) {
    foreach my $req (qw(Type Name Updatable Domain)) {
	next if (defined $info->{$req});
	print "Constant '$param' does not have required field '$req'\n";
	$errors++;
    }
}


#
# The constant name should be related to the parameter name
# (with some exceptions)
#
while (my ($param, $info) = each %$config_params) {
    die "Cannot parse parameter [$param]"
      unless ($param =~ /^SQLF_(?:DB|K)TN_(.*)/);
    my $short_param = lc($1);
    my $name = $info->{'Name'};
    next if ($short_param eq $name);
    $short_param =~ s/_//g;
    $name =~ s/_//gg;
    next if ($short_param eq $name);
    next if ($info->{Name} =~ m!(?:database_consistent)$!);
    print "Constant '$param' has conflicting name '$info->{Name}'\n";
    $errors++;
}


#
# The 'Type' field should be a supported data type
#
while (my ($param, $info) = each %$config_params) {
    my $type = $info->{'Type'};
    next if ($type =~ m!^(?:string|float)$!);
    next if ($type =~ m!^u?(?:16|32|64)bit$!);
    print "Constant '$param' has invalid type '$type'\n";
    $errors++;
}

#
# All entries marked as 'NUM', 'MIN' or 'MAX' should be numeric
#
while (my ($param, $info) = each %$config_params) {
    next unless ($param =~ /^SQLF_DBTN_(?:NUM|MIN|MAX)/);
    if ($info->{'Type'} eq 'string') {
	print "Constant '$param' is type string, expected number\n";
	$errors++;
    }
}

#
#  All String entries should have a Length, and non-strings should not
#
while (my ($param, $info) = each %$config_params) {
    if ($info->{'Type'} eq 'string') {
	unless  (defined $info->{'Length'}) {
	    print "Constant '$param' is type string but has no length\n";
	    $errors++;
	}
    } elsif (defined $info->{'Length'}) {
	print "Constant '$param' is type $info->{'Type'} but has a length\n";
	$errors++;
    }
}

#
# All configuration parameters should be known constants, have
# Type 'Number' and Category 'ConfigParam'
#
foreach my $param (sort keys %$config_params) {
    my $info = DB2::Admin::Constants::->GetInfo($param);
    unless (defined $info) {
	print "Constant '$param' is not known to DB2::Admin::Constants\n";
	$errors++;
	next;
    }
    unless ($info->{'Type'} eq 'Number') {
	print "Constant '$param' is not known as a number to DB2::Admin::Constants\n";
	$errors++
    }
    unless (defined $info->{'Category'} &&$
	    info->{'Category'} eq 'ConfigParam') {
	print "Constant '$param' is not known as a ConfigParam to DB2::Admin::Constants\n";
	$errors++
    }
}

#
# All DB2::Admin constants marked as 'ConfigParam' should be known, or
# known to be obsolete.  IBM-internal constyants should not have a
# description.
#
foreach my $constant (sort keys %$DB2::Admin::Constants::constant_info) {
    my $info = $DB2::Admin::Constants::constant_info->{$constant};
    next unless (defined $info->{'Category'} &&
		 $info->{'Category'} eq 'ConfigParam');

    if (grep { $_ eq $constant } @ibm_internal) {
	if (defined $config_params->{$constant}) {
	    print "DB2::Admin::Constants '$constant' is IBM-internal and should not be in the configuration parameter table\n";
	    $errors++;
	}
	next;
    }
    next if (defined $config_params->{$constant});
    next if (grep { $_ eq $constant } @obsolete_v71, @obsolete_v81, @obsolete_v82, @obsolete_v95);
    #next if ($constant =~ m!^SQLF_KTN_!);
    print "DB2::Admin::Constants '$constant' is not known and not listed as obsolete\n";
    $warnings++;
}


#
# Constants known to be obsolete should not be listed
#
foreach my $constant (@obsolete_v71, @obsolete_v81, 
		      @obsolete_v82, @obsolete_v95) {
    next unless (defined $config_params->{$constant});
    print "Constant '$constant' is listed as obsolete in <sqlutil.h> but still described\n";
    $errors++;
}

if ($errors || $warnings) {
    print "Found $errors errors and $warnings warnings\n";
}
exit($errors);

#!/usr/bin/perl -w
#
# $Header: /cvsroot/arsperl/ARSperl/infra/exsi.pl,v 1.8 2011/07/29 13:05:28 tstapff Exp $
#
# NAME
#   exsi.pl < ar.h > server_info_type_hints.h
#
# DESCRIPTION
#   read the server info defines
#   make gross assumptions about the format of the comments
#   spit out a ServerInfoTypeHints structure
#
# AUTHOR
#   jeff murphy
#   jcmurphy@jeffmurphy.org
#
# $Log: exsi.pl,v $
# Revision 1.8  2011/07/29 13:05:28  tstapff
# arsystem 7.6.4 port
#
# Revision 1.6  2009/12/14 17:30:56  jeffmurphy
# more fiddling with exsi.pl: removed skip of MAX_ATTACH_SIZE, reworded warning
#
# Revision 1.5  2009/12/14 17:25:34  jeffmurphy
# changed die to warn. due to watch serverinfotypehints is searched, shouldnt affect anything if theres a gap. sf bug id 2914262
#
# Revision 1.4  2009/03/31 17:41:18  tstapff
# arsystem 7.5 port, AR*Image functions
#
# Revision 1.3  2008/09/24 13:03:14  tstapff
# bugfix for serverTypeInfoHints.h
#
# Revision 1.2  2007/09/13 22:50:26  tstapff
# arsystem 7.1 port
#
# Revision 1.1  2003/03/27 18:00:04  jcmurphy
# exsi.pl
#
#

use strict;
my $D  = 0;

header();


my $ct = 0;  # counter for completeness check
my $apiVersion;

while(<>) {
	print if $D;
	chomp;
	
	$apiVersion = $1 if /#define\s+AR_CURRENT_API_VERSION\s+(\d+)/;

	# jump thru hoops

	my ($sin, $siv, $sit, $sit2);
	# name value type type2

	while( 1 ){
		if(/\#define\s+(AR_SERVER_INFO_\S+)\s+(\d+)\s*\/\*\s*(\w+)[-;(\s]+(\S+)?/) {
			($sin, $siv, $sit, $sit2) = ($1, $2, $3, $4);
#			print STDERR "\$sin <", $sin, ">  \$siv <", $siv, ">  \$sit <", $sit, ">  \$sit2 <", $sit2, ">\n";  # _DEBUG_
		}elsif(/\#define\s+(AR_SERVER_INFO_\S+)\s+(\d+)\s*$/){
			($sin, $siv) = ($1, $2);
			$_ = <>;
			if( /^\s*\/\*\s+(\S+)\s+(\S+)?/) {
				($sit, $sit2) = ($1, $2);
			}else{
				next;
			}
		}
		last;
	}

	if( defined $sin && defined $siv && defined $sit ){
		print "sin $sin siv $siv sit $sit\n" if $D;
		if( $apiVersion == 14 && $ct == 324 ){
			$ct += 9;
		}elsif( $apiVersion >= 17 && $ct == 326 ){
			$ct += 4;
		}elsif( $apiVersion >= 17 && $ct == 339 ){
			$ct += 2;
		}elsif( $apiVersion >= 20 && $ct == 358 ){
			$ct += 22;
		}elsif( $apiVersion >= 20 && $ct == 384 ){
			$ct += 2;
		}elsif( $apiVersion >= 20 && $ct == 398 ){
			$ct += 3;
		}else{
			++$ct;
		}
#		print STDERR "($ct) sin $sin siv $siv sit $sit\n";
		if ($siv != $ct) {
			if( $siv <= 324 ){
				warn "!!! ERROR: Cannot determine type for AR_SERVER_INFO constant $ct !!!";
			}else{
				warn "WARNING: gap in enumeration for $sin expected $ct got $siv. it's OK to ignore this.";
			}
			$ct = $siv;
		}

		next if $sit eq 'deprecated';

		# jump thru some more hoops

		$sit .= " $sit2" if ($sit =~ /unsigned/);

		# *grimace*

		$sit =~ s/\://g;
		$sit =~ s/\-.*//g;

		# 5.x 
		
		$sit = "int" if $sit =~ /int\(AIX\)/i;

		# omg 

		$sit = "int" if $sin eq "AR_SERVER_INFO_MAX_AUDIT_LOG_FILE_SIZE";
		$sit = "char" if $sin eq "AR_SERVER_INFO_MESSAGE_CAT_SCHEMA";
		$sit = "unsigned long" if $sit eq "ARInternalId";
		$sit = "unsigned char" if $sin eq "AR_SERVER_INFO_SVR_EVENT_LIST";

# AR_SERVER_INFO_MESSAGE_CAT_SCHEMA [138] is an name
# AR_SERVER_INFO_MAX_AUDIT_LOG_FILE_SIZE [120] is an 0
# AR_SERVER_INFO_SVR_EVENT_LIST [141] is an list

		$sit = "int" if $sin eq "AR_SERVER_INFO_DB_MAX_ATTACH_SIZE";
		$sit = "int" if $sin eq "AR_SERVER_INFO_DB_MAX_TEXT_SIZE";
		$sit = "char" if $sin eq "AR_SERVER_INFO_GUID_PREFIX";

		$sit = "char" if $sin eq "AR_SERVER_INFO_FT_COLLECTION_DIR";     # deprecated in 7.5
		$sit = "char" if $sin eq "AR_SERVER_INFO_FT_CONFIGURATION_DIR";  # deprecated in 7.5
		$sit = "char" if $sin eq "AR_SERVER_INFO_FT_TEMP_DIR";           # deprecated in 7.5

		$sit = "int" if $sin eq "AR_SERVER_INFO_LICENSE_USAGE";
		$sit = "int" if $sin eq "AR_SERVER_INFO_MAX_CLIENT_MANAGED_TRANSACTIONS";
		$sit = "int" if $sin eq "AR_SERVER_INFO_CLIENT_MANAGED_TRANSACTION_TIMEOUT";

		$sit = "int" if $sin eq "AR_SERVER_INFO_MAX_ATTACH_SIZE";
		$sit = "int" if $sin eq "AR_SERVER_INFO_ATRIUM_SSO_AUTHENTICATION";

		$sit = "int" if $sin eq "AR_SERVER_INFO_MFS_TITLE_FIELD_WEIGHT";         # 327
		$sit = "int" if $sin eq "AR_SERVER_INFO_MFS_ENVIRONMENT_FIELD_WEIGHT";   # 328
		$sit = "int" if $sin eq "AR_SERVER_INFO_MFS_KEYWORDS_FIELD_WEIGHT";      # 329

		$sit = "int" if $sin eq "AR_SERVER_INFO_OVERLAY_MODE";                   # 341

		#print "\t/*$sin [$siv] is an $sit*/\n";

		my $artype = typemap($sit);
		die "cant map \"$sit\" to an artype for \"$sin\"\n" if 
		  !defined($artype);
		print "\t{ $sin,\t".typemap($sit)." }, /* $siv */\n";
	}

}

footer();

exit 0;

sub typemap {
	my $t = shift;
	my %m = ( 'int'     => 'AR_DATA_TYPE_INTEGER',
		  'long'    => 'AR_DATA_TYPE_INTEGER',
		  'real'    => 'AR_DATA_TYPE_REAL',
		  'char'    => 'AR_DATA_TYPE_CHAR',
		  'String'  => 'AR_DATA_TYPE_CHAR',
		  'diary'   => 'AR_DATA_TYPE_DIARY',
		  'enum'    => 'AR_DATA_TYPE_ENUM',
		  'time'    => 'AR_DATA_TYPE_TIME',
		  'bitmask' => 'AR_DATA_TYPE_BITMASK',
		  'bytes'   => 'AR_DATA_TYPE_BYTES'
		  );

	$t =~ s/unsigned\s//g;
	return $m{$t} if ( defined($m{$t}) );
	return undef;
}

sub header {
	print "
/* DO NOT EDIT. this file was automatically generated by
   $0 on ".scalar localtime()." */

#ifndef __ServerInfoTypeHints__
#define __ServerInfoTypeHints__

static struct {
	unsigned int infoTypeNum;
	unsigned int infoTypeType;
} ServerInfoTypeHints[] = {
";
}

sub footer {
	print "
	{ TYPEMAP_LAST,                         TYPEMAP_LAST }
};
#endif /* __ServerInfoTypeHints__ */
";
}




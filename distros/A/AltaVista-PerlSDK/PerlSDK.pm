#   AltaVista Search SDK support package
#   Copyright (c)2000 AltaVista Company
#   All Rights Reserved.
#
#   This software is furnished under a license and may be used and copied
#   only  in  accordance  with  the  terms  of such  license and with the
#   inclusion of the above copyright notice. This software or  any  other
#   copies thereof may not be provided or otherwise made available to any
#   other person. No title to and ownership of  the  software  is  hereby
#   transferred.
#
#   The information in this software is subject to change without  notice
#   and  should  not be  construed as a commitment  by AltaVista Company.
#
# PerlSDK.pm

package AltaVista::PerlSDK;

use strict;
use Carp;	# defines the carp(), croak(), and confess() functions
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
	AVS_ADDDOC_IO_ERR
	AVS_BADARGS_ERR
	AVS_CHARSET_ASCII8
	AVS_CHARSET_LATIN1
	AVS_CHARSET_UTF8
	AVS_COMPACT_IO_ERR
	AVS_COUNTS_ERR
	AVS_DATE_ERR
	AVS_DOCDATA_ERR
	AVS_DOCID_ERR
	AVS_DOCLIST_ERR
	AVS_DOC_EXISTS
	AVS_DOC_LIMIT_ERR
	AVS_DOC_NOTFOUND
	AVS_FIELD_ERR
	AVS_FILTER_ERR
	AVS_GETDATA_ERR
	AVS_INDEX_ERR
	AVS_LICENSE_EXPIRED
	AVS_LOCK_ERR
	AVS_MALLOC_ERR
	AVS_MAX_BUCKETS
	AVS_MAX_DOCDATA
	AVS_MAX_DOCID
	AVS_MAX_TIERS
	AVS_MAX_WORDSIZE
	AVS_MKSTABLE_IO_ERR
	AVS_MKVIS_IO_ERR
	AVS_NOMORE_WORDS
	AVS_OK
	AVS_OPEN_ERR
	AVS_OPTION_RANKBYDATE
	AVS_OPTION_SEARCHBYDATE
	AVS_OPTION_SEARCHSINCE
	AVS_OPTION_NOBLOCK
	AVS_OPTION_INDEX_CJK_CHARS_AS_WORDS
	AVS_OPTION_NOPROXIMITY
	AVS_OPT_FLAGS_RANK_TO_BOOL
	AVS_PARSE_ERR
	AVS_PARSE_SGML
	AVS_RESULTNUM_ERR
	AVS_SEARCH_ERR
	AVS_STARTDOC_ERR
	AVS_SYNC_ERR
	AVS_UNK_EXCEPTION_ERR
	AVS_UPDATE_ERR
	AVS_VERSION_ERR
	VALTYPE_NAME_LEN
	_AVS_INTERFACE_VERSION
	     avs_adddate
	     avs_addfield
	     avs_addliteral
	     avs_addvalue
	     avs_addword
	     avs_buildmode
	     avs_buildmode_ex
	     avs_close
	     avs_compact
	     avs_compactionneeded
	     avs_compact_minor
	     avs_count
	     avs_count_close
	     avs_count_getcount
	     avs_count_getword
	     avs_countnext
	     avs_default_options
	     avs_define_valtype
	     avs_define_valtype_multiple
	     avs_deletedocid
	     avs_enddoc
	     avs_errmsg
	     avs_getindexmode
	     avs_getindexversion
	     avs_getindexversion_counts_v
	     avs_getindexversion_search_v
	     avs_getmaxloc
	     avs_getsearchresults
	     avs_getsearchterms
	     avs_getsearchversion
	     avs_licenseinfo
	     avs_lookup_valtype
	     avs_makestable
	     avs_open
	     avs_querymode
	     avs_release_valtypes
	     avs_search
	     avs_search_close
	     avs_search_ex
	     avs_search_genrank
	     avs_search_getdata
	     avs_search_getdatalen
	     avs_search_getdate
	     avs_search_getdocid
	     avs_search_getdocidlen
	     avs_search_getrelevance
	     avs_setdocdata
	     avs_setdocdate
	     avs_setdocdatetime
	     avs_setparseflags
	     avs_setrankval
	     avs_startdoc
	     avs_timer
	     avs_total_docs
	     avs_version
	     avs_create_options
	     avs_create_parameters
);
$VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined AltaVista::PerlSDK macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap AltaVista::PerlSDK $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

AltaVista::PerlSDK - Perl extension for AltaVista Search Software Development Kit

=head1 SYNOPSIS

  use AltaVista::PerlSDK;

avs_adddate(idx, yr, mo, da, startloc)

avs_addfield(idx, pFname, startloc, endloc)	

avs_addliteral(idx, pWord, loc)

avs_addvalue(idx, valtype, value, loc)

avs_addword(idx, pWords, loc, pNumWords)

avs_buildmode(idx)

avs_buildmode_ex(idx, ntiers)

avs_close(idx)

avs_compact(idx, bMore_p)

avs_compactionneeded(idx)

avs_compact_minor(idx, bMore_p)

avs_count(idx, pWordPrefix, pCountsHdl)

avs_count_close(CountsHdl)

avs_count_getcount(CountsHdl)

avs_count_getword(CountsHdl)

avs_countnext(CountsHdl)

avs_default_options(pOptions)

avs_define_valtype(name, minval, maxval, valtype_p)

avs_define_valtype_multiple(name, minval, maxval, numvalues, valtype_p)

avs_deletedocid(idx, pDocId, pCount)

avs_enddoc(idx)

avs_errmsg(code)

avs_getindexmode(idx)

avs_getindexversion(idx)

avs_getindexversion_counts_v(countsHdl)

avs_getindexversion_search_v(searchHdl)

avs_getmaxloc(idx, pMaxloc)

avs_getsearchresults(searchHdl, resultNum)

avs_getsearchterms(psearchHdl, termNum, term, count)

avs_licenseinfo(key, expDate, docLimit)

avs_lookup_valtype(name)

avs_makestable(idx)

avs_open(parameters, path, mode, pIdx)

avs_querymode(idx)

avs_release_valtypes()

avs_release_valtype(valtype_p)

avs_search(idx, pQuery, pBoolQuery, pOptions, pDocsFound, pDocsReturned, pTermCount, pSearchHdl)

avs_search_close(pSearchHdl)

avs_search_ex(idx, pQuery, pBoolQuery, pOptions, searchsince, pDocsFound, pDocsReturned, pTermCount, pSearchHdl)

avs_search_genrank(idx, pBoolQuery, pRankTerms, pRankSetup, pOptions, searchsince, pDocsFound, pDocsReturned, pSearchHdl)

avs_search_getdata(searchHdl)

avs_search_getdatalen(searchHdl)

avs_search_getdate(psearchHdl, year, month, day)

avs_search_getdocid(searchHdl)

avs_search_getdocidlen(searchHdl)

avs_search_getrelevance(psearchHdl)

avs_setdocdata(idx, pDocData, len)

avs_setdocdate(idx, year, month, day)

avs_setdocdatetime(idx, year, month, day, hour, minute, second)

avs_setparseflags(idx, parseflags)

avs_setrankval(idx, valtype, value)

avs_startdoc(idx, pDocId, flags, pStartLoc)

avs_timer(current)

avs_total_docs(idx, pDoccount)

avs_version(license_key)

avs_create_options(limit, timeout, flags)

avs_create_parameters(_interface_version, license, ignored_thresh, chars_before_wildcard, unlimited_wild_words, indexformat, cache_threshold, options, charset, ntiers, nbuckets)

=head1 DESCRIPTION

This set of extensions provides wrappers for most of the C functionalities in
the AltaVista Search software development kit (SDK) except for a few functions 
that did not make sense to export to perl.

Two additional functions are used to ease the process of creating options and parameters: 
avs_create_options
avs_create_parameters

The following functions are not implemented due to its complexity or they are
unnecessary.

=over 4

=item I<avs_add_ms_callback> UNIMPLEMENTED

=item I<avs_addrankterms> UNIMPLEMENTED

=item I<avs_count_docs> UNIMPLEMENTED

=item I<avs_count_docs_freelist> UNIMPLEMENTED

=item I<avs_errmsg_copy> UNIMPLEMENTED

=item I<avs_newdoc> UNIMPLEMENTED

=item I<avs_search_getdata_copy> UNIMPLEMENTED

=item I<avs_search_getdocid_copy> UNIMPLEMENTED

=item I<avs_search_getrelevance> RETURN ARGUMENT

=back

=head1 PREREQUITES

Perl 5.004, AltaVista SearchSDK Library 

=head1 INSTALLATION - Windows System

To install this module, copy avs.h and avs30.lib from your 
AltaVista SearchSDK source hierarchy into this directory. Then 
type the following commands:
    
    perl Makefile.PL
    nmake
    nmake test
    nmake install

This will install the module into the Perl library directory.

=head1 INSTALLATION - UNIX/Linux/Solaris System

To install this module, copy avs.h and libavs30.a from your 
AltaVista SearchSDK source hierarchy into this directory.  Then 
type the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 AUTHOR

AltaVista Search <avse-support@av.com>

Copyright (c)2000 AltaVista Company
All Rights Reserved.

This software is furnished under a license and may be used and copied
only  in  accordance  with  the  terms  of such  license and with the
inclusion of the above copyright notice. This software or  any  other
copies thereof may not be provided or otherwise made available to any
other person. No title to and ownership of  the  software  is  hereby
transferred.

The information in this software is subject to change without  notice
and  should  not be  construed as a commitment  by AltaVista Company.

=head1 SEE ALSO

perl, AltaVista Search SDK documentation.

=cut

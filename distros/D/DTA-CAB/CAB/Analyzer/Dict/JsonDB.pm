## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::Dict::JsonDB.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic analysis dictionary API using JSON values

package DTA::CAB::Analyzer::Dict::JsonDB;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Analyzer::Dict::Json;
use DTA::CAB::Analyzer::Dict::BDB;
use IO::File;
use Carp;
use Encode qw(encode decode);
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer::Dict::BDB DTA::CAB::Analyzer::Dict::Json);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     ##-- Filename Options
##     dictFile => $filename,    ##-- filename (default=undef): should be TT-dict with JSON-encoded hash values
##
##     ##-- Analysis Output
##     label          => $lab,   ##-- analyzer label
##     analyzeCode    => $code,  ##-- pseudo-accessor to perform actual analysis for token ($_); see DTA::CAB::Analyzer::Dict for details
##
##     ##-- Analysis Options
##     encoding       => $enc,   ##-- encoding of db file: OVERRIDE DEFAULT: 'raw'
##     keyEncoding    => $enc,   ##-- NEW: encoding of db file keys (default='UTF-8')
##
##     ##-- Analysis objects
##     dbf => $dbf,              ##-- underlying Lingua::TT::DBFile object (default=undef)
##     dba => \%dba,             ##-- args for Lingua::TT::DBFile->new()
##     #={
##     #  mode  => $mode,        ##-- default: 0644
##     #  dbflags => $flags,     ##-- default: O_RDONLY
##     #  type    => $type,      ##-- one of 'HASH', 'BTREE', 'RECNO', 'GUESS' (default: 'GUESS')
##     #  dbinfo  => \%dbinfo,   ##-- default: "DB_File::${type}INFO"->new();
##     #  dbopts  => \%opts,     ##-- db options (e.g. cachesize,bval,...) -- defaults to none (uses DB_File defaults)
##     # }
##    )
sub new {
  my $that = shift;
  my $dic = $that->DTA::CAB::Analyzer::Dict::BDB::new(
						      ##-- filenames
						      dictFile => undef,

						      ##-- options
						      encoding => 'raw', ##-- override
						      keyEncoding => 'UTF-8',

						      ##-- analysis output
						      label => 'dict_json',
						      analyzeCode => $DTA::CAB::Analyzer::Dict::Json::CODE_DEFAULT,

						      ##-- JSON parser (segfaults; see Analyzer::Dict::Json::jsonxs() method)
						      #jxs => __PACKAGE__->jsonxs,

						      ##-- user args
						      @_
						     );
  return $dic;
}



##==============================================================================
## Methods: Embedded API
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $bool = $dic->ensureLoaded()
##  + ensures analyzer data is loaded from default files
sub ensureLoaded {
  my $dic = shift;
  my $rc  = $dic->DTA::CAB::Analyzer::Dict::BDB::ensureLoaded(@_);

  ##-- shutoff the value filters
  ## + BUG (2011-04-08, kaskade, perl 5.10.0): 'Undefined subroutine &main:: called'
  ##   - appears whenever we disable existing filters with filter_OP_KEYVAL(undef)
  ##   - workaround: pass 'raw' encoding into DB_File and install only the filters we really want here
  ##   - implemented as workaround 'keyEncoding','valEncoding' in Analyzer::Dict::BDB
#  if ($rc && $dic->dictOk) {
#    my $tied = $dic->{dbf}{tied};
#    $tied->filter_fetch_value(undef); ##-- BUG
#    $tied->filter_store_value(undef); ##-- BUG
#  }

  return $rc;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

##======================================================================
## Methods: Persistence: Perl

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
sub noSaveKeys {
  my $that = shift;
  return ($that->DTA::CAB::Analyzer::Dict::BDB::noSaveKeys,
	  $that->DTA::CAB::Analyzer::Dict::Json::noSaveKeys,
	 );
}

## @keys = $class_or_obj->noSaveBinKeys()
sub noSaveBinKeys {
  my $that = shift;
  return ($that->DTA::CAB::Analyzer::Dict::BDB::noSaveBinKeys,
	  $that->DTA::CAB::Analyzer::Dict::Json::noSaveBinKeys,
	 );
}


##==============================================================================
## Methods: Analysis
##==============================================================================

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
##  + INHERITED from Dict

##------------------------------------------------------------------------
## Methods: Analysis: Utils

## $prefix = $dict->analyzePre()
sub analyzePre {
  my $dic = shift;
  return $dic->DTA::CAB::Analyzer::Dict::Json::analyzePre(@_);
}

## $coderef = $dict->analyzeCode()
## $coderef = $dict->analyzeCode($code)
##  + inherited



1; ##-- be happy

__END__

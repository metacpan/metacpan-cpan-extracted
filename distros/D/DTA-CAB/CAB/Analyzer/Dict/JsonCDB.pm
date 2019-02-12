## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::Dict::JsonCDB.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic analysis dictionary API using JSON values

package DTA::CAB::Analyzer::Dict::JsonCDB;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Analyzer::Dict::Json;
use DTA::CAB::Analyzer::Dict::CDB;
use IO::File;
use Carp;
use utf8;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer::Dict::CDB DTA::CAB::Analyzer::Dict::Json);

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
##     dbf => $dbf,              ##-- underlying Lingua::TT::CDBFile object (default=undef)
##     dba => \%dba,             ##-- args for Lingua::TT::CDBFile->new()
##    )
sub new {
  my $that = shift;
  my $dic = $that->DTA::CAB::Analyzer::Dict::CDB::new(
						      ##-- filenames
						      dictFile => undef,

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
  my $rc  = $dic->DTA::CAB::Analyzer::Dict::CDB::ensureLoaded(@_);
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
  return ($that->DTA::CAB::Analyzer::Dict::CDB::noSaveKeys,
	  $that->DTA::CAB::Analyzer::Dict::Json::noSaveKeys,
	 );
}

## @keys = $class_or_obj->noSaveBinKeys()
sub noSaveBinKeys {
  my $that = shift;
  return ($that->DTA::CAB::Analyzer::Dict::CDB::noSaveBinKeys,
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

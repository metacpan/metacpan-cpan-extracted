## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::Dict::Json.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic analysis dictionary API using JSON values

package DTA::CAB::Analyzer::Dict::Json;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Analyzer::Dict;
use JSON::XS;
use IO::File;
use Carp;
use Encode qw(encode decode);

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer::Dict);

our $CODE_DEFAULT =
  ('return if (!defined($val=$dhash->{'._am_xlit('$_').'}));'
   .' $val=$jxs->decode($val);'
   .' @$_{keys %$val}=values %$val;');

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
##     encoding       => $enc,   ##-- encoding of db file (default='UTF-8'): clobbers $dba{encoding} ; uses DB filters
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
  my $dic = $that->SUPER::new(
			      ##-- filenames
			      dictFile => undef,

			      ##-- options
			      encoding => 'UTF-8',

			      ##-- analysis output
			      label => 'dict_json',
			      analyzeCode => $CODE_DEFAULT,

			      ##-- JSON parser (segfaults: see jsonxs() method, below)
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
  my $rc  = 1;
  if ( defined($dic->{dictFile}) && !$dic->dictOk ) {
    $dic->info("loading dictionary file '$dic->{dictFile}'");
    $rc &&= $dic->{ttd}->loadFile($dic->{dictFile}, encoding=>$dic->{encoding});

    ##-- json with utf8(1) wants utf8-encoded octets, so we munge them here
    foreach (values %{$dic->{ttd}{dict}}) {
      #$_ = Encode::encode_utf8($_) if (utf8::is_utf8($_));
      utf8::encode($_) if (utf8::is_utf8($_));
    }
  }
  return $rc;
}

## $dic = $dic->decodeDictValues()
##  + runs $jxs->decode() on all dict values (for in-memory dicts)
sub decodeDictValues {
  my $dic = shift;
  return $dic if (!$dic->{ttd} || !$dic->{ttd}{dict});

  my $dict = $dic->{ttd}{dict};
  my $jxs  = $dic->jsonxs;
  foreach (keys %$dict) {
    $dict->{$_} = $jxs->decode($dict->{$_}) if (!ref($dict->{$_}));
  }
  return $dic;
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
  return ($that->SUPER::noSaveKeys, qw(jxs));
}

## @keys = $class_or_obj->noSaveBinKeys()
##  + returns list of keys not to be saved in binary mode
sub noSaveBinKeys {
  my $that = shift;
  return ($that->SUPER::noSaveBinKeys, qw(jxs));
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

## $jxs = $dict->jsonxs()
## $jxs = $CLASS->jsonxs()
##  + returns underlying JSON::XS object or creates appropriate new object
##  + DISABLED (b/c of segfaults): caches if not already defined for object call
##--
## Program received signal SIGSEGV, Segmentation fault.
## 0xb7a03584 in XS_JSON__XS_DESTROY () from /usr/lib/perl5/auto/JSON/XS/XS.so
## (gdb) bt
## #0  0xb7a03584 in XS_JSON__XS_DESTROY () from /usr/lib/perl5/auto/JSON/XS/XS.so
## #1  0x080d5d7b in Perl_pp_entersub ()
## #2  0x08078bb8 in Perl_call_sv ()
## #3  0x080e8090 in Perl_sv_clear ()
## #4  0x080e87da in Perl_sv_free2 ()
## #5  0x080dd8d9 in ?? ()
## #6  0x080dd939 in Perl_sv_clean_objs ()
## #7  0x0807dcaf in perl_destruct ()
## #8  0x080642a5 in main ()
##--
sub jsonxs {
  return $_[0]{jxs} if (ref($_[0]) && defined($_[0]{jxs}));
  my $jxs = JSON::XS->new->utf8(1)->relaxed(1)->shrink(1)->allow_blessed(1)->convert_blessed(1);
  #return $_[0]{jxs} = $jxs if (ref($_[0]));
  return $jxs;
}

## $prefix = $dict->analyzePre()
sub analyzePre {
  my $dic = shift;
  return 'my $jxs=$anl->jsonxs; '.$dic->SUPER::analyzePre();
}

## $coderef = $dict->analyzeCode()
## $coderef = $dict->analyzeCode($code)
##  + inherited



1; ##-- be happy

__END__

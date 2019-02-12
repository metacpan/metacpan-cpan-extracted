## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::Dict.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic analysis dictionary API using Lingua::TT::Dict

package DTA::CAB::Analyzer::Dict;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Format;
use Lingua::TT::Dict;
use IO::File;
use Carp;

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer);

##--------------------------------------------------------------
## Globals: Accessors

##  + dict application is computed as:
##      $dic->accessClosure($dic->{analyzeCode})->();
##  + analysis closure compiled from $dic->{analyzeCode} can use vars:
##      $dic   ##-- analyzer object
##      $anl   ##-- analyzer object (alias provided by Analyzer::accessClosure)
##      $lab   ##-- $dic->{label}
##      $dhash ##-- $dic->dictHash()
##      #$doc   ##-- document being analyzed
##      #$types ##-- types being analyzed with analyzeTypes()
##      #$opts  ##-- user options to analyzeTypes()
##  + the following lexical temporaries are provided:
##      $key   ##-- temporary; unused here
##      $val   ##-- temporary; unused here
##      @keys  ##-- temporary; unused here
##      @vals  ##-- temporary; unused here
##      %vals  ##-- temporary; unused here
##==============================================================================

our $CODE_DEFAULT = '$_->{$lab}=$dhash->{'._am_xlit().'};'; # '._am_clean('$_->{$lab}'); ##-- useless, since expandTypes() puts undef back!

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     ##-- Filename Options
##     dictFile=> $filename,     ##-- default: none
##
##     ##-- Analysis Output
##     label          => $lab,   ##-- analyzer label
##     analyzeCode    => $code,  ##-- pseudo-accessor ($code->()): apply dict to current token ($_)
##
##     ##-- Analysis Options
##     encoding       => $enc,   ##-- encoding of dict file (default='UTF-8')
##     allowRegex     => $re,    ##-- only lookup tokens whose text matches $re (default=none)
##     eqIdWeight     => $w,     ##-- weight for identity analyses for analyzeSet=>$DICT_SET_FST_EQ
##
##     ##-- Analysis objects
##     ttd => $ttdict,           ##-- underlying Lingua::TT::Dict object
##    )
sub new {
  my $that = shift;
  my $dic = $that->SUPER::new(
			      ##-- filenames
			      dictFile => undef,

			      ##-- analysis objects
			      ttd=>Lingua::TT::Dict->new(),

			      ##-- options
			      encoding       => 'UTF-8',

			      ##-- analysis output
			      label => 'dict',
			      analyzeCode => $CODE_DEFAULT,
			      allowRegex => undef,

			      ##-- user args
			      @_
			     );
  return $dic;
}

## $dic = $dic->clear()
sub clear {
  my $dic = shift;
  $dic->{ttd}->clear;
  return $dic;
}


##==============================================================================
## Methods: Embedded API
##==============================================================================

## $bool = $dict->dictOk()
##  + returns false iff dict is undefined or "empty"
sub dictOk {
  return defined($_[0]{ttd}) && scalar(%{$_[0]{ttd}{dict}});
}

## \%key2val = $dict->dictHash()
##   + returns a (possibly tie()d hash) representing dict contents
##   + default just returns $dic->{ttd}{dict} or a new empty hash
sub dictHash {
  return $_[0]{ttd} && $_[0]{ttd}{dict} ? $_[0]{ttd}{dict} : {};
}

## $val_or_undef = $dict->dictLookup($key)
##  + get stored value for key $key
##  + default returns $dict->{ttd}{dict}{$key} or undef
sub dictLookup {
  return $_[0]{ttd} && $_[0]{ttd}{dict} ? $_[0]{ttd}{dict}{$_[1]} : undef;
}

##==============================================================================
## Methods: I/O
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
  }
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
  return ($that->SUPER::noSaveKeys, qw(ttd));
}

## $saveRef = $obj->savePerlRef()
##  + inherited from DTA::CAB::Persistent

## $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref)
##  + OLD: implicitly calls $obj->clear()
sub loadPerlRef {
  my ($that,$ref) = @_;
  my $obj = $that->SUPER::loadPerlRef($ref);
  #$obj->clear();
  return $obj;
}

##==============================================================================
## Methods: Analysis
##==============================================================================

##------------------------------------------------------------------------
## Methods: Analysis: Generic

## $bool = $anl->canAnalyze()
##  + returns true if analyzer can perform its function (e.g. data is loaded & non-empty)
##  + override calls dictOk()
sub canAnalyze {
  return $_[0]->dictOk();
}

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
sub analyzeTypes {
  my ($dic,$doc,$types,$opts) = @_;

  ##-- setup common variables
  my $allow_re = defined($dic->{allowRegex}) ? qr($dic->{allowRegex}) : undef;
  my $acode    = $dic->analyzeCode;

  foreach (values %$types) {
    next if (defined($allow_re) && $_->{text} !~ $allow_re);
    $acode->();
  }

  return $doc;
}

##------------------------------------------------------------------------
## Methods: Analysis: Utils

## $prefix = $dict->analyzePre()
sub analyzePre {
  my $dic = shift;
  return join('',
	      (map {"my $_;\n"}
	       '$dic=$anl',
	       '$lab=$dic->{label}',
	       '$dhash=$dic->dictHash',
	       '($key,$val,@keys,@vals,%vals)'
	      ),
	      ($dic->{analyzePre} ? $dic->{analyzePre} : qw()),
	     );
}

## $coderef = $dict->analyzeCode()
## $coderef = $dict->analyzeCode($code)
sub analyzeCode {
  my ($dic,$code) = @_;
  #return $dic->analyzeCode_dummy($code) if ($dic->{label} eq 'exlex'); ##-- DEBUG
  $code      = defined($dic->{analyzeCode}) ? $dic->{analyzeCode} : $CODE_DEFAULT if (!defined($code));
  my $acode  = $dic->accessClosure($code, pre=>$dic->analyzePre);
  return $acode;
}

1; ##-- be happy

__END__


##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::Dict - generic analysis dictionary API using Lingua::TT::Dict

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Analyzer::Dict;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 $dic = $dic->clear();
 
 ##========================================================================
 ## Methods: Embedded API
 
 $bool = $dict->dictOk();
 \%key2val = $dict->dictHash();
 $val_or_undef = $dict->dictLookup($key);
 
 ##========================================================================
 ## Methods: I/O
 
 $bool = $dic->ensureLoaded();
 
 ##========================================================================
 ## Methods: Persistence: Perl
 
 @keys = $class_or_obj->noSaveKeys();
 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);
 
 ##========================================================================
 ## Methods: Analysis
 
 $bool = $anl->canAnalyze();
 $doc = $anl->analyzeTypes($doc,\%types,\%opts);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Analyzer::Dict inherits from
L<DTA::CAB::Analyzer|DTA::CAB::Analyzer>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict: Accessors
=pod

=head2 Accessors

Dict application is computed as:

 $dic->accessClosure($dic->{analyzeCode})->();

Analysis closure compiled from $dic-E<gt>{analyzeCode} can use vars:

 $dic   ##-- analyzer object
 $anl   ##-- analyzer object (alias provided by Analyzer::accessClosure)
 $lab   ##-- $dic->{label}
 $dhash ##-- $dic->dictHash()
 #$doc   ##-- document being analyzed
 #$types ##-- types being analyzed with analyzeTypes()
 #$opts  ##-- user options to analyzeTypes()

The following lexical temporaries are provided for convenience:

 $key   ##-- dict key (temporary)
 $val   ##-- dict value (temporary, used by SET macros)

See L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> for more details on access closures.

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

%$obj, %args:

 ##-- Filename Options
 dictFile=> $filename,     ##-- default: none
 ##-- Analysis Output
 label          => $lab,   ##-- analyzer label
 analyzeGet     => $code,  ##-- pseudo-accessor ($code->($tok)): returns list of source keys for token  (default='$_[0]{text}')
 analyzeSet     => $code,  ##-- pseudo-accessor ($code->($tok,$key,$val)) sets analyses for $tok
 ##-- Analysis Options
 encoding       => $enc,   ##-- encoding of dict file (default='UTF-8')
 allowRegex     => $re,    ##-- only lookup tokens whose text matches $re (default=none)
 eqIdWeight     => $w,     ##-- weight for identity analyses for analyzeSet=>$DICT_SET_FST_EQ
 ##-- Analysis objects
 ttd => $ttdict,           ##-- underlying Lingua::TT::Dict object

=item clear

 $dic = $dic->clear();

Clears the object by calling $dic-E<ttd>clear().
Note that this may not be what you want if the underlying dictionary
uses persistent storage -- override this method if that is the case.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict: Methods: Embedded API
=pod

=head2 Methods: Embedded API

=over 4

=item dictOk

 $bool = $dict->dictOk();

Returns false iff dict is undefined or "empty".

=item dictHash

 \%key2val = $dict->dictHash();

Returns a (possibly tie()d hash) representing dict contents.
Default just returns $dic-E<gt>{ttd}{dict} or a new empty hash.

=item dictLookup

 $val_or_undef = $dict->dictLookup($key);

Get stored value for key $key, or undef if no such value exists.
Default returns $dict-E<gt>{ttd}{dict}{$key}.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict: Methods: I/O: Input: all
=pod

=head2 Methods: I/O

=over 4

=item ensureLoaded

 $bool = $dic->ensureLoaded();

Ensures analyzer data is loaded from default files.
Override calls $dic-E<gt>{ttd}-E<gt>loadFile().

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict: Methods: Persistence: Perl
=pod

=head2 Methods: Persistence: Perl

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Returns list of keys not to be saved.
Default returns qw(ttd).

=item loadPerlRef

 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);

Load object data from a retrieve()d perl reference.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict: Methods: Analysis
=pod

=head2 Methods: Analysis

=over 4

=item canAnalyze

 $bool = $anl->canAnalyze();

Returns true if analyzer can perform its function (e.g. data is loaded & non-empty).
Override calls dictOk().

=item analyzeTypes

 $doc = $anl->analyzeTypes($doc,\%types,\%opts);

Perform type-wise analysis of all (text) types in $doc-E<gt>{types}.

=back

=cut


##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<DTA::CAB::Analyzer::Dict::BDB(3pm)|DTA::CAB::Analyzer::Dict::BDB>,
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut

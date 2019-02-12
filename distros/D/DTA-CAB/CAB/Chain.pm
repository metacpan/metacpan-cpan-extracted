## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Chain.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic analyzer API: analyzer "chains" / "cascades" / "pipelines" / ...

package DTA::CAB::Chain;
use DTA::CAB::Analyzer;
use DTA::CAB::Datum ':all';
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer);

BEGIN {
  *isa = \&UNIVERSAL::isa;
  *can = \&UNIVERSAL::can;
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     ##-- Analyzers
##     chain => [ $a1, $a2, ..., $aN ],        ##-- default analysis chain; see also chain() method (default: empty)
##
##     ##-- verbose trace
##     logTrace => $level,                     ##-- trace sub-analyzer execution (default: 'none')
##    )
sub new {
  my $that = shift;
  my $ach = bless({
		   ##-- user args
		   chain => [],
		   logTrace => 'none',
		   @_
		  }, ref($that)||$that);
  $ach->initialize();
  $ach->{label} = $ach->defaultLabel if (!defined($ach->{label}));
  return $ach;
}

## undef = $ach->initialize();
##  + default implementation does nothing
##  + INHERITED from DTA::CAB::Analyzer

## undef = $ach->dropClosures();
##  + drops '_analyze*' closures
##  + INHERITED from DTA::CAB::Analyzer

## @keys = $anl->typeKeys(\%opts)
##  + returns list of type-wise keys to be expanded for this analyzer by expandTypes()
##  + default just concatenates keys for sub-analyzers
sub typeKeys {
  my $ach = shift;
  return map {ref($_) ? $_->typeKeys(@_) : qw()} @{$ach->chain(@_)}
}


##==============================================================================
## Methods: Chain selection
##==============================================================================

## \@analyzers = $ach->chain()
## \@analyzers = $ach->chain(\%opts)
##  + get selected analyzer chain
###  + OLD: default method just returns $anl->{chain}
###  + NEW: default method returns all globally enabled analyzers in $anl->{chain}
sub chain {
  my $ach = shift;
  #return $ach->{chain};
  return [grep {$_ && $_->enabled} @{$ach->{chain}}];
}

## \@analyzers = $ach->subAnalyzers()
## \@analyzers = $ach->subAnalyzers(\%opts)
##  + returns a list of all sub-analyzers
##  + override just calls chain()
sub subAnalyzers {
  return $_[0]->chain(@_[1..$#_]);
}


##==============================================================================
## Methods: I/O
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $bool = $ach->ensureLoaded()
## $bool = $ach->ensureLoaded(\%opts)
##  + ensures analysis data is loaded from default files
##  + default version calls $a->ensureLoaded() for each $a in $ach->subAnalyzers(\%opts)
sub ensureLoaded {
  my $ach = shift;
  my $subs = $ach->subAnalyzers(@_);
  my $rc = 1;
  foreach (@$subs) {
    $rc &&= $_->ensureLoaded() if (ref($_) && $_->can('ensureLoaded'));
    last if (!$rc); ##-- short-circuit
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
##  + default just greps for CODE-refs
##  + INHERITED from DTA::CAB::Analyzer

## $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref)
##  + default implementation just clobbers $CLASS_OR_OBJ with $ref and blesses
##  + INHERITED from DTA::CAB::Analyzer

##======================================================================
## Methods: Persistence: Bin

## @keys = $class_or_obj->noSaveBinKeys()
##  + returns list of keys not to be saved for binary mode
##  + default just returns list of known '_analyze' keys
##  + INHERITED from DTA::CAB::Analyzer

## $loadedObj = $CLASS_OR_OBJ->loadBinRef($ref)
##  + drops closures
##  + INHERITED from DTA::CAB::Analyzer

##==============================================================================
## Methods: Analysis
##==============================================================================

##------------------------------------------------------------------------
## Methods: Analysis: Generic

## $bool = $ach->canAnalyze()
## $bool = $ach->canAnalyze(\%opts)
##  + returns true if analyzer can perform its function (e.g. data is loaded & non-empty)
##  + returns true if all enabled analyzers in the chain can analyze
sub canAnalyze {
  my $ach = shift;
  my $subs = $ach->subAnalyzers(@_);
  foreach (grep {ref($_) && $_->enabled(@_)} @$subs) {
    if (!$_ || !$_->canAnalyze) {
      #$ach->logwarn("canAnalyze() returning 0 for sub-analyzer \"$_\"");
      return 0;
    }
  }
  return 1;
}


## $bool = $anl->enabled(\%opts)
##  + returns $anl->{enabled} and disjunction over all sub-analyzers
sub enabled {
  my $ach = shift;
  return $ach->SUPER::enabled(@_) && scalar(grep {$_->enabled(@_)} @{$ach->subAnalyzers(@_)});
}


## undef = $anl->initInfo()
##  + logs initialization info
##  + default method reports values of {label}, enabled()
sub initInfo {
  my $anl = shift;
  if (!$anl->{initQuiet}) {
    $anl->SUPER::initInfo(@_);
    $_->initInfo(@_) foreach (@{$anl->subAnalyzers(@_)});
    $anl->{initQuiet}=1;
  }
}


##==============================================================================
## Methods: Analysis: v1.x

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $ach->analyzeDocument($doc,\%opts)
##  + analyze a DTA::CAB::Document $doc
##  + top-level API routine
##  + INHERITED from DTA::CAB::Analyzer

## $doc = $ach->analyzeTypes($doc,$types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
##  + Chain default calls $a->analyzeTypes for each analyzer $a in the chain
sub analyzeTypes {
  my ($ach,$doc,$types,$opts) = @_;
  foreach (@{$ach->chain($opts)}) {
    next if (!$_->doAnalyze($opts,'Types') || !$_->enabled($opts));
    $ach->vlog($opts->{logTrace}//$ach->{logTrace},"analyzeTypes: $_->{label}");
    $_->analyzeTypes($doc,$types,$opts);
  }
  return $doc;
}

## $doc = $ach->analyzeTokens($doc,\%opts)
##  + perform token-wise analysis of all tokens $doc->{body}[$si]{tokens}[$wi]
##  + default implementation just shallow copies tokens in $doc->{types}
##  + INHERITED from DTA::CAB::Analyzer

## $doc = $ach->analyzeSentences($doc,\%opts)
##  + perform sentence-wise analysis of all sentences $doc->{body}[$si]
##  + Chain default calls $a->analyzeSentences for each analyzer $a in the chain
sub analyzeSentences {
  my ($ach,$doc,$opts) = @_;
  foreach (@{$ach->chain($opts)}) {
    next if (!$_->doAnalyze($opts,'Sentences') || !$_->enabled($opts));
    $ach->vlog($opts->{logTrace}//$ach->{logTrace},"analyzeSentences: $_->{label}");
    $_->analyzeSentences($doc,$opts);
  }
  return $doc;
}

## $doc = $ach->analyzeLocal($doc,\%opts)
##  + perform local document-level analysis of $doc
##  + Chain default calls $a->analyzeLocal for each analyzer $a in the chain
sub analyzeLocal {
  my ($ach,$doc,$opts) = @_;
  foreach (@{$ach->chain($opts)}) {
    next if (!$_->doAnalyze($opts,'Local') || !$_->enabled($opts));
    $ach->vlog($opts->{logTrace}//$ach->{logTrace},"analyzeLocal: $_->{label}");
    $_->analyzeLocal($doc,$opts);
  }
  return $doc;
}

## $doc = $ach->analyzeClean($doc,\%opts)
##  + cleanup any temporary data associated with $doc
##  + Chain default calls $a->analyzeClean for each analyzer $a in the chain,
##    then superclass Analyzer->analyzeClean
sub analyzeClean {
  my ($ach,$doc,$opts) = @_;
  foreach (@{$ach->chain($opts)}) {
    next if (!$_->doAnalyze($opts,'Clean') || !$_->enabled($opts));
    $ach->vlog($opts->{logTrace}//$ach->{logTrace},"analyzeClean: $_->{label}");
    $_->analyzeClean($doc,$opts);
  }
  return $ach->SUPER::analyzeClean($doc,$opts) if ($ach->doAnalyze($opts,'Clean'));
  return $doc;
}

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: Wrappers

## $tok = $ach->analyzeToken($tok_or_string,\%opts)
##  + perform type- and token-analyses on $tok_or_string
##  + wrapper for $ach->analyzeDocument()
##  + INHERITED from DTA::CAB::Analyzer

## $tok = $ach->analyzeSentence($sent_or_array,\%opts)
##  + perform type-, token-, and sentence-analyses on $sent_or_array
##  + wrapper for $ach->analyzeDocument()
##  + INHERITED from DTA::CAB::Analyzer

## $rpc_xml_base64 = $anl->analyzeData($data_str,\%opts)
##  + analyze a raw (formatted) data string $data_str with internal parsing & formatting
##  + wrapper for $anl->analyzeDocument()
##  + INHERITED from DTA::CAB::Analyzer

##==============================================================================
## Methods: XML-RPC
##  + INHERITED from DTA::CAB::Analyzer

1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl
=pod

=cut

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Chain - serial multi-analyzer pipeline

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Chain;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 @keys = $anl->typeKeys(\%opts);
 
 ##========================================================================
 ## Methods: Chain selection
 
 \@analyzers = $ach->chain();
 \@analyzers = $ach->subAnalyzers();
 
 ##========================================================================
 ## Methods: I/O
 
 $bool = $ach->ensureLoaded();
 
 ##========================================================================
 ## Methods: Analysis
 
 $bool = $ach->canAnalyze();
 $bool = $anl->enabled(\%opts);
 undef = $anl->initInfo();
 
 $doc = $ach->analyzeTypes($doc,$types,\%opts);
 $doc = $ach->analyzeSentences($doc,\%opts);
 $doc = $ach->analyzeLocal($doc,\%opts);
 $doc = $ach->analyzeClean($doc,\%opts);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Chain
is an abstract L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> subclass
for implementing serial document processing "pipelines" or "cascades"
in terms of a flat list of L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> objects.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

%$obj, %args:

 chain => [ $a1, $a2, ..., $aN ],        ##-- default analysis chain; see also chain() method (default: empty)

=item typeKeys

 @keys = $anl->typeKeys(\%opts);

Returns list of type-wise keys to be expanded for this analyzer by expandTypes()
Default implementation just concatenates typeKeys() for sub-analyzers.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain: Methods: Chain selection
=pod

=head2 Methods: Chain selection

=over 4

=item chain

 \@analyzers = $ach->chain();
 \@analyzers = $ach->chain(\%opts)

Get selected analyzer chain.
Default method returns all globally enabled analyzers in $anl-E<gt>{chain}.

=item subAnalyzers

 \@analyzers = $ach->subAnalyzers();
 \@analyzers = $ach->subAnalyzers(\%opts)

Returns a list of all sub-analyzers.
Override just calls chain().

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain: Methods: I/O
=pod

=head2 Methods: I/O

=over 4

=item ensureLoaded

 $bool = $ach->ensureLoaded();
 $bool = $ach->ensureLoaded(\%opts)

Ensures analysis data is loaded from default files
Override calls $a-E<gt>ensureLoaded() for each $a in $ach-E<gt>subAnalyzers(\%opts).

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain: Methods: Analysis
=pod

=head2 Methods: Analysis

=over 4

=item canAnalyze

 $bool = $ach->canAnalyze();
 $bool = $ach->canAnalyze(\%opts)

Returns true if analyzer can perform its function (e.g. data is loaded & non-empty).
Override returns true if all enabled analyzers in the chain can analyze.

=item enabled

 $bool = $anl->enabled(\%opts);

Returns $anl-E<gt>{enabled} and (disjunction over all sub-analyzers).

=item initInfo

 undef = $anl->initInfo();

Logs initialization info.
Default method reports values of {label}, enabled().

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain: Methods: Analysis: API
=pod

=head2 Methods: Analysis: API

=over 4

=item analyzeTypes

 $doc = $ach->analyzeTypes($doc,$types,\%opts);

Perform type-wise analysis of all (text) types in $doc-E<gt>{types}.
Chain default calls $a-E<gt>analyzeTypes for each analyzer $a in the chain.

=item analyzeSentences

 $doc = $ach->analyzeSentences($doc,\%opts);

Perform sentence-wise analysis of all sentences $doc-E<gt>{body}[$si].
Chain default calls $a-E<gt>analyzeSentences for each analyzer $a in the chain.

=item analyzeLocal

 $doc = $ach->analyzeLocal($doc,\%opts);

Perform local document-level analysis of $doc.
Chain default calls $a-E<gt>analyzeLocal for each analyzer $a in the chain.

=item analyzeClean

 $doc = $ach->analyzeClean($doc,\%opts);

Cleanup any temporary data associated with $doc.
Chain default calls $a-E<gt>analyzeClean for each analyzer $a in the chain,
then superclass Analyzer-E<gt>analyzeClean.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl
=pod



=cut

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB::Chain::Multi(3pm)|DTA::CAB::Chain::Multi>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut

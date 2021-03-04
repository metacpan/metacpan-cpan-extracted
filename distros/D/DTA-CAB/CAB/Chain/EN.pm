## -*- Mode: CPerl -*-
## File: DTA::CAB::Chain::EN.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: robust analysis: default chain (english)

package DTA::CAB::Chain::EN;
use DTA::CAB::Datum ':all';
use DTA::CAB::Chain::Multi;

##-- sub-analyzers
use DTA::CAB::Analyzer::TokPP;
use DTA::CAB::Analyzer::Morph::Helsinki::EN;
use DTA::CAB::Analyzer::Morph::Latin;
use DTA::CAB::Analyzer::MorphSafe;
use DTA::CAB::Analyzer::Moot;
use DTA::CAB::Analyzer::MootSub;
use DTA::CAB::Analyzer::LangId::Simple;
use DTA::CAB::Analyzer::DTAClean;
use DTA::CAB::Analyzer::Null;

use IO::File;
use Carp;

use strict;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::CAB::Chain::Multi);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure: HASH
sub new {
  my $that = shift;
  return $that->SUPER::new
    (
     ##-- analyzers
     tokpp => DTA::CAB::Analyzer::TokPP->new(),
     xlit  => DTA::CAB::Analyzer::Unicruft->new(),
     ##
     morph => DTA::CAB::Analyzer::Morph::Helsinki::EN->new(),
     mlatin=> DTA::CAB::Analyzer::Morph::Latin->new(),
     msafe => DTA::CAB::Analyzer::MorphSafe->new(), ##-- remove this for en-chain?
     ##
     moot  => DTA::CAB::Analyzer::Moot->new(lang=>'en'), ##-- moot tagger (on dmoot output; (n>1)-grams)
     moot1 => DTA::CAB::Analyzer::Moot->new(lang=>'en'), ##-- moot tagger (on dmoot output; 1-grams only)
     mootsub => DTA::CAB::Analyzer::MootSub->new(ucTags=>[],stts=>0,wMorph=>.2), ##-- moot tagger, post-processing hacks
     ##
     langid => DTA::CAB::Analyzer::LangId::Simple->new(defaultLang=>'en'), ##-- language-guesser (stopword-based; between msafe and rw)
     ##
     clean => DTA::CAB::Analyzer::DTAClean->new(),
     ##
     null => DTA::CAB::Analyzer::Null->new(), ##-- null analyzer (for 'null' chain)

     ##-- security
     autoClean => 0, ##-- always run 'clean' analyzer regardless of options; checked in both doAnalyze(), analyzeClean()
     defaultChain => 'default',

     ##-- user args
     @_,

     ##-- overrides
     chains => undef,		##-- see setupChains() method
     chain => undef,		##-- see setupChains() method
    );
}

##==============================================================================
## Methods: Chain selection
##==============================================================================

## $ach = $ach->setupChains()
##  + setup default named sub-chains in $ach->{chains}
##  + override
##  + adapted from Chain::DTA
sub setupChains {
  my $ach = shift;
  my @akeys = grep {UNIVERSAL::isa($ach->{$_},'DTA::CAB::Analyzer')} keys(%$ach);
  my $chains = $ach->{chains} =
    {
     (map {("sub.$_"=>[$ach->{$_}])} @akeys), ##-- sub.xlit, sub.lts, ...
     #(map {("$_"=>[$ach->{$_}])} @akeys),     ##-- xlit, lts, ...
     ##
     'sub.sent'       =>[@$ach{qw(moot  mootsub)}],
     'sub.sent1'      =>[@$ach{qw(moot1 mootsub)}],
     ##
     'default.tokpp'  =>[@$ach{qw(tokpp)}],
     'default.xlit'   =>[@$ach{qw(xlit)}],
     'default.morph'  =>[@$ach{qw(tokpp xlit morph)}],
     'default.mlatin' =>[@$ach{qw(tokpp xlit       mlatin)}],
     'default.msafe'  =>[@$ach{qw(tokpp xlit morph mlatin msafe)}],
     'default.langid' =>[@$ach{qw(tokpp xlit morph mlatin msafe langid)}],
     'default.langid' =>[@$ach{qw(tokpp xlit morph mlatin langid)}],
     'default.moot'     =>[@$ach{qw(tokpp xlit              morph mlatin msafe langid moot)}],
     'default.moot1'    =>[@$ach{qw(tokpp xlit              morph mlatin msafe langid moot1)}],
     'default.lemma'    =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot  mootsub)}],
     'default.lemma1'   =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot1 mootsub)}],
     'default.base'     =>[@$ach{qw(tokpp xlit morph mlatin msafe langid)}],
     'default.type'     =>[@$ach{qw(tokpp xlit morph mlatin msafe langid)}],
     ##
     'norm'          =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot  mootsub)}],
     'norm1'         =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot1 mootsub)}],
     'all'           =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot  mootsub)}], ##-- old dta clients use 'all'!
     'clean'         =>[@$ach{qw(clean)}],
     'null'	     =>[$ach->{null}],
    };
  #$chains->{'default'} = [map {@{$chains->{$_}}} qw(default.type sub.sent)];

  ##-- chain aliases
  $chains->{'default'}  = $chains->{lemma}  = $chains->{'norm'};
  $chains->{'default1'} = $chains->{lemma1} = $chains->{'norm1'};

  ##-- sanitize chains
  foreach (values %{$ach->{chains}}) {
    @$_ = grep {ref($_)} @$_;
  }

  ##-- set default chain
  $ach->{chain} = $ach->{chains}{$ach->{defaultChain}};

  ##-- force default labels
  foreach (grep {UNIVERSAL::isa($ach->{$_},'DTA::CAB::Analyzer')} keys(%$ach)) {
    next if ($_ =~ /^(?:langid)$/);       ##-- keep these labels
    ($ach->{$_}{label} = $_) =~ s/1$//;   ##-- truncate '1' suffix for label (e.g. dmoot1, moot1)
  }
  return $ach;
}

## \@analyzers = $ach->chain()
## \@analyzers = $ach->chain(\%opts)
##  + get selected analyzer chain
##  + inherited from DTA::CAB::Chain::Multi
##    - calls setupChains() if $ach->{chain} is empty
##    - checks for $opts{chain} and returns $ach->{chains}{ $opts{chain} } if available

## $ach = $ach->ensureChain()
##  + checks for $ach->{chain}, calls $ach->setupChains() if needed
##  + inherited from DTA::CAB::Chain::Multi

##==============================================================================
## Methods: I/O
##==============================================================================


##==============================================================================
## Methods: Persistence
##==============================================================================

##======================================================================
## Methods: Persistence: Perl

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
##  + default just greps for CODE-refs
##  + inherited from DTA::CAB::Chain::Multi: override appends {chain},{chains}

## $saveRef = $obj->savePerlRef()
##  + return reference to be saved (top-level objects only)
##  + inherited from DTA::CAB::Persistent

## $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref)
##  + default implementation just clobbers $CLASS_OR_OBJ with $ref and blesses
##  + inherited from DTA::CAB::Persistent

##==============================================================================
## Methods: Analysis
##==============================================================================

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: Utils

## $bool = $anl->doAnalyze(\%opts, $name)
##  + alias for $anl->can("analyze${name}") && (!exists($opts{"doAnalyze${name}"}) || $opts{"doAnalyze${name}"})
##  + override checks $anl->{autoClean} flag
sub doAnalyze {
  my ($anl,$opts,$name) = @_;
  return 1 if ($anl->{autoClean} && $name eq 'Clean');
  return $anl->SUPER::doAnalyze($opts,$name);
}


##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $ach->analyzeDocument($doc,\%opts)
##  + analyze a DTA::CAB::Document $doc
##  + top-level API routine
##  + INHERITED from DTA::CAB::Analyzer

## $doc = $ach->analyzeTypes($doc,$types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
##  + Chain default calls $a->analyzeTypes for each analyzer $a in the chain
##  + INHERITED from DTA::CAB::Chain

## $doc = $ach->analyzeTokens($doc,\%opts)
##  + perform token-wise analysis of all tokens $doc->{body}[$si]{tokens}[$wi]
##  + default implementation just shallow copies tokens in $doc->{types}
##  + INHERITED from DTA::CAB::Analyzer

## $doc = $ach->analyzeSentences($doc,\%opts)
##  + perform sentence-wise analysis of all sentences $doc->{body}[$si]
##  + Chain default calls $a->analyzeSentences for each analyzer $a in the chain
##  + INHERITED from DTA::CAB::Chain

## $doc = $ach->analyzeLocal($doc,\%opts)
##  + perform local document-level analysis of $doc
##  + Chain default calls $a->analyzeLocal for each analyzer $a in the chain
##  + INHERITED from DTA::CAB::Chain

## $doc = $ach->analyzeClean($doc,\%opts)
##  + cleanup any temporary data associated with $doc
##  + Chain default calls $a->analyzeClean for each analyzer $a in the chain,
##    then superclass Analyzer->analyzeClean
sub analyzeClean {
  my ($ach,$doc,$opts) = @_;
  $ach->SUPER::analyzeClean($doc,$opts);                                    ##-- inherited from DTA::CAB::Chain (chain-local cleanup)
  $ach->analyzeClean_rm_undef($doc,$opts);                                  ##-- remove keys with undef values from tokens
  return $doc if (!$ach->{autoClean} && !exists($opts->{doAnalyzeClean}));  ##-- don't "clean" by default
  return $ach->{clean}->analyzeClean($doc,$opts);
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
##  + INHERITED from DTA::CAB::Chain::Multi

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Chain::EN - DTA-like analysis chain class for contemporary english

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Chain::EN;
 
 ##========================================================================
 ## Methods
 
 $obj = CLASS_OR_OBJ->new(%args);
 $ach = $ach->setupChains();
 $bool = $ach->ensureLoaded();
 $bool = $anl->doAnalyze(\%opts, $name);
 $doc = $ach->analyzeClean($doc,\%opts);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Chain::EN
is a L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> subclass with
a L<DTA::CAB::Chain::DTA|DTA::CAB::Chain::DTA>-like naming scheme
suitable for analyzing contemporary English input.
This class inherits from
L<DTA::CAB::Chain::Multi|DTA::CAB::Chain::Multi>.
See the L</setupChains> method for a list of supported sub-chains
and the corresponding analyers.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain::DTA: Methods
=pod

=head2 Methods

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

%$obj, %args:

 ##-- paranoia
 autoClean => 0,  ##-- always run 'clean' analyzer regardless of options; checked in both doAnalyze(), analyzeClean()
 defaultChain => 'default',
 ##
 ##-- overrides
 chains => undef, ##-- see setupChains() method
 chain => undef, ##-- see setupChains() method

Additionally, the following sub-analyzers are defined
as fields of %$obj:

=over 4

=item tokpp

Token preprocessor,
a L<DTA::CAB::Analyzer::TokPP|DTA::CAB::Analyzer::TokPP> object.

=item xlit

Transliterator,
a L<DTA::CAB::Analyzer::Unicruft|DTA::CAB::Analyzer::Unicruft> object.

=item morph

Morphological analyzer (Helsinki-style with TAGH emulation hacks),
a L<DTA::CAB::Analyzer::Morph::Helsinki::EN|DTA::CAB::Analyzer::Morph::Helsinki::EN> object.

=item mlatin

Latin pseudo-morphology,
a L<DTA::CAB::Analyzer::Morph::Latin|DTA::CAB::Analyzer::Morph::Latin> object.

=item msafe

Morphological security heuristics,
a L<DTA::CAB::Analyzer::MorphSafe|DTA::CAB::Analyzer::MorphSafe> object.

=item moot

HMM part-of-speech tagger,
a L<DTA::CAB::Analyzer::Moot|DTA::CAB::Analyzer::Moot> object.

=item mootsub

Post-processing for L</moot> tagger,
a L<DTA::CAB::Analyzer::MootSub|DTA::CAB::Analyzer::MootSub> object.

=item clean

Janitor (paranoid removal of internal temporary data),
a L<DTA::CAB::Analyzer::DTAClean|DTA::CAB::Analyzer::DTAClean> object.

=back

=back


=item setupChains

 $ach = $ach->setupChains();

Setup default named sub-chains in $ach-E<gt>{chains}.
Currently defines a singleton chain C<sub.NAME>
for each analyzer key in keys(%$ach), as well as the following
non-trivial chains:

 'sub.sent'       =>[@$ach{qw(moot  mootsub)}],
 'sub.sent1'      =>[@$ach{qw(moot1 mootsub)}],
 ##
 'default.tokpp'  =>[@$ach{qw(tokpp)}],
 'default.xlit'   =>[@$ach{qw(xlit)}],
 'default.morph'  =>[@$ach{qw(tokpp xlit morph)}],
 'default.mlatin' =>[@$ach{qw(tokpp xlit       mlatin)}],
 'default.msafe'  =>[@$ach{qw(tokpp xlit morph mlatin msafe)}],
 'default.langid' =>[@$ach{qw(tokpp xlit morph mlatin msafe langid)}],
 'default.moot'   =>[@$ach{qw(tokpp xlit              morph mlatin msafe langid moot)}],
 'default.moot1'  =>[@$ach{qw(tokpp xlit              morph mlatin msafe langid moot1)}],
 'default.lemma'  =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot  mootsub)}],
 'default.lemma1' =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot1 mootsub)}],
 'default.base'   =>[@$ach{qw(tokpp xlit morph mlatin msafe langid)}],
 'default.type'   =>[@$ach{qw(tokpp xlit morph mlatin msafe langid)}],
 ##
 'norm'           =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot  mootsub)}],
 'norm1'          =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot1 mootsub)}],
 'all'            =>[@$ach{qw(tokpp xlit morph mlatin msafe langid moot  mootsub)}], ##-- old dta clients use 'all'!
 'clean'          =>[@$ach{qw(clean)}],
 'null'           =>[$ach->{null}],

=item ensureLoaded

 $bool = $ach->ensureLoaded();

Ensures analysis data is loaded from default files.
Inherited DTA::CAB::Chain::Multi override calls ensureChain() before inherited method.
Hack copies chain sub-analyzers (rwsub, dmootsub) AFTER loading their own sub-analyzers,
setting 'enabled' only then if appropriate.


=item doAnalyze

 $bool = $anl->doAnalyze(\%opts, $name);

Alias for $anl-E<gt>can("analyze${name}") && (!exists($opts{"doAnalyze${name}"}) || $opts{"doAnalyze${name}"}).
Override checks $anl-E<gt>{autoClean} flag.


=item analyzeClean

 $doc = $ach->analyzeClean($doc,\%opts);

Cleanup any temporary data associated with $doc.
Chain default calls $a-E<gt>analyzeClean for each analyzer $a in the chain,
then superclass Analyzer-E<gt>analyzeClean.
Local override checks $ach-E<gt>{autoClean}.

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

Copyright (C) 2016-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<DTA::CAB::Chain::Multi(3pm)|DTA::CAB::Chain::Multi>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut

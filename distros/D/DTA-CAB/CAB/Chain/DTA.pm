## -*- Mode: CPerl -*-
## File: DTA::CAB::Chain::DTA.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: robust analysis: default chain

package DTA::CAB::Chain::DTA;
use DTA::CAB::Datum ':all';
use DTA::CAB::Chain::Multi;

##-- sub-analyzers
use DTA::CAB::Analyzer::ExLex;
use DTA::CAB::Analyzer::Cache::Static;
use DTA::CAB::Analyzer::TokPP;
use DTA::CAB::Analyzer::LTS;
use DTA::CAB::Analyzer::Morph;
use DTA::CAB::Analyzer::Morph::Latin;
use DTA::CAB::Analyzer::Morph::Extra::OrtLexHessen; ##-- auxilliary DB: Siedlungsplaetze_Hessen, from HLGL Marburg (optional)
use DTA::CAB::Analyzer::MorphSafe;
use DTA::CAB::Analyzer::Rewrite;
use DTA::CAB::Analyzer::Moot;
use DTA::CAB::Analyzer::Moot::Boltzmann;
use DTA::CAB::Analyzer::EqPho;
use DTA::CAB::Analyzer::EqPhoX;
use DTA::CAB::Analyzer::EqRW;
use DTA::CAB::Analyzer::RewriteSub;
use DTA::CAB::Analyzer::DmootSub;
use DTA::CAB::Analyzer::LangId::Simple;
use DTA::CAB::Analyzer::MootSub;
use DTA::CAB::Analyzer::EqLemma;
use DTA::CAB::Analyzer::DTAMapClass;
use DTA::CAB::Analyzer::SynCoPe::NER;
use DTA::CAB::Analyzer::GermaNet::Hypernyms;
use DTA::CAB::Analyzer::GermaNet::Hyponyms;
use DTA::CAB::Analyzer::GermaNet::Synonyms;
use DTA::CAB::Analyzer::DTAClean;
use DTA::CAB::Analyzer::Null;

use IO::File;
use Carp;

use strict;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::CAB::Chain::Multi);

## supported date-optimized rewrite-ranges
our @RW_RANGES = qw(1600-1700 1700-1800 1800-1900);

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
     static => DTA::CAB::Analyzer::Cache::Static->new(typeKeys=>[qw(eqphox errid exlex f lts mlatin morph msafe pnd rw xlit lang)]),
     exlex => DTA::CAB::Analyzer::ExLex->new(),
     tokpp => DTA::CAB::Analyzer::TokPP->new(),
     xlit  => DTA::CAB::Analyzer::Unicruft->new(),
     ##
     lts   => DTA::CAB::Analyzer::LTS->new(),
     ##
     morph => DTA::CAB::Analyzer::Morph->new(),
     mlatin=> DTA::CAB::Analyzer::Morph::Latin->new(),
     mhessen => DTA::CAB::Analyzer::Morph::Extra::OrtLexHessen->new(),
     mhessengeo => DTA::CAB::Analyzer::Morph::Extra::GeoLexHessen->new(),
     msafe => DTA::CAB::Analyzer::MorphSafe->new(),
     rw    => DTA::CAB::Analyzer::Rewrite->new(),
     (map {("rw.$_" => DTA::CAB::Analyzer::Rewrite->new())} @RW_RANGES),
     rwsub => DTA::CAB::Analyzer::RewriteSub->new(),
     ##
     eqphox => DTA::CAB::Analyzer::EqPhoX->new(),
     eqpho => DTA::CAB::Analyzer::EqPho->new(),
     eqrw  => DTA::CAB::Analyzer::EqRW->new(),
     ##
     ##
     dmoot  => DTA::CAB::Analyzer::Moot::Boltzmann->new(), ##-- moot n-gram disambiguator ((n>=1)-grams)
     dmoot1 => DTA::CAB::Analyzer::Moot::Boltzmann->new(), ##-- moot n-gram disambiguator (1-grams only)
     dmootsub => DTA::CAB::Analyzer::DmootSub->new(), ##-- moot n-gram disambiguator: sub-morph
     moot  => DTA::CAB::Analyzer::Moot->new(), ##-- moot tagger (on dmoot output; (n>1)-grams)
     moot1 => DTA::CAB::Analyzer::Moot->new(), ##-- moot tagger (on dmoot output; 1-grams only)
     mootsub => DTA::CAB::Analyzer::MootSub->new(), ##-- moot tagger, post-processing hacks
     mapclass => DTA::CAB::Analyzer::DTAMapClass->new(), ##-- mapping class (post-moot)
     ##
     langid => DTA::CAB::Analyzer::LangId::Simple->new(), ##-- language-guesser (stopword-based; between msafe and rw)
     ##
     ner => DTA::CAB::Analyzer::SynCoPe::NER->new(), ##-- ne-recognizer (post-moot)
     ##
     eqlemma  => DTA::CAB::Analyzer::EqLemma->new(), ##-- eqlemma (best only)
     ##
     'gn-syn' => DTA::CAB::Analyzer::GermaNet::Synonyms->new(),   ##-- GermaNet synonyms
     'gn-isa' => DTA::CAB::Analyzer::GermaNet::Hypernyms->new(),  ##-- GermaNet hyperyms (superclasses)
     'gn-asi' => DTA::CAB::Analyzer::GermaNet::Hyponyms->new(),   ##-- GermaNet hyponyms (subclasses)
     ##
     'ot-syn' => DTA::CAB::Analyzer::GermaNet::Synonyms->new(label=>'ot-syn'),   ##-- OpenThesaurus synonyms
     'ot-isa' => DTA::CAB::Analyzer::GermaNet::Hypernyms->new(label=>'ot-isa'),  ##-- OpenThesaurus hypernyms (superclasses)
     'ot-asi' => DTA::CAB::Analyzer::GermaNet::Hyponyms->new(label=>'ot-asi'),   ##-- OpenThesaurus hyponyms (subclasses)
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
##  + dta ddc and django cab demo both call 'all' chain:
##    - ddc web search: (client = 194.95.188.36 = services.dwds.de)
##        2010-11-19 13:15:42 [24194] (DEBUG) DTA.CAB.Server.XmlRpc.Procedure: dta.cab.all.analyzeToken(): client=194.95.188.36
##    - django cab demo (client = 194.95.188.22 = www.deutschestextchiv.de)
##        2010-11-19 13:15:09 [24194] (DEBUG) DTA.CAB.Server.XmlRpc.Procedure: dta.cab.all.analyzeToken(): client=194.95.188.22
sub setupChains {
  my $ach = shift;
  $ach->{rwsub}{chain} = [@$ach{qw(lts morph)}];
  $ach->{dmootsub}{chain} = [@$ach{qw(morph mlatin)}]; #mhessen mhessengeo
  my @akeys = grep {UNIVERSAL::isa($ach->{$_},'DTA::CAB::Analyzer')} keys(%$ach);
  my $chains = $ach->{chains} =
    {
     (map {("sub.$_"=>[$ach->{$_}])} @akeys), ##-- sub.xlit, sub.lts, ...
     #(map {("$_"=>[$ach->{$_}])} @akeys),     ##-- xlit, lts, ...
     ##
     'sub.expand'     =>[@$ach{qw(eqpho eqrw eqlemma)}],
     'sub.sent'       =>[@$ach{qw(dmoot  dmootsub moot  mootsub)}],
     'sub.sent1'      =>[@$ach{qw(dmoot1 dmootsub moot1 mootsub)}],
     'sub.gn'	      =>[@$ach{qw(gn-syn gn-isa gn-asi)}],
     'sub.ot'	      =>[@$ach{qw(ot-syn ot-isa ot-asi)}],
     ##
     'default.static' =>[@$ach{qw(static)}],
     'default.exlex'  =>[@$ach{qw(exlex)}],
     'default.tokpp'  =>[@$ach{qw(tokpp)}],
     'default.xlit'   =>[@$ach{qw(xlit)}],
     'default.lts'    =>[@$ach{qw(xlit lts)}],
     'default.eqphox' =>[@$ach{qw(tokpp xlit lts eqphox)}],
     'default.morph'  =>[@$ach{qw(tokpp xlit morph)}],
     'default.mlatin' =>[@$ach{qw(tokpp xlit       mlatin)}],
     'default.mhessen'=>[@$ach{qw(tokpp xlit       mhessen)}],
     'default.mhessengeo'=>[@$ach{qw(tokpp xlit    mhessengeo)}],
     'default.msafe'  =>[@$ach{qw(tokpp xlit morph mlatin msafe)}],
     'default.langid' =>[@$ach{qw(tokpp xlit morph mlatin msafe langid)}],
     'default.rw'     =>[@$ach{qw(tokpp xlit rw)}],
     'default.rw.safe'=>[@$ach{qw(tokpp xlit                         morph mlatin msafe langid rw)}],
     'default.dmoot'  =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot)}],
     'default.dmoot1' =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot1)}],
     'default.moot'   =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot  dmootsub moot)}],
     'default.moot1'  =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot1 dmootsub moot1)}],
     'default.lemma'  =>[@$ach{qw(tokpp xlit lts eqphox morph mlatin msafe langid rw        dmoot1 dmootsub moot  mootsub)}],
     'default.lemma1' =>[@$ach{qw(tokpp xlit lts eqphox morph mlatin msafe langid rw        dmoot1 dmootsub moot1 mootsub)}],
     'default.ner'    =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot  dmootsub moot mootsub ner)}],
     'default.base'   =>[@$ach{qw(static exlex tokpp xlit lts        morph mlatin msafe langid)}],
     'default.type'   =>[@$ach{qw(static exlex tokpp xlit lts        morph mlatin msafe langid rw rwsub)}],
     ##
     'expand.old'     =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw       eqpho eqrw)}],
     'expand.ext'     =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw       eqpho eqrw eqphox)}],
     'expand.all'     =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw       eqpho eqrw eqphox dmoot1 dmootsub moot1 mootsub eqlemma)}],
     'expand.eqpho'   =>[@$ach{qw(static exlex       xlit lts                             eqpho)}],
     'expand.eqrw'    =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw             eqrw)}],
     'expand.eqlemma' =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub eqlemma)}],
     'expand.gn-syn'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub gn-syn)}],
     'expand.gn-isa'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub gn-isa)}],
     'expand.gn-asi'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub gn-asi)}],
     'expand.gn'      =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub gn-syn gn-isa gn-asi)}],
     'expand.ot-syn'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub ot-syn)}],
     'expand.ot-isa'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub ot-isa)}],
     'expand.ot-asi'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub ot-asi)}],
     'expand.ot'      =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub ot-syn ot-isa ot-asi)}],
     ##
     'norm'           =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot  dmootsub moot  mootsub)}],
     'norm1'          =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot1 dmootsub moot1 mootsub)}],
     'ner'            =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot  dmootsub moot  mootsub ner)}],
     'caberr'         =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot  dmootsub moot  mootsub mapclass)}],
     'caberr1'        =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot1 dmootsub moot1 mootsub mapclass)}],
     'all'            =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw rwsub eqpho eqrw eqphox dmoot  dmootsub moot  mootsub eqlemma)}], ##-- old dta clients use 'all'!
     'clean'          =>[@$ach{qw(clean)}],
     'null'           =>[$ach->{null}],
    };
  #$chains->{'default'} = [map {@{$chains->{$_}}} qw(default.type sub.sent)];

  ##-- chain aliases
  $chains->{'default'}  = $chains->{lemma}  = $chains->{'norm'};
  $chains->{'default1'} = $chains->{lemma1} = $chains->{'norm1'};
  $chains->{'expand'}   = $chains->{'expand.all'};

  ##-- BEGIN TEMPORARY custom chain(s): "hlgl": place-name recognition Hessen
  $chains->{"norm.hlgl"}  = [map {($_,$_ eq $ach->{mlatin} ? $ach->{mhessen} : qw())} @{$chains->{norm}}];
  $chains->{"norm1.hlgl"} = [map {($_,$_ eq $ach->{mlatin} ? $ach->{mhessen} : qw())} @{$chains->{norm1}}];
  ##
  $chains->{"norm.hlgl.geo"}  = [map {($_,$_ eq $ach->{mlatin} ? $ach->{mhessengeo} : qw())} @{$chains->{norm}}];
  $chains->{"norm1.hlgl.geo"} = [map {($_,$_ eq $ach->{mlatin} ? $ach->{mhessengeo} : qw())} @{$chains->{norm1}}];
  ##-- END TEMPORARY custom chain(s)

  ##-- date-dependent chains
  foreach my $rng (@RW_RANGES) {
    if ($ach->{"rw.$rng"} && ($ach->{"rw.$rng"}{enabled}//1)) {
      foreach my $key (qw(norm norm1 lemma lemma1 default default1 expand)) {
	$chains->{"$key.$rng"} = [map {$_ eq $ach->{rw} ? $ach->{"rw.$rng"} : $_} @{$chains->{$key}}];
      }
    } else {
      $ach->warn("optimized rewrite cascade rw.$rng not available: disabling derived chains for range $rng");
      delete $ach->{"rw.$rng"};
      delete $chains->{"sub.rw.$rng"};
    }
  }

  ##-- sanitize chains
  foreach (values %{$ach->{chains}}) {
    @$_ = grep {ref($_)} @$_;
  }

  ##-- set default chain
  $ach->{chain} = $ach->{chains}{$ach->{defaultChain}};

  ##-- force default labels
  foreach (grep {UNIVERSAL::isa($ach->{$_},'DTA::CAB::Analyzer')} keys(%$ach)) {
    next if ($_ =~ /^(?:langid|rw\.[0-9\-]+|mhessen(?:geo)?)$/);    ##-- keep labels for these analyzers
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

## $bool = $ach->ensureLoaded()
##  + ensures analysis data is loaded from default files
##  + inherited DTA::CAB::Chain::Multi override calls ensureChain() before inherited method
sub ensureLoaded {
  my $ach = shift;
  $ach->SUPER::ensureLoaded(@_) || return 0;

  ##-- hack: copy chain members AFTER loading for sub-analyzers, setting 'enabled' if appropriate
  my ($subkey);
  foreach $subkey (qw(rwsub dmootsub)) {
    if (ref($ach->{$subkey})) {
      foreach (grep {!$_->{"_${subkey}"}} @{$ach->{$subkey}{chain}}) {
	$_ = bless( {%$_}, ref($_) );
	$_->{label}   = $subkey.'_'.$_->{label};
	$_->{enabled} = $ach->{$subkey}{enabled};
	$_->{"_$subkey"}  = 1;
      }
    }
  }

  return 1;
}

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

DTA::CAB::Chain::DTA - Deutsches Textarchiv canonicalization chain class

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Chain::DTA;
 
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

DTA::CAB::Chain::DTA
is the L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> subclass implementing
the robust orthographic canonicalization cascade used in the
I<Deutsches Textarchiv> project.  This class inherits from
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

=item lts

Phonetizer (Letter-to-Sound mapper),
a L<DTA::CAB::Analyzer::LTS|DTA::CAB::Analyzer::LTS> object.

=item morph

Morphological analyzer (TAGH),
a L<DTA::CAB::Analyzer::Morph|DTA::CAB::Analyzer::Morph> object.

=item mlatin

Latin pseudo-morphology,
a L<DTA::CAB::Analyzer::Morph::Latin|DTA::CAB::Analyzer::Morph::Latin> object.

=item msafe

Morphological security heuristics,
a L<DTA::CAB::Analyzer::MorphSafe|DTA::CAB::Analyzer::MorphSafe> object.

=item rw

Weighted finite-state rewrite cascade,
a L<DTA::CAB::Analyzer::Rewrite|DTA::CAB::Analyzer::Rewrite> object.

Date-optimized variants C<rw.1600-1700>, C<rw.1700-1800>, and C<rw.1800-1900> may also be included.

=item rwsub

Post-processing for rewrite cascade,
a L<DTA::CAB::Analyzer::RewriteSub|DTA::CAB::Analyzer::RewriteSub> object.

=item eqphox

Intensional (TAGH-based) phonetic equivalence expander,
a L<DTA::CAB::Analyzer::EqPhoX|DTA::CAB::Analyzer::EqPhoX> object.

=item eqpho

Extensional (corpus-based) phonetic equivalence expander,
a L<DTA::CAB::Analyzer::EqPho|DTA::CAB::Analyzer::EqPho> object.

=item eqrw

Extensional rewrite-equivalence expander,
a L< DTA::CAB::Analyzer::EqRW| DTA::CAB::Analyzer::EqRW> object.

=item dmoot

Token-level dynamic HMM conflation disambiguator,
a L<DTA::CAB::Analyzer::Moot::DynLex|DTA::CAB::Analyzer::Moot::DynLex> object.

=item dmootsub

Post-processing for L</dmoot> analyzer,
a L<DTA::CAB::Analyzer::DmootSub|DTA::CAB::Analyzer::DmootSub> object.

=item moot

HMM part-of-speech tagger,
a L<DTA::CAB::Analyzer::Moot|DTA::CAB::Analyzer::Moot> object.

=item mootsub

Post-processing for L</moot> tagger,
a L<DTA::CAB::Analyzer::MootSub|DTA::CAB::Analyzer::MootSub> object.

=item eqlemma

Extensional (corpus-based) lemma-equivalence class expander,
a L< DTA::CAB::Analyzer::EqLemma| DTA::CAB::Analyzer::EqLemma> object.

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

 'sub.expand'     =>[@$ach{qw(eqpho eqrw eqlemma)}],
 'sub.sent'       =>[@$ach{qw(dmoot  dmootsub moot  mootsub)}],
 'sub.sent1'      =>[@$ach{qw(dmoot1 dmootsub moot1 mootsub)}],
 'sub.gn'         =>[@$ach{qw(gn-syn gn-isa gn-asi)}],
 'sub.ot'         =>[@$ach{qw(ot-syn ot-isa ot-asi)}],
 ##
 'default.static' =>[@$ach{qw(static)}],
 'default.exlex'  =>[@$ach{qw(exlex)}],
 'default.tokpp'  =>[@$ach{qw(tokpp)}],
 'default.xlit'   =>[@$ach{qw(xlit)}],
 'default.lts'    =>[@$ach{qw(xlit lts)}],
 'default.eqphox' =>[@$ach{qw(tokpp xlit lts eqphox)}],
 'default.morph'  =>[@$ach{qw(tokpp xlit morph)}],
 'default.mlatin' =>[@$ach{qw(tokpp xlit       mlatin)}],
 'default.msafe'  =>[@$ach{qw(tokpp xlit morph mlatin msafe)}],
 'default.langid' =>[@$ach{qw(tokpp xlit morph mlatin msafe langid)}],
 'default.rw'     =>[@$ach{qw(tokpp xlit rw)}],
 'default.rw.safe'=>[@$ach{qw(tokpp xlit                         morph mlatin msafe langid rw)}],
 'default.dmoot'  =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot)}],
 'default.dmoot1' =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot1)}],
 'default.moot'   =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot  dmootsub moot)}],
 'default.moot1'  =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot1 dmootsub moot1)}],
 'default.lemma'  =>[@$ach{qw(tokpp xlit lts eqphox morph mlatin msafe langid rw        dmoot1 dmootsub moot  mootsub)}],
 'default.lemma1' =>[@$ach{qw(tokpp xlit lts eqphox morph mlatin msafe langid rw        dmoot1 dmootsub moot1 mootsub)}],
 'default.ner'    =>[@$ach{qw(tokpp xlit              lts eqphox morph mlatin msafe langid rw        dmoot  dmootsub moot mootsub ner)}],
 'default.base'   =>[@$ach{qw(static exlex tokpp xlit lts        morph mlatin msafe langid)}],
 'default.type'   =>[@$ach{qw(static exlex tokpp xlit lts        morph mlatin msafe langid rw rwsub)}],
 ##
 'expand.old'     =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw       eqpho eqrw)}],
 'expand.ext'     =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw       eqpho eqrw eqphox)}],
 'expand.all'     =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw       eqpho eqrw eqphox dmoot1 dmootsub moot1 mootsub eqlemma)}],
 'expand.eqpho'   =>[@$ach{qw(static exlex       xlit lts                             eqpho)}],
 'expand.eqrw'    =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw             eqrw)}],
 'expand.eqlemma' =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub eqlemma)}],
 'expand.gn-syn'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub gn-syn)}],
 'expand.gn-isa'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub gn-isa)}],
 'expand.gn-asi'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub gn-asi)}],
 'expand.gn'      =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub gn-syn gn-isa gn-asi)}],
 'expand.ot-syn'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub ot-syn)}],
 'expand.ot-isa'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub ot-isa)}],
 'expand.ot-asi'  =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub ot-asi)}],
 'expand.ot'      =>[@$ach{qw(static exlex       xlit lts morph mlatin msafe rw                  eqphox dmoot1 dmootsub moot1 mootsub ot-syn ot-isa ot-asi)}],
 ##
 'norm'           =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot  dmootsub moot  mootsub)}],
 'norm1'          =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot1 dmootsub moot1 mootsub)}],
 'ner'            =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot  dmootsub moot  mootsub ner)}],
 'caberr'         =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot  dmootsub moot  mootsub mapclass)}],
 'caberr1'        =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw                  eqphox dmoot1 dmootsub moot1 mootsub mapclass)}],
 'all'            =>[@$ach{qw(static exlex tokpp xlit lts morph mlatin msafe langid rw rwsub eqpho eqrw eqphox dmoot  dmootsub moot  mootsub eqlemma)}],
 'clean'          =>[@$ach{qw(clean)}],
 ##
 'null'           =>[$ach->{null}],

High-level date-optimized chains C<norm.RNG>, C<norm1.RNG>, C<lemma.RNG>, C<lemma1.RNG>, C<default.RNG>, and C<expand.RNG>
are also defined using the date-optimized rewrite cascade C<rw.RNG> in place of the default "generic" cascade C<rw>
for each range I<RNG> in C<1600-1700>, C<1700-1800>, and C<1800-1900>.

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

Copyright (C) 2010-2019 by Bryan Jurish

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

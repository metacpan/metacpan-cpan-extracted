## -*- Mode: CPerl -*-
## File: DTA::CAB::Chain::Multi.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: robust analysis: multi-chains

package DTA::CAB::Chain::Multi;
use DTA::CAB::Datum ':all';
use DTA::CAB::Chain;
use IO::File;
use Carp;

use strict;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::CAB::Chain);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure: HASH
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- user args
			   @_,

			   ##-- overrides
			   chains => undef, ##-- ($chainName=>\@chainAnalyzers,...): see setupChains() method
			   chain => undef,  ##-- default chain: see setupChains() method
			  );
}

##==============================================================================
## Methods: Chain selection
##==============================================================================

## $ach = $ach->setupChains()
##  + setup default named sub-chains in $ach->{chains}
##  + set default chain $ach->{chain}
##  + default implementation just sets ($key=>[$ach->{$key}]) for each analyzer value in %$ach
##  + default implementation sets default chain to sorted list of analyzer values in %$ach
sub setupChains {
  my $ach = shift;
  my @akeys = sort grep {UNIVERSAL::isa($ach->{$_},'DTA::CAB::Analyzer')} keys(%$ach);
  my $chains = $ach->{chains} =
    {
     (map {("$_"=>[$ach->{$_}])} @akeys), ##-- e.g. sub.xlit, sub.lts, ...
     'default'  =>[@$ach{@akeys}],
    };

  ##-- sanitize chains
  foreach (values %{$ach->{chains}}) {
    @$_ = grep {ref($_)} @$_;
  }

  ##-- set default chain
  $ach->{chain} = $ach->{chains}{default};

  ##-- force default labels
  $ach->{$_}{label} = $_ foreach (grep {UNIVERSAL::isa($ach->{$_},'DTA::CAB::Analyzer')} keys(%$ach));

  ##-- return
  return $ach;
}

## $ach = $ach->ensureChain()
##  + checks for $ach->{chain}, calls $ach->setupChains() if needed
sub ensureChain {
  $_[0]->setupChains if (!$_[0]{chain} || !@{$_[0]{chain}});
  return $_[0];
}

## \@analyzers = $ach->chain()
## \@analyzers = $ach->chain(\%opts)
##  + get selected analyzer chain
##  + OVERRIDE calls setupChains() if $ach->{chain} is empty
##  + OVERRIDE checks for $opts{chain} and returns $ach->{chains}{ $opts{chain} } if available
##  + OVERRIDE splits $opts{chain} on /[\,\s]+/ and constructs chain
sub chain {
  $_[0]->ensureChain;
  if ($_[1] && $_[1]{chain}) {
    return $_[0]{chains}{$_[1]{chain}} if ($_[0]{chains}{$_[1]{chain}});     ##-- pre defined chain
    return [
	    grep {ref($_) && $_->enabled($_[1])}
	    map { @{$_[0]{chains}{$_} || ($_[0]{$_} ? [$_[0]{$_}] : undef) || $_[0]->logconfess("could not resolve chain component '$_'")} }
	    split(/[\,\s]+/,$_[1]{chain})
	   ];
  }
  return [grep {ref($_) && $_->enabled($_[1])} @{$_[0]{chain}}];
}

## $chainAnalyzer = $ach->getChain()
## $chainAnalyzer = $ach->getChain($chainSpec)
##  + returns a new DTA::CAB::Chain for the appropriate spec
sub getChain {
  return DTA::CAB::Chain->new( chain=>$_[0]->chain({chain=>$_[1]}) );
}

## \@analyzers = $ach->subAnalyzers()
## \@analyzers = $ach->subAnalyzers(\%opts)
##  + returns a list of all sub-analyzers
##  + override returns all defined analyzers in any chain in $ach->{chains} or in values(%$ach)
sub subAnalyzers {
  my $ach = shift;
  my %subh = map {(overload::StrVal($_)=>$_)} grep {ref($_) && UNIVERSAL::isa($_,'DTA::CAB::Analyzer')} values(%$ach);
  $subh{overload::StrVal($_)} = $_ foreach (@{$ach->chain(@_)});
  my ($ckey, $a);
  foreach $ckey (sort keys %{$ach->{chains}}) {
    foreach $a (grep {$_} @{$ach->{chains}{$ckey}||[]}) {
      $subh{overload::StrVal($a)} = $a;
    }
  }
  return [values %subh];
}


##==============================================================================
## Methods: I/O
##==============================================================================

## $bool = $ach->autoEnable()
##  + calls inherited autoEnable() method (auto-disable on all sub-analyzers)
##  + prunes disabled analyzers from chains?

## $bool = $ach->ensureLoaded()
##  + ensures analysis data is loaded from default files
##  + override calls ensureChain() before inherited method
##  + override sanitizes sub-chains to canAnalyze() sub-analyzers after load
sub ensureLoaded_OLD {
  my $ach = shift;
  $ach->ensureChain;
  my $rc = 1;

 LOAD_CHAIN:
  foreach (values %{$ach->{chains}}) {
    foreach (grep {$_} @$_) {
      $rc &&= $_->ensureLoaded();
      last LOAD_CHAIN if (!$rc);
    }

    ##-- sanitize sub-chain
    @$_ = grep {$_ && $_->canAnalyze} @$_;
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
##  + override appends {chain},{chains}
sub noSaveKeys {
  my $ach = shift;
  return ($ach::SUPER->noSaveKeys, qw(chain chains));
}

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
##  + INHERITED from DTA::CAB::Chain

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

## \@sigs = $anl->xmlRpcSignatures()
##  + returns an array-ref of valid XML-RPC signatures:
##    [ "$returnType1 $argType1_1 $argType1_2 ...", ..., "$returnTypeN ..." ]
##  + inherited from DTA::CAB::Analyzer::XmlRpc
#sub xmlRpcMethods {
#  my ($anl,$prefix,$opts) = @_;
#  $prefix = $prefix ? "${prefix}." : '';
#  $opts   = {} if (!$opts);
#  return map {$anl->SUPER::xmlRpcMethods($prefix.$_, {%$opts,chain=>$_})} keys(%{$anl->{chains}});
#}

## \%analyzerHash = $anl->xmlRpcAnalyzers()
## \%analyzerHash = $anl->xmlRpcAnalyzers($prefix)
##  + returns pseudo hash for use with DTA::CAB::Server::XmlRpc 'as' attribute
sub xmlRpcAnalyzers {
  my ($anl,$prefix) = @_;
  $prefix  = '' if (!defined($prefix));
  $prefix .= '.' if ($prefix && $prefix !~ /\.$/);
  $anl->ensureChain;
  return
    { (map {("${prefix}$_"=>bless({%$anl,chain=>$anl->{chains}{$_}},ref($anl)))} keys(%{$anl->{chains}})) };
}

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Chain::Multi - serial multi-analyzer pipelines with name-based dispatch

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Chain::Multi;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 
 ##========================================================================
 ## Methods: Chain selection
 
 $ach = $ach->setupChains();
 $ach = $ach->ensureChain();
 \@analyzers = $ach->chain();
 \@analyzers = $ach->subAnalyzers();
 
 
 ##========================================================================
 ## Methods: Persistence: Perl
 
 @keys = $class_or_obj->noSaveKeys();
 
 ##========================================================================
 ## Methods: XML-RPC
 
 \%analyzerHash = $anl->xmlRpcAnalyzers();
 


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Chain::Multi
is an abstract L<DTA::CAB::Chain|DTA::CAB::Chain> subclass
which supports user selection from a pre-defined set of named processing chains
at runtime.

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain::Multi: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

%$obj, %args

 chains => undef, ##-- ($chainName=>\@chainAnalyzers,...): see setupChains() method
 chain => undef,  ##-- default chain: see setupChains() method

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain::Multi: Methods: Chain selection
=pod

=head2 Methods: Chain selection

=over 4

=item setupChains

 $ach = $ach->setupChains();

Setup default named sub-chains in $ach-E<gt>{chains};
should also set default chain $ach-E<gt>{chain}.

Default implementation just sets ($key=E<gt>[$ach-E<gt>{$key}]) for each analyzer value in %$ach,
and sets default chain to sorted list of analyzer values in %$ach.

Subclasses will probably need to override this method.

=item ensureChain

 $ach = $ach->ensureChain();

Checks for $ach-E<gt>{chain}, calls $ach-E<gt>setupChains() if needed.

=item chain

 \@analyzers = $ach->chain();
 \@analyzers = $ach->chain(\%opts)

Get selected analyzer chain.

=over 4

=item *

Override calls setupChains() if $ach-E<gt>{chain} is empty

=item *

Override checks for $opts{chain} and returns $ach-E<gt>{chains}{ $opts{chain} } if available
(runtime user chain selection).

=item *

OVERRIDE splits $opts{chain} on /[\,\s]+/ and constructs chain
(runtime construction of user-specified chain).

=back

=item subAnalyzers

 \@analyzers = $ach->subAnalyzers();
 \@analyzers = $ach->subAnalyzers(\%opts)

Returns a list of all sub-analyzers.
Override returns all defined analyzers in any chain in $ach-E<gt>{chains} or in values(%$ach).

=back

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain::Multi: Methods: Persistence: Perl
=pod

=head2 Methods: Persistence: Perl

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Returns list of keys not to be saved
Override appends {chain},{chains} to superclass list.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Chain::Multi: Methods: XML-RPC
=pod

=head2 Methods: XML-RPC

=over 4

=item xmlRpcAnalyzers

 \%analyzerHash = $anl->xmlRpcAnalyzers();
 \%analyzerHash = $anl->xmlRpcAnalyzers($prefix)

Returns pseudo hash for use with L<DTA::CAB::Server::XmlRpc|DTA::CAB::Server::XmlRpc> 'as' attribute.

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
L<DTA::CAB::Chain::DTA(3pm)|DTA::CAB::Chain::DTA>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut

## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::DmootSub.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: sub-analysis (Morph,toka) of dmoot targets

##==============================================================================
## Package: Analyzer::DmootSub
##==============================================================================
package DTA::CAB::Analyzer::DmootSub;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Chain;
use DTA::CAB::Analyzer::Morph;
use Carp;
use strict;
our @ISA = qw(DTA::CAB::Chain);

##==============================================================================
## Methods: Constructors etc.

## $obj = $CLASS_OR_OBJ->new(chain=>\@analyzers, %args)
##  + basic object structure: (see also DTA::CAB::Chain)
##     chain => [$a1, ..., $aN], ##-- sub-analysis chain (e.g. chain=>[$morph,$mlatin])
##  + new object structure:
##     dmootLabel => $label,        ##-- label of source dmoot object (default='dmoot')
##     standalone => $bool,         ##-- if true, no sub-analysis or morph parsing will be done (default=false)
sub new {
  my $that = shift;
  my $asub = $that->SUPER::new(
			       ##-- defaults
			       #analysisClass => 'DTA::CAB::Analyzer::Rewrite::Analysis',
			       label => 'dmsub',

			       ##-- analysis selection
			       dmootLabel => 'dmoot',
			       standalone => 0,

			       ##-- user args
			       @_
			      );
  return $asub;
}

##==============================================================================
## Methods: I/O

##------------------------------------------------------------------------
## Methods: I/O: Input: all

## \@analyzers = $ach->chain()
## \@analyzers = $ach->chain(\%opts)
##  + get selected analyzer chain
###  + NEW: just return $ach->{chain}, since analyzers may still be disabled here (argh)
sub chain {
  my $ach = shift;
  return $ach->{chain};
  #return [grep {$_ && $_->enabled} @{$ach->{chain}}];
}

## $bool = $ach->ensureLoaded()
##  + returns true if any chain member loads successfully (or if the chain is empty)
sub ensureLoaded {
  my $ach = shift;
  @{$ach->{chain}} = grep {$_} @{$ach->{chain}}; ##-- hack: chuck undef chain-links here
  return 1 if (!@{$ach->{chain}});
  my $rc = 0;
  foreach (@{$ach->{chain}}) {
    $rc = $_->ensureLoaded() || $rc;
  }
  return $rc;
}

##==============================================================================
## Methods: Analysis

## $bool = $anl->doAnalyze(\%opts, $name)
##  + override: only allow analyzeSentences()
sub doAnalyze {
  my $anl = shift;
  return 0 if (defined($_[1]) && $_[1] ne 'Sentences');
  return $anl->SUPER::doAnalyze(@_);
}

## $doc = $anl->analyzeSentences($doc,\%opts)
##  + post-processing for 'dmoot' object
##  + extracts dmoot targets, builds pseudo-type hash, calls sub-chain analyzeTypes(), & expands back into 'dmoot' sources
sub analyzeSentences {
  my ($asub,$doc,$opts) = @_;
  return $doc if (!$asub->enabled($opts));

  ##-- load
  #$asub->ensureLoaded();

  ##-- get dmoot target types
  my $dmkey = $asub->{dmootLabel};
  my $standalone = $asub->{standalone};
  my $dmtypes = {};   ##-- $dmtypes:  {$dmootTag => {text=>$dmootTag, morph=>\@dmootMorph}, ... } ##-- analyzed types
  my $udmtypes = {};  ##-- $udmtypes: {$dmootTag => {text=>$dmootTag, morph=>undef, ...}}         ##-- un-analyzed types
  my $nil      = [];
  my ($tok,$txt,$dm,$dmtag,$dmtyp);
 TOK:
  foreach $tok (map {@{$_->{tokens}}} @{$doc->{body}}) {
    next if (!defined($dm=$tok->{$dmkey}));
    $dmtag = $dm->{tag};

    ##-- check for existing analyses
    $txt = $tok->{xlit} ? $tok->{xlit}{latin1Text} : $tok->{text};
    if (($tok->{toka} && @{$tok->{toka}}) || ($tok->{tokpp} && @{$tok->{tokpp}})) {
      ##-- existing analyses: toka|tokpp
      $dm->{morph} = [ map { {hi=>$_,w=>0} } @{$tok->{toka} // $tok->{tokpp} // $nil} ];
      $dm->{tag}   = $tok->{xlit} && $tok->{xlit}{isLatinExt} ? $tok->{xlit}{latin1Text} : $tok->{text}; ##-- force literal text for tokenizer-analyzed tokens
    }
    elsif (!$standalone) {
      $dmtyp = $dmtypes->{$dmtag};
      $dmtyp = $dmtypes->{$dmtag} = { text=>$dmtag } if (!defined($dmtyp));
      if ($dmtyp->{morph} && @{$dmtyp->{morph}}) {
	$dm->{morph} = $dmtyp->{morph} if (!$dm->{morph} || !@{$dm->{morph}});
	next;
      }

      if ($dmtag eq $txt) {
	##-- existing analyses: morph: from text
	$dm->{morph} = $dmtyp->{morph} = $tok->{morph};

	##-- latin analyses exist: add them
	$dm->{morph} = $dmtyp->{morph} = [@{$dm->{morph}||[]}, @{$tok->{mlatin}}] if ($tok->{mlatin});
      }
      else {
	foreach (grep {$_->{hi} eq $dmtag && $_->{morph}} @{$tok->{rw}}) {
	  ##-- existing analyses: morph: from rewrite
	  $dm->{morph} = $dmtyp->{morph} = $_->{morph};
	  last;
	}
      }
      ##-- oops... might need to re-analyze
      $udmtypes->{$dmtag} = $dmtyp if (!$dmtyp->{morph} || !@{$dmtyp->{morph}});
    }
  }

  ##-- analyze remaining dmoot types
  if (!$standalone) {
    my ($sublabel);
    foreach (@{$asub->{chain}}) {
      #$sublabel = $asub->{label}.'_'.$_->{label};
      $sublabel = $_->{label};
      next if (defined($opts->{$sublabel}) && !$opts->{$sublabel});
      $_->{label} =~ s/^\Q$asub->{label}_\E//;  ##-- sanitize label ("dmoot_morph" --> "morph"), because it's also used as output key
      $_->analyzeTypes($doc,$udmtypes,$opts);
      $_->{label} = $sublabel;
    }

    ##-- delete dmoot target type 'text'
    delete($_->{text}) foreach (values %$dmtypes);

    ##-- re-expand dmoot target fields (morph,mlatin): UNKNOWN ONLY
    foreach $tok (map {@{$_->{tokens}}} @{$doc->{body}}) {
      next if (!defined($dm=$tok->{$dmkey})
	       || !defined($dmtag=$dm->{tag})
	       || !defined($dmtyp=$udmtypes->{$dmtag}));
      @$dm{keys %$dmtyp} = values %$dmtyp;
      $dm->{morph} = [@{$dm->{morph}||[]}, @{$dm->{mlatin}}] if ($dm->{mlatin}); ##-- hack: adopt 'mlatin' into 'morph'
    }
  }

  ##-- return
  return $doc;
}

## @keys = $anl->typeKeys()
##  + returns list of type-wise keys to be expanded for this analyzer by expandTypes()
##  + override returns empty list
sub typeKeys {
  #return $_[0]{dmootLabel};
  return qw();
}

##------------------------------------------------------------------------
## Methods: Analysis: Generic

## $bool = $ach->canAnalyze()
## $bool = $ach->canAnalyze(\%opts)
##  + returns true if analyzer can perform its function (e.g. data is loaded & non-empty)
##  + override always returns 1 because of 'toka' hack
sub canAnalyze { return 1; }

sub canAnalyzeOLD {
  my $ach = shift;
  @{$ach->{chain}} = grep {$_ && $_->canAnalyze} @{$ach->chain(@_)};
  foreach (@{$ach->chain(@_)}) {
    return 1 if ($_->canAnalyze);
  }
  return 1;
}

## $bool = $anl->enabled(\%opts)
##  + returns $anl->{enabled} and disjunction over all sub-analyzers
##  + returns true if just $ach is enabled
sub enabled {
  my $ach = shift;
  return $ach->DTA::CAB::Analyzer::enabled(@_); #&& scalar(grep {$_->enabled(@_)} @{$ach->subAnalyzers(@_)});
}



1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::DmootSub - sub-analysis (Morph,toka) of dmoot targets

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Analyzer::DmootSub;
 
 ##========================================================================
 ## Methods: Constructors etc.
 
 $obj = $CLASS_OR_OBJ->new(chain=>\@analyzers, %args);
 
 ##========================================================================
 ## Methods: I/O
 
 \@analyzers = $ach->chain();
 $bool = $ach->ensureLoaded();
 
 ##========================================================================
 ## Methods: Analysis
 
 $bool = $anl->doAnalyze(\%opts, $name);
 @keys = $anl->typeKeys();
 $bool = $ach->canAnalyze();
 $bool = $anl->enabled(\%opts);
 


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Analyzer::DmootSub
provides a L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> subclass for
type-wise chained analysis of token-wise disambiguated input.  Specifically,
it was designed to invoke a morphological analyzer ('morph') on the output
of a dynamic lexicon HMM ('dmoot').
This class
inherits from L<DTA::CAB::Chain|DTA::CAB::Chain>
and implements the L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> API.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DmootSub: Methods: Constructors etc.
=pod

=head2 Methods: Constructors etc.

=over 4

=item new

 $obj = $CLASS_OR_OBJ->new(chain=>\@analyzers, %args);

%$obj, %args (see also DTA::CAB::Chain):

 chain => [$a1, ..., $aN],    ##-- sub-analysis chain (e.g. chain=>[$morph,$mlatin])
 dmootLabel => $label,        ##-- label of source dmoot object (default='dmoot')
 standalone => $bool,         ##-- if true, no sub-analysis or morph parsing will be done (default=false)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DmootSub: Methods: I/O: Input: all
=pod

=head2 Methods: I/O

=over 4

=item chain

 \@analyzers = $ach->chain();
 \@analyzers = $ach->chain(\%opts);

Get selected analyzer chain.
NEW: just return $ach-E<gt>{chain}, since analyzers may still be disabled here (argh)

=item ensureLoaded

 $bool = $ach->ensureLoaded();

Returns true if any chain member loads successfully (or if the chain is empty).
Hack: removes undefined chain-links before attempting to load sub-analyzers.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DmootSub: Methods: Analysis
=pod

=head2 Methods: Analysis

=over 4

=item doAnalyze

 $bool = $anl->doAnalyze(\%opts, $name);

Override: only allow analyzeSentences().

=item analyzeSentences

 $doc = $anl->analyzeSentences($doc,\%opts)

Post-processing for 'dmoot' object.
Extracts dmoot targets, builds pseudo-type hash, calls sub-chain analyzeTypes(), & expands back into 'dmoot' sources.

=item typeKeys

 @keys = $anl->typeKeys();

Returns list of type-wise keys to be expanded for this analyzer by expandTypes().
Override returns empty list.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DmootSub: Methods: Analysis: Generic
=pod

=head2 Methods: Analysis: Generic

=over 4

=item canAnalyze

 $bool = $ach->canAnalyze();
 $bool = $ach->canAnalyze(\%opts)

Returns true if analyzer can perform its function (e.g. data is loaded & non-empty).
Override always returns 1 because of 'toka' hack.

=item enabled

 $bool = $anl->enabled(\%opts);

Returns true if just $anl is enabled,
even if no sub-analyzers are enabled.

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

Copyright (C) 2011-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut

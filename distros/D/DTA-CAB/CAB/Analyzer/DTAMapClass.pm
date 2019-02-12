## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::DTAMapClass.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: post-processing for DTA chain: mapping class
##  + sets $tok->{mapclass}

package DTA::CAB::Analyzer::DTAMapClass;
use DTA::CAB::Analyzer ':child';
use Carp;
use strict;
our @ISA = qw(DTA::CAB::Analyzer);

##======================================================================
## Methods

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure, %args:
##     mootLabel => $label,    ##-- label for Moot tagger object (default='moot')
##     lz => $lemmatizer,      ##-- DTA::CAB::Analyzer::Lemmatizer sub-object
sub new {
  my $that = shift;
  my $asub = $that->SUPER::new(
			       ##-- analysis selection
			       label => 'mapclass',
			       xyTags => {map {($_=>undef)} qw(XY FM NE), '@UNKNOWN'}, ##-- if these tags are assigned, use literal text and not dmoot normalization

			       ##-- user args
			       @_
			      );
  return $asub;
}

## $bool = $anl->doAnalyze(\%opts, $name)
##  + override: only allow analyzeSentences()
sub doAnalyze {
  my $anl = shift;
  return 0 if (defined($_[1]) && $_[1] ne 'Sentences');
  return $anl->SUPER::doAnalyze(@_);
}

## $doc = $anl->Sentences($doc,\%opts)
##  + post-processing for 'moot' object
sub analyzeSentences {
  my ($asub,$doc,$opts) = @_;
  return $doc if (!$asub->enabled($opts));

  ##-- common variables
  my $label  = $asub->{label};
  my $xytags = $asub->{xyTags};

  my ($old,$new,$xlit, $moota,$mootxy);
  foreach (map {@{$_->{tokens}}} @{$doc->{body}}) {
    $old    = $_->{text};
    $new    = $_->{moot} ? $_->{moot}{word} : ($_->{dmoot} ? $_->{dmoot}{tag} : $xlit);
    $xlit   = $_->{xlit} ? $_->{xlit}{latin1Text} : $old;
    if ($_->{moot}) {
      $moota  = $_->{moot}{analyses} && @{$_->{moot}{analyses}};
      $mootxy = exists($xytags->{$_->{moot}{tag}});
    } else {
      ($moota,$mootxy) = (undef,1);
    }

    $_->{$label} =
      join(",",
	   ($_->{exlex} ? '+' : '-').'exlex',
	   ($new eq $old ? '+' : '-').'id',
	   ($new eq $xlit ? '+' : '-').'xid',
	   ($_->{msafe} ? '+' : '-').'msafe',
	   ($moota  ? '+' : '-').'moota',
	   ($mootxy ? '+' : '-').'mootxy',
	  );
  }

  ##-- return
  return $doc;
}

1; ##-- be happy

__END__

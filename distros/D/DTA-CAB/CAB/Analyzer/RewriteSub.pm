## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::RewriteSub.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: sub-analysis (LTS, Morph) of rewrite targets

##==============================================================================
## Package: Analyzer::RewriteSub
##==============================================================================
package DTA::CAB::Analyzer::RewriteSub;
use DTA::CAB::Chain;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Analyzer::Morph;
use DTA::CAB::Analyzer::LTS;
use Carp;
use strict;
our @ISA = qw(DTA::CAB::Chain);

##==============================================================================
## Methods

## $obj = CLASS_OR_OBJ->new(chain=>\@analyzers, %args)
##  + basic object structure: (see also DTA::CAB::Chain)
##    (
##     chain => [$a1, ..., $aN], ##-- sub-analysis chain (e.g. chain=>[$lts,$morph])
##    )
##  + new object structure:
##    (
##     rwLabel => $label,        ##-- label of source 'rewrite' object (default='rw')
##    )
sub new {
  my $that = shift;
  my $asub = $that->SUPER::new(
			       ##-- defaults
			       #analysisClass => 'DTA::CAB::Analyzer::Rewrite::Analysis',
			       label => 'rwsub',

			       ##-- analysis selection
			       rwLabel => 'rw',

			       ##-- user args
			       @_
			      );
  return $asub;
}

## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in %types (= %{$doc->{types}})
##  + extracts rewrite targets, builds pseudo-type hash, calls sub-chain analyzeTypes(), & expands
sub analyzeTypes {
  my ($asub,$doc,$types,$opts) = @_;
  return $doc if (!$asub->enabled($opts));

  ##-- load
  #$asub->ensureLoaded();

  ##-- get rewrite target types
  $types = $doc->types if (!$types);
  my $rwkey   = $asub->{rwLabel};
  my $rwtypes = {
		 map { ($_->{hi}=>bless({text=>$_->{hi}},'DTA::CAB::Token')) }
		 map { $_->{$rwkey} ? @{$_->{$rwkey}} : qw() }
		 values(%$types)
		};

  ##-- analyze rewrite target types
  my ($sublabel);
  foreach (@{$asub->{chain}}) {
    $sublabel = $_->{label};
    next if (defined($opts->{$sublabel}) && !$opts->{$sublabel});
    $_->{label} =~ s/^\Q$asub->{label}_\E//;  ##-- sanitize label (e.g. "rwsub_morph" --> "morph"), because it's also used as output key
    $_->analyzeTypes($doc,$rwtypes,$opts);
    $_->{label} = $sublabel;
  }

  ##-- delete rewrite target type 'text'
  delete($_->{text}) foreach (values %$rwtypes);

  ##-- expand rewrite target types
  my ($rwtyp);
  foreach (map {$_->{$rwkey} ? @{$_->{$rwkey}} : qw()} values(%$types)) {
    $rwtyp = $rwtypes->{$_->{hi}};
    @$_{keys %$rwtyp} = values %$rwtyp;
  }

  ##-- return
  return $doc;
}

## @keys = $anl->typeKeys()
##  + returns list of type-wise keys to be expanded for this analyzer by expandTypes()
##  + override returns $anl->{rwLabel}
sub typeKeys {
  return $_[0]{rwLabel};
}


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

##------------------------------------------------------------------------
## Methods: Analysis: Generic

## $bool = $ach->canAnalyze()
## $bool = $ach->canAnalyze(\%opts)
##  + returns true if analyzer can perform its function (e.g. data is loaded & non-empty)
##  + returns true if ANY analyzers in the chain do to
sub canAnalyze {
  my $ach = shift;
  @{$ach->{chain}} = grep {$_ && $_->canAnalyze} @{$ach->chain(@_)};
  foreach (@{$ach->chain(@_)}) {
    return 1 if ($_->canAnalyze);
  }
  return 1;
}



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

DTA::CAB::Analyzer::RewriteSub - sub-analysis (LTS, Morph) of rewrite targets

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Analyzer::RewriteSub;
 
 ##========================================================================
 ## Methods
 
 $obj = CLASS_OR_OBJ->new(chain=>\@analyzers, %args);
 @keys = $anl->typeKeys();
 \@analyzers = $ach->chain();
 $bool = $ach->ensureLoaded();
 $bool = $ach->canAnalyze();
 $doc = $anl->analyzeTypes($doc,\%types,\%opts);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Analyzer::RewriteSub provides a
L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> implementation
for post-processing of rewrite analyses as generated
by a L<DTA::CAB::Analyzer::Rewrite|DTA::CAB::Analyzer::Rewrite> analyzer
in a L<DTA::CAB::Chain::DTA|DTA::CAB::Chain::DTA> analysis chain.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::RewriteSub: Methods
=pod

=head2 Methods

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(chain=>\@analyzers, %args);

%$obj, %args (see also L<DTA::CAB::Chain|DTA::CAB::Chain>):

 chain => [$a1, ..., $aN], ##-- sub-analysis chain (e.g. chain=>[$lts,$morph])
 rwLabel => $label,        ##-- label of source 'rewrite' object (default='rw')


=item typeKeys

 @keys = $anl->typeKeys();

Returns list of type-wise keys to be expanded for this analyzer by expandTypes().
Override returns $anl-E<gt>{rwLabel}.

=item chain

 \@analyzers = $ach->chain();
 \@analyzers = $ach->chain(\%opts)

Get selected analyzer chain.
NEW: just return $ach-E<gt>{chain}, since analyzers may still be disabled here (argh).

=item ensureLoaded

 $bool = $ach->ensureLoaded();

Returns true if any chain member loads successfully (or if the chain is empty).

=item canAnalyze

 $bool = $ach->canAnalyze();
 $bool = $ach->canAnalyze(\%opts)

Returns true if analyzer can perform its function (e.g. data is loaded & non-empty)
Override returns true if ANY analyzers in the chain do to.

=item analyzeTypes

 $doc = $anl->analyzeTypes($doc,\%types,\%opts);

Perform type-wise analysis of all (text) types in %types (= %{$doc-E<gt>{types}}).
Override extracts rewrite targets, builds pseudo-type hash, calls sub-chain analyzeTypes(), & re-expands.

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
L<DTA::CAB::Analyzer::Rewrite(3pm)|DTA::CAB::Analyzer::Rewrite>,
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB::Chain::DTA(3pm)|DTA::CAB::Chain::DTA>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut

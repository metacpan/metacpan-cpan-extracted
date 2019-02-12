## -*- Mode: CPerl -*-
## File: DTA::CAB::Analyzer::Automaton::Gfsm::XL.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Gfsm::XL::Cascade -based transductions

package DTA::CAB::Analyzer::Automaton::Gfsm::XL;
use DTA::CAB::Analyzer::Automaton;
use Gfsm;
use Gfsm::XL;
use Encode qw(encode decode);
use IO::File;
use Carp;

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer::Automaton);

our $DEFAULT_ANALYZE_PRE = q($anl->setLookupOptions({src=>$_[0],map {($_=>$anl->{$_})} qw(max_paths max_weight max_ops)}););

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure: see DTA::CAB::Analyzer::Automaton
##  + new data / changes
##    (
##     ##-- Analysis objects
##     fst  => $cl,       ##-- a Gfsm::XL::Cascade::Lookup object (default=new)
##
##     ##-- Lookup options (obsolete: only used if you leave the default analyzePre method)
##     max_paths  => $max_paths,           ##-- sets $cl->max_paths()
##     max_ops    => $max_ops_or_array,    ##-- sets $cl->max_ops()     ; default=16384
##     max_weight => $max_weight_or_array, ##-- sets $cl->max_weight()
##    )
## + $max_ops, $max_weight may also be specified as an ARRAY-ref [$a,$b]
##   to compute the actual parameter on-the-fly as the linear function:
##      $max_thingy = $a * length($input_word) + $b

sub new {
  my $that = shift;
  my $aut = $that->SUPER::new(
			      ##-- analysis objects
			      fst=>undef, #Gfsm::XL::Cascade::Lookup->new(undef),

			      ##-- lookup options
			      #max_weight => 3e38,
			      #max_paths  => 1,
			      max_ops    => 16384,

			      analyzePre => $DEFAULT_ANALYZE_PRE,

			      ##-- user args
			      @_
			     );
  $aut->setLookupOptions($aut);
  return $aut;
}


## $aut = $aut->clear()
sub clear {
  my $aut = shift;

  $aut->{fst}->_cascade_set(undef) if ($aut->{fst});

  ##-- inherited
  $aut->SUPER::clear();
}

## $aut = $aut->resetProfilingData()
## - inherited

##--------------------------------------------------------------
## Methods: Lookup Options

## $aut = $aut->setLookupOptions(\%opts)
## + obsolete; remains for compatibility with pre-v1.31 code
## + \%opts keys:
##   max_paths  => $n_paths,
##   max_ops    => $n_ops_or_array,
##   max_weight => $w_or_array,
sub setLookupOptions {
  my ($aut,$opts) = @_;
  my $cl = $aut->{fst};
  return if (!defined($cl));

  ##-- opts: max_weight
  if (UNIVERSAL::isa($opts->{max_weight},'ARRAY')) {
    $cl->max_weight($opts->{max_weight}[0] * length(($opts->{src}||'1')) + $opts->{max_weight}[1]);
  } elsif (defined($opts->{max_weight})) {
    $cl->max_weight($opts->{max_weight});
  }

  ##-- opts: max_ops
  if (UNIVERSAL::isa($opts->{max_ops},'ARRAY')) {
    $cl->max_ops($opts->{max_ops}[0] * length(($opts->{src}||'1')) + $opts->{max_ops}[1]);
  } elsif (defined($opts->{max_ops})) {
    $cl->max_ops($opts->{max_ops});
  }

  ##-- opts: max_paths
  $cl->max_paths ($opts->{max_paths})  if (defined($opts->{max_paths}));

  return $aut;
}

##==============================================================================
## Methods: Generic
##==============================================================================

## $class = $aut->fstClass()
##  + default FST class for loadFst() method
sub fstClass { return 'Gfsm::XL::Cascade'; }

## $class = $aut->labClass()
##  + default labels class for loadLabels() method
sub labClass { return 'Gfsm::Alphabet'; }

## $bool = $aut->fstOk()
##  + should return false iff fst is undefined or "empty"
sub fstOk { return defined($_[0]{fst}) && defined($_[0]{fst}->cascade) && $_[0]{fst}->cascade->depth>0; }

## $bool = $aut->labOk()
##  + should return false iff label-set is undefined or "empty"
#(inherited)

## $bool = $aut->dictOk()
##  + should return false iff dict is undefined or "empty"
##(inherited)


##==============================================================================
## Methods: I/O
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $aut = $aut->load(fst=>$fstFile, lab=>$labFile, dict=>$dictFile)
## + inherited

##--------------------------------------------------------------
## Methods: I/O: Input: Dictionary

## $aut = $aut->loadDict($dictfile)
## + inherited


##--------------------------------------------------------------
## Methods: I/O: Input: Transducer

## $aut = $aut->loadCascade($cscfile)
## $aut = $aut->loadFst    ($cscfile)
*loadFst = \&loadCascade;
sub loadCascade {
  my ($aut,$cscfile) = @_;
  $aut->info("loading cascade file '$cscfile'");
  my $csc = Gfsm::XL::Cascade->new();
  if (!$csc->load($cscfile)) {
    $aut->logconfess("loadCascade(): load failed for '$cscfile': $!");
    return undef;
  }
  $aut->{fst} = Gfsm::XL::Cascade::Lookup->new($csc);
  $aut->setLookupOptions($aut);
  #$aut->{result} = Gfsm::Automaton->new($csc->semiring_type);  ##-- reset result automaton
  delete($aut->{_analyze});
  #print STDERR sprintf("loadCascade(): csc=0x%0.8x, cl=0x%0.8x\n", $$csc, ${$aut->{fst}}); ##-- DEBUG
  return $aut;
}

## $result = $aut->resultFst()
##  + returns empty result FST
sub resultFst {
  return Gfsm::Automaton->new($_[0]{fst}->cascade->semiring_type);
}


##--------------------------------------------------------------
## Methods: I/O: Input: Labels

## $aut = $aut->loadLabels($labfile)
## + inherited

## $aut = $aut->parseLabels()
## + inherited

##==============================================================================
## Methods: Analysis
##  + inherited from DTA::CAB::Analyzer::Automaton
##==============================================================================


1; ##-- be happy
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl & edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::Automaton::Gfsm::XL - Gfsm::XL::Cascade-based transductions

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Analyzer::Automaton::Gfsm::XL;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = DTA::CAB::Analyzer::Automaton::Gfsm::XL->new(%args);
 $aut = $aut->clear();
 $aut = $aut->setLookupOptions(\%opts);
 
 ##========================================================================
 ## Methods: Generic
 
 $class = $aut->fstClass();
 $class = $aut->labClass();
 $bool = $aut->fstOk();
 
 ##========================================================================
 ## Methods: I/O
 
 $aut = $aut->loadCascade($cscfile);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Automaton::Gfsm::XL: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Analyzer::Automaton::Gfsm::XL
inherits from
L<DTA::CAB::Analyzer::Automaton|DTA::CAB::Analyzer::Automaton>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Automaton::Gfsm::XL: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $aut = CLASS_OR_OBJ->new(%args);

Constructor override: see L<DTA::CAB::Analyzer::Automaton::new()|DTA::CAB::Analyzer::Automaton/item_new>.

new and/or changed %args, %$aut:

 ##-- Analysis objects
 fst  => $cl,               ##-- a Gfsm::XL::Cascade::Lookup object (default=new)
 ##
 ##-- Lookup options (new)
 max_paths  => $max_paths,           ##-- sets $cl->max_paths()
 max_ops    => $max_ops,             ##-- sets $cl->max_ops()
 max_weight => $max_weight_or_array, ##-- sets $cl->max_weight()
                                     ##   + may also be specified as an ARRAY-ref [$a,$b]
                                     ##     to compute max-weight parameter on-the-fly as
                                     ##     the linear function:
                                     ##       $max_weight = $a * length($input_word) + $b


=item clear

 $aut = $aut->clear();

Override: clear automaton.

=item setLookupOptions

 $aut = $aut->setLookupOptions(\%opts);

Sets lookup-local options %opts:

 src        => $input_text,
 max_weight => $w,
 max_paths  => $n_paths,
 max_ops    => $n_ops,

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Automaton::Gfsm::XL: Methods: Generic
=pod

=head2 Methods: Generic

=over 4

=item fstClass

 $class = $aut->fstClass();

Override: default FST class for L</loadFst>() method

=item labClass

 $class = $aut->labClass();

Override: default labels class for L</loadLabels>() method

=item fstOk

 $bool = $aut->fstOk();

Override: should return false iff fst is undefined or "empty"

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Automaton::Gfsm::XL: Methods: I/O
=pod

=head2 Methods: I/O

=over 4

=item loadCascade

 $aut = $aut->loadCascade($cscfile);
 $aut = $aut->loadFst    ($cscfile)

Alias / override.

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

Copyright (C) 2009-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

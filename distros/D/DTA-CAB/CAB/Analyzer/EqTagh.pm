## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::EqTagh.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: lemma-equivalence class expansion: TAGH via FST

##==============================================================================
## Package: Analyzer::EqTagh
##==============================================================================
package DTA::CAB::Analyzer::EqTagh;
use strict;

#use DTA::CAB::Analyzer::EqLemma::BDB;
#our @ISA = qw(DTA::CAB::Analyzer::EqLemma::BDB);
##
#use DTA::CAB::Analyzer::EqLemma::CDB;
#our @ISA = qw(DTA::CAB::Analyzer::EqLemma::CDB);
##
use DTA::CAB::Analyzer::EqLemma::FST;
our @ISA = qw(DTA::CAB::Analyzer::EqLemma::FST);

sub new {
  my $that = shift;
  return $that->SUPER::new(label=>'eqtagh',@_);
}

1; ##-- be happy

__END__

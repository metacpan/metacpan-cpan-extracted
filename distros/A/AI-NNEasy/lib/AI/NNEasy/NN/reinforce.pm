#############################################################################
## This file was generated automatically by Class::HPLOO/0.21
##
## Original file:    ./lib/AI/NNEasy/NN/reinforce.hploo
## Generation date:  2005-01-16 19:52:04
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        reinforce.pm
## Purpose:     AI::NNEasy::NN::reinforce
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-14
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package AI::NNEasy::NN::reinforce ;

  use strict qw(vars) ; no warnings ;

  use vars qw(%CLASS_HPLOO @ISA) ;

  @ISA = qw(Class::HPLOO::Base UNIVERSAL) ;

  my $CLASS = 'AI::NNEasy::NN::reinforce' ; sub __CLASS__ { 'AI::NNEasy::NN::reinforce' } ;

  use Class::HPLOO::Base ;
  
  sub learn { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    foreach my $layer ( reverse @{$this->{'layers'}}[ 1 .. $#{$this->{'layers'}} ] ) {
      foreach my $node ( @{$layer->{nodes}} ) {
        foreach my $westNode ( @{$node->{connectedNodesWest}->{nodes}} ) {
          my $dW = $westNode->{activation} * $node->{connectedNodesWest}->{weights}->{ $westNode->{nodeid} } * $this->{learning_rate} ;
          $node->{connectedNodesWest}->{weights}->{ $westNode->{nodeid} } += $dW ;
        }
      }
    }
  }


}


1;



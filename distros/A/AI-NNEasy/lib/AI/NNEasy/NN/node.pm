#############################################################################
## This file was generated automatically by Class::HPLOO/0.21
##
## Original file:    ./lib/AI/NNEasy/NN/node.hploo
## Generation date:  2005-01-16 19:52:04
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        node.pm
## Purpose:     AI::NNEasy::NN::node
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-14
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package AI::NNEasy::NN::node ;

  use strict qw(vars) ; no warnings ;

  use vars qw(%CLASS_HPLOO @ISA) ;

  @ISA = qw(Class::HPLOO::Base UNIVERSAL) ;

  my $CLASS = 'AI::NNEasy::NN::node' ; sub __CLASS__ { 'AI::NNEasy::NN::node' } ;

  use Class::HPLOO::Base ;

  my $NODEID ;

  sub node { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $params = shift(@_) ;
    
    $this->{nodeid} = ++$NODEID ;
    
    $this->{activation} = $$params{random_activation} ? rand($$params{random}) : 0 ;

    $this->{random_weights} = $$params{random_weights} ;
    $this->{decay} = $$params{decay} ;
    $this->{adjust_error} = $$params{adjust_error} ;
    $this->{persistent_activation} = $$params{persistent_activation} ;
    $this->{threshold} = $$params{threshold} ;
    $this->{activation_function} = $$params{activation_function} ;
    $this->{active} = 1 ;
    
    $this->{error} = 0 ;

    return $this ;
  }


}


1;



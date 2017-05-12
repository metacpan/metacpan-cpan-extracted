#############################################################################
## This file was generated automatically by Class::HPLOO/0.21
##
## Original file:    ./lib/AI/NNEasy/NN/layer.hploo
## Generation date:  2005-01-16 19:52:04
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        layer.pm
## Purpose:     AI::NNEasy::NN::layer
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-14
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package AI::NNEasy::NN::layer ;

  use strict qw(vars) ; no warnings ;

  use vars qw(%CLASS_HPLOO @ISA) ;

  @ISA = qw(Class::HPLOO::Base UNIVERSAL) ;

  my $CLASS = 'AI::NNEasy::NN::layer' ; sub __CLASS__ { 'AI::NNEasy::NN::layer' } ;

  use Class::HPLOO::Base ;

  use AI::NNEasy::NN::node ;

  sub layer { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $params = shift(@_) ;
    
    $this->{nodes} = [] ;
    for (1 .. $$params{nodes}) { push( @{$this->{nodes}} , AI::NNEasy::NN::node->new($params) ) ;}
    return $this ;
  }
  
  sub layer_output { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $params = shift(@_) ;
    
    my @outputs ;
    foreach my $node ( @{$this->{nodes}} ) {
      push(@outputs , $$node{activation}) ;
    }

    return \@outputs;    
  }


}


1;



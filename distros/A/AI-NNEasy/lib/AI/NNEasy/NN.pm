#############################################################################
## This file was generated automatically by Class::HPLOO/0.21
##
## Original file:    ./lib/AI/NNEasy/NN.hploo
## Generation date:  2005-01-16 19:51:58
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        NN.pm
## Purpose:     AI::NNEasy::NN
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-14
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
##
## This class and classes inside AI::NNEasy::NN::* were 1st based in the
## module AI::NNFlex from Charles Colbourn <charlesc at nnflex.g0n.net>.
##
#############################################################################


{ package AI::NNEasy::NN ;

  use strict qw(vars) ; no warnings ;

  use vars qw(%CLASS_HPLOO @ISA $VERSION) ;

  $VERSION = '0.06' ;

  @ISA = qw(Class::HPLOO::Base UNIVERSAL) ;

  my $CLASS = 'AI::NNEasy::NN' ; sub __CLASS__ { 'AI::NNEasy::NN' } ;

  use Class::HPLOO::Base ;

  use AI::NNEasy::NN::layer ;
  use AI::NNEasy::NN::feedforward ;
  use AI::NNEasy::NN::backprop ;

  use vars qw($AUTOLOAD) ;
  
  sub NN { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $params = shift(@_) ;
    my $netParams = shift(@_) ;
    
    my @layers ;

    foreach my $i (keys %$netParams) {
      $this->{$i} = $$netParams{$i};
    }

    $this->{networktype} ||= 'feedforward' ;
    $this->{learning_algorithm} ||= 'backprop' ;
    
    $this->{learning_algorithm_class} = "AI::NNEasy::NN::" . $this->{learning_algorithm} ;
        
    my $nntype_class = "AI::NNEasy::NN::" . $this->{networktype} . '_' . $this->{learning_algorithm} ;
    
    bless($this , $nntype_class) ;


    foreach my $i ( @$params ) {
      next if !$$i{nodes} ;
      my %layer = %{$i} ;
      push(@layers , AI::NNEasy::NN::layer->new(\%layer)) ;
    }

    $this->{layers} = \@layers ;

    if ( $this->{bias} ) {
      $this->{biasNode} = AI::NNEasy::NN::node->new( {activation_function => 'linear'} ) ;
      $this->{biasNode}->{activation} = 1;
    }

    $this->init ;
    
    return $this ;
  }
  
  sub init { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my @layers = @{$this->{layers}} ;

    my $currentLayer ;

    foreach my $layer (@layers) {
      # Foreach node we need to make connections east and west
      foreach my $node ( @{$layer->{nodes}} ) {
        # only initialise to the west if layer > 0
        if ($currentLayer > 0 ) {
          foreach my $westNodes ( @{ $this->{layers}->[$currentLayer -1]->{nodes} } ) {
            foreach my $connectionFromWest ( @{ $westNodes->{connectedNodesEast}->{nodes} } ) {
              if ($connectionFromWest eq $node) {
                my $weight = $this->{random_weights} ? rand(2)-1 : 0 ;
                push(@{$node->{connectedNodesWest}->{nodes}} , $westNodes) ;
                $node->{connectedNodesWest}->{weights}{ $westNodes->{nodeid} } = $weight ;
              }
            }
          }
        }

        # Now initialise connections to the east (if not last layer)
        if ($currentLayer < (@layers - 1)) {
          foreach my $eastNodes ( @{$this->{layers}->[$currentLayer+1]->{nodes}} ) {
            if (!$this->{random_connections} || $this->{random_connections} > rand(1)) {
              my $weight = $this->{random_weights} ? rand(1) : 0 ;
              push( @{$node->{connectedNodesEast}->{nodes}} , $eastNodes) ;
              $node->{connectedNodesEast}->{weights}{ $eastNodes->{nodeid} } = $weight ;
            }
          }
        }
      }
      ++$currentLayer ;
    }

    # add bias node to westerly connections
    if ( $this->{bias} ) {
      foreach my $layer (@{$this->{layers}}) {
        foreach my $node (@{$layer->{nodes}}) {
          push @{$node->{connectedNodesWest}->{nodes}},$this->{biasNode};
          my $weight = $this->{random_weights} ? rand(1) : 0 ;
          $node->{connectedNodesWest}->{weights}{ $this->{biasNode}->{nodeid} } = $weight ;
        }
      }
    }
  }
  
  sub learn { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    &{$this->{learning_algorithm_class} . '::learn'}($this , @_) ;
  }
  
  sub output { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $params = shift(@_) ;
    
    my $outputLayer = defined $$params{layer} ? $this->{layers}[$$params{layer}] : $this->{layers}[-1] ;
    return AI::NNEasy::NN::layer::layer_output($outputLayer) ;
  }
  
  sub linear { my $this = ref($_[0]) ? shift : undef ;my $CLASS = ref($this) || __PACKAGE__ ;my $value = shift(@_) ; return $value ;}
  
  *tanh = \&tanh_c ;
  
  
  
  sub tanh_pl { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $value = shift(@_) ;
    
    if    ($value > 20)  { return 1 ;}
    elsif ($value < -20) { return -1 ;}
    else {
      my $x = exp($value) ;
      my $y = exp(-$value) ;
      return ($x-$y)/($x+$y) ;
    }
  }
  
  *sigmoid = \&sigmoid_c ;
  
  sub sigmoid_pl { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $value = shift(@_) ;
    
    return (1+exp(-$value))**-1 ;
  }
  
  
  
  sub AUTOLOAD { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my ($name) = ( $AUTOLOAD =~ /(\w+)$/ ) ;
    my $sub = $this->{learning_algorithm_class} . '::' . $name ;
    return &$sub($this,@_) if defined &$sub ;
    my @call = caller ;
    die("Can't find $AUTOLOAD or $sub at @call\n") ;
  }

my $INLINE_INSTALL ; BEGIN { use Config ; my @installs = ($Config{installarchlib} , $Config{installprivlib} , $Config{installsitelib}) ; foreach my $i ( @installs ) { $i =~ s/[\\\/]/\//gs ;} $INLINE_INSTALL = 1 if ( __FILE__ =~ /\.pm$/ && ( join(" ",@INC) =~ /\Wblib\W/s || __FILE__ =~ /^(?:\Q$installs[0]\E|\Q$installs[1]\E|\Q$installs[2]\E)/ ) ) ; }

use Inline C => <<'__INLINE_C_SRC__' , ( $INLINE_INSTALL ? (NAME => 'AI::NNEasy::NN' , VERSION => '0.06') : () ) ;

double tanh_c ( SV* self , double value ) {
    if      ( value > 20 ) { return 1 ;}
    else if ( value < -20 ) { return -1 ;}
    else {
      double x = Perl_exp(value) ;
      double y = Perl_exp(-value) ;
      double ret = (x-y)/(x+y) ;
      return ret ;
    }
}

double sigmoid_c ( SV* self , double value ) {
    double ret = 1 + Perl_exp( -value ) ;
    ret = Perl_pow(ret , -1) ;
    return ret ;
}

__INLINE_C_SRC__


}


{ package AI::NNEasy::NN::feedforward_backprop ;

  use strict qw(vars) ; no warnings ;

  use vars qw(%CLASS_HPLOO @ISA) ;

  push(@ISA , qw(AI::NNEasy::NN::backprop AI::NNEasy::NN::feedforward AI::NNEasy::NN Class::HPLOO::Base UNIVERSAL)) ;

  my $CLASS = 'AI::NNEasy::NN::feedforward_backprop' ; sub __CLASS__ { 'AI::NNEasy::NN::feedforward_backprop' } ;

  use Class::HPLOO::Base ;
  ## Just define a class with this @ISA.

}




1;



#############################################################################
## This file was generated automatically by Class::HPLOO/0.21
##
## Original file:    ./lib/AI/NNEasy/NN/feedforward.hploo
## Generation date:  2005-01-16 19:52:04
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        feedforward.pm
## Purpose:     AI::NNEasy::NN::feedforward
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-14
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package AI::NNEasy::NN::feedforward ;


use strict qw(vars) ; no warnings ;


use vars qw(%CLASS_HPLOO @ISA $VERSION) ;


$VERSION = '0.06' ;


push(@ISA , qw(AI::NNEasy::NN Class::HPLOO::Base UNIVERSAL)) ;


my $CLASS = 'AI::NNEasy::NN::feedforward' ; sub __CLASS__ { 'AI::NNEasy::NN::feedforward' } ;


use Class::HPLOO::Base ;



  *run = \&run_c ;

  sub run_pl { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $inputPatternRef = shift(@_) ;
    
    # Now apply the activation
    my $counter = 0 ;
    foreach my $node ( @{ $this->{layers}->[0]->{nodes} } ) {
      if ( $node->{active} ) {
        if ( $node->{persistent_activation} ) {
          $node->{activation} += $$inputPatternRef[$counter] ;
        }
        else {
          $node->{activation} = $$inputPatternRef[$counter] ;
        }
      }
      ++$counter ;
    }
    

    # Now flow activation through the network starting with the second layer
    
    my ( $function ) ;
    
    foreach my $layer ( @{$this->{layers}}[1 .. $#{$this->{layers}}] ) {
      foreach my $node ( @{$layer->{nodes}} ) {
        $node->{activation} = 0 if !$node->{persistent_activation} ;
        
        $function = $node->{activation_function} ;

        foreach my $connectedNode ( @{$node->{connectedNodesWest}->{nodes}} ) {
          $node->{activation} -= $node->{decay} if $node->{decay} ;
          
          $node->{activation} += $this->$function(
           $node->{connectedNodesWest}->{weights}{ $connectedNode->{nodeid} }
             *
           $connectedNode->{activation}
          ) ;
        }

        if ( $node->{active} ) {
          $node->{activation} = $this->$function( $node->{activation} ) ;
        }
      }
    }
  }
  
  

my $INLINE_INSTALL ; BEGIN { use Config ; my @installs = ($Config{installarchlib} , $Config{installprivlib} , $Config{installsitelib}) ; foreach my $i ( @installs ) { $i =~ s/[\\\/]/\//gs ;} $INLINE_INSTALL = 1 if ( __FILE__ =~ /\.pm$/ && ( join(" ",@INC) =~ /\Wblib\W/s || __FILE__ =~ /^(?:\Q$installs[0]\E|\Q$installs[1]\E|\Q$installs[2]\E)/ ) ) ; }

use Inline C => <<'__INLINE_C_SRC__' , ( $INLINE_INSTALL ? (NAME => 'AI::NNEasy::NN::feedforward' , VERSION => '0.06') : () ) ;


#define OBJ_HV(self)		(HV*) SvRV( self )
#define OBJ_AV(self)		(AV*) SvRV( self )

#define FETCH_ATTR(hv,k)	*hv_fetch(hv, k , strlen(k) , 0)
#define FETCH_ATTR_PV(hv,k)	SvPV( FETCH_ATTR(hv,k) , len)
#define FETCH_ATTR_NV(hv,k)	SvNV( FETCH_ATTR(hv,k) )
#define FETCH_ATTR_IV(hv,k)	SvIV( FETCH_ATTR(hv,k) )  
#define FETCH_ATTR_HV(hv,k)	(HV*) FETCH_ATTR(hv,k)
#define FETCH_ATTR_AV(hv,k)	(AV*) FETCH_ATTR(hv,k)
#define FETCH_ATTR_HV_REF(hv,k)	(HV*) SvRV( FETCH_ATTR(hv,k) )
#define FETCH_ATTR_AV_REF(hv,k)	(AV*) SvRV( FETCH_ATTR(hv,k) )

#define FETCH_ELEM(av,i)		*av_fetch(av,i,0)
#define FETCH_ELEM_HV_REF(av,i)	(HV*) SvRV( FETCH_ELEM(av,i) )
#define FETCH_ELEM_AV_REF(av,i)	(AV*) SvRV( FETCH_ELEM(av,i) )

void run_c( SV* self , SV* inputPatternRef) {
    STRLEN len;
    int i , j , k ;
    AV* inputPattern = (AV*) SvRV(inputPatternRef) ;
    AV* layers ;
    HV* self_hv = OBJ_HV( self );
    char* function ;
        
    AV* nodes = FETCH_ATTR_AV_REF( FETCH_ELEM_HV_REF( FETCH_ATTR_AV_REF(self_hv , "layers") , 0) , "nodes") ;
    for (i = 0 ; i <= av_len(nodes) ; ++i) {
      HV* node = OBJ_HV( *av_fetch(nodes, i ,0) ) ;
      
      if ( SvTRUE( FETCH_ATTR(node , "active") ) ) {
        SV* activation = FETCH_ATTR(node , "activation") ;
        SV* input = *av_fetch(inputPattern, i ,0) ;
        
        if ( SvTRUE( FETCH_ATTR(node , "persistent_activation") ) ) {
          sv_setnv(activation , (SvNV(activation) + SvNV(input)) ) ;
        }
        else {
          sv_setnv(activation , SvNV(input)) ;
        }
      }
    }
    
    layers = FETCH_ATTR_AV_REF(self_hv , "layers") ;
    for (i = 1 ; i <= av_len(layers) ; ++i) {
      SV* layer = *av_fetch(layers, i ,0) ;
      
      AV* nodes = FETCH_ATTR_AV_REF(OBJ_HV(layer) , "nodes") ;
      for (j = 0 ; j <= av_len(nodes) ; ++j) {
        HV* node = OBJ_HV( *av_fetch(nodes, j ,0) ) ;
        SV* activation = FETCH_ATTR(node , "activation") ;
        AV* westNodes ;
        double funct_in ;
        
        if ( !SvTRUE( FETCH_ATTR(node , "persistent_activation") ) ) sv_setiv(activation , 0) ;
        
        function = FETCH_ATTR_PV(node , "activation_function") ;
        
        westNodes = FETCH_ATTR_AV_REF( FETCH_ATTR_HV_REF(node , "connectedNodesWest") , "nodes") ;
        for (k = 0 ; k <= av_len(westNodes) ; ++k) {
          HV* connectedNode = OBJ_HV( *av_fetch(westNodes, k ,0) ) ;
          
          if ( SvTRUE( FETCH_ATTR(node , "decay") ) ) {
            double val = SvNV(activation) - FETCH_ATTR_NV(node , "decay") ;
            sv_setiv(activation , val) ;
          }
          
          funct_in = FETCH_ATTR_NV( FETCH_ATTR_HV_REF( FETCH_ATTR_HV_REF(node , "connectedNodesWest") , "weights") , FETCH_ATTR_PV(connectedNode , "nodeid") ) * FETCH_ATTR_NV(connectedNode , "activation") ;
          
          if ( strcmp(function , "tanh") == 0 ) {
            if      ( funct_in > 20 ) { funct_in = 1 ;}
            else if ( funct_in < -20 ) { funct_in = -1 ;}
            else {
              double x = Perl_exp(funct_in) ;
              double y = Perl_exp(-funct_in) ;
              funct_in = (x-y)/(x+y) ;
            }
            sv_setnv(activation , ( SvNV(activation) + funct_in) ) ;
          }
          else if ( strcmp(function , "linear") == 0 ) {
            sv_setnv(activation , ( SvNV(activation) + funct_in) ) ;
          }
        }
        
        if ( SvTRUE( FETCH_ATTR(node , "active") ) ) {
          funct_in = FETCH_ATTR_NV(node , "activation") ;
          
          if ( strcmp(function , "tanh") == 0 ) {
            if      ( funct_in > 20 ) { funct_in = 1 ;}
            else if ( funct_in < -20 ) { funct_in = -1 ;}
            else {
              double x = Perl_exp(funct_in) ;
              double y = Perl_exp(-funct_in) ;
              funct_in = (x-y)/(x+y) ;
            }
            sv_setnv(activation , funct_in) ;
          }
          else if ( strcmp(function , "linear") == 0 ) {
            sv_setnv(activation , funct_in) ;
          }
        }

      }

    }
    
}

__INLINE_C_SRC__


}


1;



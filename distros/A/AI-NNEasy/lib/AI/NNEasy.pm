#############################################################################
## This file was generated automatically by Class::HPLOO/0.21
##
## Original file:    ./lib/AI/NNEasy.hploo
## Generation date:  2005-01-16 22:07:24
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        NNEasy.pm
## Purpose:     AI::NNEasy
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-14
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package AI::NNEasy ;

  
use strict qw(vars) ; no warnings ;

  
use vars qw(%CLASS_HPLOO @ISA $VERSION) ;

  
$VERSION = '0.06' ;

  
@ISA = qw(Class::HPLOO::Base UNIVERSAL) ;

  
my $CLASS = 'AI::NNEasy' ; sub __CLASS__ { 'AI::NNEasy' } ;

  
use Class::HPLOO::Base ;

  use AI::NNEasy::NN ;
  use Storable qw(freeze thaw) ;
  use Data::Dumper ;
  


  sub NNEasy { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $file = shift(@_) ;
    my @out_types = ref($_[0]) eq 'ARRAY' ? @{ shift(@_) } : ( ref($_[0]) eq 'HASH' ? %{ shift(@_) } : shift(@_) ) ;
    my $error_ok = shift(@_) ;
    my $in = shift(@_) ;
    my $out = shift(@_) ;
    my @layers = ref($_[0]) eq 'ARRAY' ? @{ shift(@_) } : ( ref($_[0]) eq 'HASH' ? %{ shift(@_) } : shift(@_) ) ;
    my $conf = shift(@_) ;
    
    $file ||= 'nneasy.nne' ;
  
    if ( $this->load($file) ) {
      return $this ;
    }
  
    my $in_sz  = ref $in  ? $in->{nodes}  : $in ;
    my $out_sz = ref $out ? $out->{nodes} : $out ;
  
    @layers = ($in_sz+$out_sz) if !@layers ;
    
    foreach my $layers_i ( @layers ) {
      $layers_i = $in_sz+$out_sz if $layers_i <= 0 ;
    }
    
    $conf ||= {} ;
    
    my $decay = $$conf{decay} || 0 ; 
    
    my $nn_in  = $this->_layer_conf( { decay=>$decay } , $in ) ;
    my $nn_out  = $this->_layer_conf( { decay=>$decay , activation_function=>'linear' } , $out ) ;
    
    foreach my $layers_i ( @layers ) {
      $layers_i = $this->_layer_conf( { decay=>$decay } , $layers_i ) ;
    }
    
    my $nn_conf = {random_connections=>0 , networktype=>'feedforward' , random_weights=>1 , learning_algorithm=>'backprop' , learning_rate=>0.1 , bias=>1} ;
    foreach my $Key ( keys %$nn_conf ) { $$nn_conf{$Key} = $$conf{$Key} if exists $$conf{$Key} ;}
    
    $this->{NN_ARGS} = [[ $nn_in , @layers , $nn_out ] , $nn_conf] ;

    $this->{NN} = AI::NNEasy::NN->new( @{$this->{NN_ARGS}} ) ;
    
    $this->{FILE} = $file ;
    
    @out_types = (0,1) if !@out_types ;
    
    @out_types = sort {$a <=> $b} @out_types ;
    
    $this->{OUT_TYPES} = \@out_types ;
    
    if ( $error_ok <= 0 ) {
      my ($min_dif , $last) ;
      my $i = -1 ;
      foreach my $out_types_i ( @out_types ) {
        ++$i ;
        if ($i > 0) {
          my $dif = $out_types_i - $last ;
          $min_dif = $dif if !defined $min_dif || $dif < $min_dif ;
        }
        $last = $out_types_i ;
      }
      $error_ok = $min_dif / 2 ;
      $error_ok -= $error_ok*0.1 ;
    }
    
    $this->{ERROR_OK} = $error_ok ;
    
    return $this ;
  }
  
  sub _layer_conf { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $def = shift(@_) ;
    my $conf = shift(@_) ;
    
    $def ||= {} ;
    $conf = { nodes=>$conf } if !ref($conf) ;
    
    foreach my $Key ( keys %$def ) { $$conf{$Key} = $$def{$Key} if !exists $$conf{$Key} ;}
  
    my $layer_conf  = {nodes=>1  , persistent_activation=>0 , decay=>0 , random_activation=>0 , threshold=>0 , activation_function=>'tanh' , random_weights=>1} ;
    foreach my $Key ( keys %$layer_conf ) { $$layer_conf{$Key} = $$conf{$Key} if exists $$conf{$Key} ;}

    return $layer_conf ;
  }
  
  sub reset_nn { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    $this->{NN} = AI::NNEasy::NN->new( @{ $this->{NN_ARGS} } ) ;
  }
  
  sub load { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $file = shift(@_) ;
    
    $file ||= $this->{FILE} ;
    if ( -s $file ) {
      open (my $fh, $file) ;
      my $dump = join '' , <$fh> ;
      close ($fh) ;
      
      my $restored = thaw($dump) ;
      
      if ($restored) {
        my $fl = $this->{FILE} ;
        %$this = %$restored ;
        $this->{FILE} = $fl if $fl ;
        return 1 ;
      }
    }
    return ;
  }
  
  sub save { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $file = shift(@_) ;
    
    $file ||= $this->{FILE} ;
        
    my $dump = freeze( {%$this} ) ;
    open (my $fh,">$this->{FILE}") ;
    print $fh $dump ;
    close ($fh) ;
  }
  
  sub learn { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $in = shift(@_) ;
    my $out = shift(@_) ;
    my $n = shift(@_) ;
    
    $n ||= 100 ;
    
    my $err ;
    for (1..100) {
      $this->{NN}->run($in) ;
      $err = $this->{NN}->learn($out) ;
    }
    
    $err *= -1 if $err < 0 ;
    return $err ;
  }
  
  *_learn_set_get_output_error = \&_learn_set_get_output_error_c ;
  
  sub _learn_set_get_output_error_pl { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $set = shift(@_) ;
    my $error_ok = shift(@_) ;
    my $ins_ok = shift(@_) ;
    my $verbose = shift(@_) ;
    
    for (my $i = 0 ; $i < @$set ; $i+=2) {
      $this->{NN}->run($$set[$i]) ;
      $this->{NN}->learn($$set[$i+1]) ;
    }

    my ($err,$learn_ok,$print) ;
    for (my $i = 0 ; $i < @$set ; $i+=2) {
      $this->{NN}->run($$set[$i]) ;
      my $er = $this->{NN}->RMSErr($$set[$i+1]) ;
      $er *= -1 if $er < 0 ;
      ++$learn_ok if $er < $error_ok ;
      $err += $er ;
      $print .= join(' ',@{$$set[$i]}) ." => ". join(' ',@{$$set[$i+1]}) ." > $er\n" if $verbose ;
    }
    
    $err /= $ins_ok ;
    
    return ( $err , $learn_ok , $print ) ;
  }
  
  
  
  
    
  sub learn_set { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my @set = ref($_[0]) eq 'ARRAY' ? @{ shift(@_) } : ( ref($_[0]) eq 'HASH' ? %{ shift(@_) } : shift(@_) ) ;
    my $ins_ok = shift(@_) ;
    my $limit = shift(@_) ;
    my $verbose = shift(@_) ;
    
    my $ins_sz = @set / 2 ;

    $ins_ok ||= $ins_sz ;
    
    my $err_static_limit = 15 ;
    my $err_static_limit_positive ;

    if ( ref($limit) eq 'ARRAY' ) {
      ($limit,$err_static_limit,$err_static_limit_positive) = @$limit ;
    }
    
    $limit ||= 30000 ;
    $err_static_limit_positive ||= $err_static_limit/2 ;
  
    my $error_ok = $this->{ERROR_OK} ;
    
    my $check_diff_count = 1000 ;
    
    my ($learn_ok,$counter,$err,$err_last,$err_count,$err_static, $reset_count1 , $reset_count2 ,$print) ;
    
    $err_static = 0 ;
    
    while ( ($learn_ok < $ins_ok) && ($counter < $limit) ) {
      ($err , $learn_ok , $print) = $this->_learn_set_get_output_error(\@set , $error_ok , $ins_ok , $verbose) ;
      
      ++$counter ;
      
      if ( !($counter % 100) || $learn_ok == $ins_ok ) {
        my $err_diff = $err_last - $err ;
        $err_diff *= -1 if $err_diff < 0 ;
        
        $err_count += $err_diff ;
        
        ++$err_static if $err_diff <= 0.00001 || $err > 1 ;
        
        print "err_static = $err_static\n" if $verbose && $err_static ;

        $err_last = $err ;
        
        my $reseted ;
        if ( $err_static >= $err_static_limit || ($err > 1 && $err_static >= $err_static_limit_positive) ) {
          $err_static = 0 ;
          $counter -= 2000 ;
          $reseted = 1 ;
          ++$reset_count1 ;
          
          if ( ( $reset_count1 + $reset_count2 ) > 2 ) {
            $reset_count1 = $reset_count2 = 0 ;
            print "** Reseting NN...\n" if $verbose ;
            $this->reset_nn ;
          }
          else {
            print "** Reseting weights due NULL diff...\n" if $verbose ;
            $this->{NN}->init ;
          }
        }
        
        if ( !($counter % $check_diff_count) ) {
          $err_count /= ($check_diff_count/100) ;
          
          print "ERR COUNT> $err_count\n" if $verbose ;
          
          if ( !$reseted && $err_count < 0.001 ) {
            $err_static = 0 ;
            $counter -= 1000 ;
            ++$reset_count2 ;
            
            if ( ($reset_count1 + $reset_count2) > 2 ) {
              $reset_count1 = $reset_count2 = 0 ;
              print "** Reseting NN...\n" if $verbose ;
              $this->reset_nn ;
            }
            else {
              print "** Reseting weights due LOW diff...\n" if $verbose ;
              $this->{NN}->init ;
            }
          }

          $err_count = 0 ;
        }
        
        if ( $verbose ) {
          print "\nepoch $counter : error_ok = $error_ok : error = $err : err_diff = $err_diff : err_static = $err_static : ok = $learn_ok\n" ;
          print $print ;
        }
      }

      print "epoch $counter : error = $err : ok = $learn_ok\n" if $verbose > 1 ;
      
    }
    
  }
  
  sub get_set_error { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my @set = ref($_[0]) eq 'ARRAY' ? @{ shift(@_) } : ( ref($_[0]) eq 'HASH' ? %{ shift(@_) } : shift(@_) ) ;
    my $ins_ok = shift(@_) ;
    
    my $ins_sz = @set / 2 ;

    $ins_ok ||= $ins_sz ;
  
    my $err ;
    for (my $i = 0 ; $i < @set ; $i+=2) {
      $this->{NN}->run($set[$i]) ;
      my $er = $this->{NN}->RMSErr($set[$i+1]) ;
      $er *= -1 if $er < 0 ;
      $err += $er ;
    }
    
    $err /= $ins_ok ;
    return $err ;
  }
  
  sub run { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $in = shift(@_) ;
    
    $this->{NN}->run($in) ;
    my $out = $this->{NN}->output() ;
    return $out ;
  }
  
  sub run_get_winner { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my $out = $this->run(@_) ;
    
    foreach my $out_i ( @$out ) {
      $out_i = $this->out_type_winner($out_i) ;
    }
    
    return $out ;
  }
  
  sub out_type_winner { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $val = shift(@_) ;
    
    my ($out_type , %err) ;
    
    foreach my $types_i ( @{ $this->{OUT_TYPES} } ) {
      my $er = $types_i - $val ;
      $er *= -1 if $er < 0 ;
      $err{$types_i} = $er ;
    }
    
    my $min_type_err = (sort { $err{$a} <=> $err{$b} } keys %err)[0] ;
    $out_type = $min_type_err ;

    return $out_type ;
  }


my $INLINE_INSTALL ; BEGIN { use Config ; my @installs = ($Config{installarchlib} , $Config{installprivlib} , $Config{installsitelib}) ; foreach my $i ( @installs ) { $i =~ s/[\\\/]/\//gs ;} $INLINE_INSTALL = 1 if ( __FILE__ =~ /\.pm$/ && ( join(" ",@INC) =~ /\Wblib\W/s || __FILE__ =~ /^(?:\Q$installs[0]\E|\Q$installs[1]\E|\Q$installs[2]\E)/ ) ) ; }

use Inline C => <<'__INLINE_C_SRC__' , ( $INLINE_INSTALL ? (NAME => 'AI::NNEasy' , VERSION => '0.06') : () ) ;


#define OBJ_SV(self)		SvRV( self )
#define OBJ_HV(self)		(HV*) SvRV( self )
#define OBJ_AV(self)		(AV*) SvRV( self )

#define FETCH_ATTR(hv,k)	*hv_fetch(hv, k , strlen(k) , 0)
#define FETCH_ATTR_PV(hv,k)	SvPV( FETCH_ATTR(hv,k) , len)
#define FETCH_ATTR_NV(hv,k)	SvNV( FETCH_ATTR(hv,k) )
#define FETCH_ATTR_IV(hv,k)	SvIV( FETCH_ATTR(hv,k) )  
#define FETCH_ATTR_HV(hv,k)	(HV*) FETCH_ATTR(hv,k)
#define FETCH_ATTR_AV(hv,k)	(AV*) FETCH_ATTR(hv,k)
#define FETCH_ATTR_SV_REF(hv,k)	SvRV( FETCH_ATTR(hv,k) )
#define FETCH_ATTR_HV_REF(hv,k)	(HV*) SvRV( FETCH_ATTR(hv,k) )
#define FETCH_ATTR_AV_REF(hv,k)	(AV*) SvRV( FETCH_ATTR(hv,k) )

#define FETCH_ELEM(av,i)		*av_fetch(av,i,0)
#define FETCH_ELEM_HV_REF(av,i)	(HV*) SvRV( FETCH_ELEM(av,i) )
#define FETCH_ELEM_AV_REF(av,i)	(AV*) SvRV( FETCH_ELEM(av,i) )

SV* _av_join( AV* av ) {
    SV* ret = sv_2mortal(newSVpv("",0)) ;
    int i ;
    for (i = 0 ; i <= av_len(av) ; ++i) {
      SV* elem = *av_fetch(av, i ,0) ;
      if (i > 0) sv_catpv(ret , " ") ;
      sv_catsv(ret , elem) ;
    }
    return ret ;
}

void _learn_set_get_output_error_c( SV* self , SV* set , double error_ok , int ins_ok , bool verbose ) {
    dXSARGS;
    
    STRLEN len;
    int i ;
    HV* self_hv = OBJ_HV( self );
    AV* set_av = OBJ_AV( set ) ;
    SV* nn = FETCH_ATTR(self_hv , "NN") ;
    SV* print_verbose = verbose ? sv_2mortal(newSVpv("",0)) : NULL ;
    SV* ret ;
    double err = 0 ;
    double er = 0 ;
    int learn_ok = 0 ;
        
    for (i = 0 ; i <= av_len(set_av) ; i+=2) {
      SV* set_in = *av_fetch(set_av, i ,0) ;
      SV* set_out = *av_fetch(set_av, i+1 ,0) ;

      PUSHMARK(SP) ;
        XPUSHs( nn );
        XPUSHs( set_in );
      PUTBACK ;
      call_method("run", G_DISCARD) ;
      
      PUSHMARK(SP) ;
        XPUSHs( nn );
        XPUSHs( set_out );
      PUTBACK ;
      call_method("learn", G_SCALAR) ;
    }
    
    for (i = 0 ; i <= av_len(set_av) ; i+=2) {
      SV* set_in = *av_fetch(set_av, i ,0) ;
      SV* set_out = *av_fetch(set_av, i+1 ,0) ;

      PUSHMARK(SP) ;
        XPUSHs( nn );
        XPUSHs( set_in );
      PUTBACK ;
      call_method("run", G_DISCARD) ;
      
      PUSHMARK(SP) ;
        XPUSHs( nn );
        XPUSHs( set_out );
      PUTBACK ;
      call_method("RMSErr", G_SCALAR) ;
      
      SPAGAIN ;
      ret = POPs ;
      er = SvNV(ret) ;
      if (er < 0) er *= -1 ;
      if (er < error_ok) ++learn_ok ;
      err += er ;
      
      if ( verbose ) sv_catpvf(print_verbose , "%s => %s > %f\n" ,
                       SvPV( _av_join( OBJ_AV(set_in) ) , len) ,
                       SvPV( _av_join( OBJ_AV(set_out) ) , len) ,
                       er
                     ) ;

    }
    
    err /= ins_ok ;

    if (verbose) {
      EXTEND(SP , 3) ;
        ST(0) = sv_2mortal(newSVnv(err)) ;
        ST(1) = sv_2mortal(newSViv(learn_ok)) ;
        ST(2) = print_verbose ;
      XSRETURN(3) ;
    }
    else {
      EXTEND(SP , 2) ;
        ST(0) = sv_2mortal(newSVnv(err)) ;
        ST(1) = sv_2mortal(newSViv(learn_ok)) ;
      XSRETURN(2) ;
    }
}

__INLINE_C_SRC__


}


1;

__END__

=head1 NAME

AI::NNEasy - Define, learn and use easy Neural Networks of different types using a portable code in Perl and XS.

=head1 DESCRIPTION

The main purpose of this module is to create easy Neural Networks with Perl.

The module was designed to can be extended to multiple network types, learning algorithms and activation functions.
This architecture was 1st based in the module L<AI::NNFlex>, than I have rewrited it to fix some
serialization bugs, and have otimized the code and added some XS functions to get speed
in the learning process. Finally I have added an intuitive inteface to create and use the NN,
and added a winner algorithm to the output.

I have writed this module because after test different NN module on Perl I can't find
one that is portable through Linux and Windows, easy to use and the most important,
one that really works in a reall problem.

With this module you don't need to learn much about NN to be able to construct one, you just
define the construction of the NN, learn your set of inputs, and use it.

=head1 USAGE

Here's an example of a NN to compute XOR:

  use AI::NNEasy ;
  
  ## Our maximal error for the output calculation.
  my $ERR_OK = 0.1 ;

  ## Create the NN:
  my $nn = AI::NNEasy->new(
  'xor.nne' , ## file to save the NN.
  [0,1] ,     ## Output types of the NN.
  $ERR_OK ,   ## Maximal error for output.
  2 ,         ## Number of inputs.
  1 ,         ## Number of outputs.
  [3] ,       ## Hidden layers. (this is setting 1 hidden layer with 3 nodes).
  ) ;
  
  
  ## Our set of inputs and outputs to learn:
  my @set = (
  [0,0] => [0],
  [0,1] => [1],
  [1,0] => [1],
  [1,1] => [0],
  );
  
  ## Calculate the actual error for the set:
  my $set_err = $nn->get_set_error(\@set) ;
  
  ## If set error is bigger than maximal error lest's learn this set:
  if ( $set_err > $ERR_OK ) {
    $nn->learn_set( \@set ) ;
    ## Save the NN:
    $nn->save ;
  }
  
  ## Use the NN:
  
  my $out = $nn->run_get_winner([0,0]) ;
  print "0 0 => @$out\n" ; ## 0 0 => 0
  
  my $out = $nn->run_get_winner([0,1]) ;
  print "0 1 => @$out\n" ; ## 0 1 => 1
  
  my $out = $nn->run_get_winner([1,0]) ;
  print "1 0 => @$out\n" ; ## 1 0 => 1
  
  my $out = $nn->run_get_winner([1,1]) ;
  print "1 1 => @$out\n" ; ## 1 1 => 0
  
  ## or just interate through the @set:
  for (my $i = 0 ; $i < @set ; $i+=2) {
    my $out = $nn->run_get_winner($set[$i]) ;
    print "@{$set[$i]}) => @$out\n" ;
  }

=head1 METHODS

=head2 new ( FILE , @OUTPUT_TYPES , ERROR_OK , IN_SIZE , OUT_SIZE , @HIDDEN_LAYERS , %CONF )

=over 4

=item FILE

The file path to save the NN. Default: 'nneasy.nne'.

=item @OUTPUT_TYPES

An array of outputs that the NN can have, so the NN can find the nearest number in this
list to give your the right output.

=item ERROR_OK

The maximal error of the calculated output.

If not defined ERROR_OK will be calculated by the minimal difference between 2 types at
@OUTPUT_TYPES dived by 2:

  @OUTPUT_TYPES = [0 , 0.5 , 1] ;
  
  ERROR_OK = (1 - 0.5) / 2 = 0.25 ;

=item IN_SIZE

The input size (number of nodes in the inpute layer).

=item OUT_SIZE

The output size (number of nodes in the output layer).

=item @HIDDEN_LAYERS

A list of size of hidden layers. By default we have 1 hidden layer, and
the size is calculated by I<(IN_SIZE + OUT_SIZE)>. So, for a NN of
2 inputs and 1 output the hidden layer have 3 nodes.

=item %CONF

Conf can be used to define special parameters of the NN:

Default:

 {networktype=>'feedforward' , random_weights=>1 , learning_algorithm=>'backprop' , learning_rate=>0.1 , bias=>1}
 
Options:

=over 4

=item networktype

The type of the NN. For now only accepts I<'feedforward'>.

=item random_weights

Maximum value for initial weight.

=item learning_algorithm

Algorithm to train the NN. Accepts I<'backprop'> and I<'reinforce'>.

=item learning_rate

Rate used in the learning_algorithm.

=item bias

If true will create a BIAS node. Usefull when you have NULL inputs, like [0,0].

=back

=back

Here's a completly example of use:

  my $nn = AI::NNEasy->new(
  'xor.nne' , ## file to save the NN.
  [0,1] ,     ## Output types of the NN.
  0.1 ,       ## Maximal error for output.
  2 ,         ## Number of inputs.
  1 ,         ## Number of outputs.
  [3] ,       ## Hidden layers. (this is setting 1 hidden layer with 3 nodes).
  {random_connections=>0 , networktype=>'feedforward' , random_weights=>1 , learning_algorithm=>'backprop' , learning_rate=>0.1 , bias=>1} ,
  ) ;

And a simple example that will create a NN equal of the above:

  my $nn = AI::NNEasy->new('xor.nne' , [0,1] , 0.1 , 2 , 1 ) ;

=head2 load

Load the NN if it was previously saved.

=head2 save

Save the NN to a file using L<Storable>.

=head2 learn (@IN , @OUT , N)

Learn the input.

=over 4

=item @IN

The values of one input.

=item @OUT

The values of the output for the input above.

=item N

Number of times that this input should be learned. Default: 100

Example:

  $nn->learn( [0,1] , [1] , 10 ) ;

=back

=head2 learn_set (@SET , OK_OUTPUTS , LIMIT , VERBOSE)

Learn a set of inputs until get the right error for the outputs.

=over 4

=item @SET

A list of inputs and outputs.

=item OK_OUTPUTS

Minimal number of outputs that should be OK when calculating the erros.

By default I<OK_OUTPUTS> should have the same size of number of different
inouts in the @SET.

=item LIMIT

Limit of interations when learning. Default: 30000

=item VERBOSE

If TRUE turn verbose method ON when learning.

=back

=head2 get_set_error (@SET , OK_OUTPUTS)

Get the actual error of a set in the NN. If the returned error is bigger than
I<ERROR_OK> defined on I<new()> you should learn or relearn the set.

=head2 run (@INPUT)

Run a input and return the output calculated by the NN based in what the NN already have learned.

=head2 run_get_winner (@INPUT)

Same of I<run()>, but the output will return the nearest output value based in the
I<@OUTPUT_TYPES> defined at I<new()>.

For example an input I<[0,1]> learned that have
the output I<[1]>, actually will return something like 0.98324 as output and
not 1, since the error never should be 0. So, with I<run_get_winner()>
we get the output of I<run()>, let's say that is 0.98324, and find what output
is near of this number, that in this case should be 1. An output [0], will return
by I<run()> something like 0.078964, and I<run_get_winner()> return 0.

=head1 Samples

Inside the release sources you can find the directory ./samples where you have some
examples of code using this module.

=head1 INLINE C

Some functions of this module have I<Inline> functions writed in C.

I have made a C version only for the functions that are wild called, like:

  AI::NNEasy::_learn_set_get_output_error

  AI::NNEasy::NN::tanh

  AI::NNEasy::NN::feedforward::run
  
  AI::NNEasy::NN::backprop::hiddenToOutput
  AI::NNEasy::NN::backprop::hiddenOrInputToHidden
  AI::NNEasy::NN::backprop::RMSErr

What give to us the speed that we need to learn fast the inputs, but at the same time
be able to create flexible NN.

=head1 Class::HPLOO

I have used L<Class::HPLOO> to write fast the module, specially the XS support.

L<Class::HPLOO> enables this kind of syntax for Perl classes:

  class Foo {
    
    sub bar($x , $y) {
      $this->add($x , $y) ;
    }
    
    sub[C] int add( int x , int y ) {
      int res = x + y ;
      return res ;
    }
    
  }

What make possible to write the module in 2 days! ;-P

=head1 Basics of a Neural Network

I<- This is just a simple text for lay pleople,
to try to make them to understand what is a Neural Network and how it works
without need to read a lot of books -.>

A NN is based in nodes/neurons and layers, where we have the input layer, the hidden layers and the output layer.

For example, here we have a NN with 2 inputs, 1 hidden layer, and 2 outputs:

         Input  Hidden  Output
 input1  ---->n1\    /---->n4---> output1
                 \  /
                  n3
                 /  \
 input2  ---->n2/    \---->n5---> output2


Basically, when we have an input, let's say [0,1], it will active I<n2>, that will
active I<n3> and I<n3> will active I<n4> and I<n5>, but the link between I<n3> and I<n4> has a I<weight>, and
between I<n3> and I<n5> another I<weight>. The idea is to find the I<weights> between the
nodes that can give to us an output near the real output. So, if the output of [0,1]
is [1,1], the nodes I<output1> and I<output2> should give to us a number near 1,
let's say 0.98654. And if the output for [0,0] is [0,0], I<output1> and I<output2> should give to us a number near 0,
let's say 0.078875.

What is hard in a NN is to find this I<weights>. By default L<AI::NNEasy> uses
I<backprop> as learning algorithm. With I<backprop> it pastes the inputs through
the Neural Network and adjust the I<weights> using random numbers until we find
a set of I<weights> that give to us the right output.

The secret of a NN is the number of hidden layers and nodes/neurons for each layer.
Basically the best way to define the hidden layers is 1 layer of (INPUT_NODES+OUTPUT_NODES).
So, a layer of 2 input nodes and 1 output node, should have 3 nodes in the hidden layer.
This definition exists because the number of inputs define the maximal variability of
the inputs (N**2 for bollean inputs), and the output defines if the variability is reduced by some logic restriction, like
int the XOR example, where we have 2 inputs and 1 output, so, hidden is 3. And as we can see in the
logic we have 3 groups of inputs:

  0 0 => 0 # false
  0 1 => 1 # or
  1 0 => 1 # or
  1 1 => 1 # true

Actually this is not the real explanation, but is the easiest way to understand that
you need to have a number of nodes/neuros in the hidden layer that can give the
right output for your problem.

Other inportant step of a NN is the learning fase. Where we get a set of inputs
and paste them through the NN until we have the right output. This process basically
will adjust the nodes I<weights> until we have an output near the real output that we want.

Other important concept is that the inputs and outputs in the NN should be from 0 to 1.
So, you can define sets like:

  0 0      => 0
  0 0.5    => 0.5
  0.5 0.5  => 1
  1 0.5    => 0
  1 1      => 1

But what is really recomended is to always use bollean values, just 0 or 1, for inputs and outputs,
since the learning fase will be faster and works better for complex problems.

=head1 SEE ALSO

L<AI::NNFlex>, L<AI::NeuralNet::Simple>, L<Class::HPLOO>, L<Inline>.

=head1 AUTHOR

Graciliano M. P. <gmpassos@cpan.org>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

Thanks a lot to I<Charles Colbourn <charlesc at nnflex.g0n.net>>, that is the
author of L<AI::NNFlex>, that 1st wrote it, since NNFlex was my starting point to
do this NN work, and 2nd to be in touch with the development of L<AI::NNEasy>.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


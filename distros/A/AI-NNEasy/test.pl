#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 10 } ;

use AI::NNEasy ;

use strict ;
use warnings qw'all' ;

#########################
{
  ok(1) ;
}
#########################
{
  my $file = 'test.nne' ;

  unlink($file) ;

  my $ERR_OK = 0.1 ;

  my $nn = AI::NNEasy->new($file , [0,1] , $ERR_OK , 2 , 1 ) ;
  
  my @set = (
  [0,0],[0],
  [0,1],[1],
  [1,0],[1],
  [1,1],[0],
  );
  
  my $set_err = $nn->get_set_error(\@set) ;
  
  while ( $set_err > $ERR_OK ) {
    $nn->learn_set( \@set , 4 , 30000 , 0 ) ;
    $set_err = $nn->get_set_error(\@set) ;
  }
  
  for (my $i = 0 ; $i < @set ; $i+=2) {
    my $out_ok = $set[$i+1] ;
    
    my $out = $nn->run($set[$i]) ;
    my $out_win = $nn->run_get_winner($set[$i]) ;
    
    my $er = $$out_ok[0] - $$out[0] ;
    $er *= -1 if $er < 0 ;
    
    ok( $er < $ERR_OK ) ;

    ok( $$out_ok[0] , $$out_win[0] ) ;
  }
  
  $set_err = $nn->get_set_error(\@set) ;
  ok( $set_err < $ERR_OK ) ;

}
#########################

print "\nThe End! By!\n" ;

1 ;

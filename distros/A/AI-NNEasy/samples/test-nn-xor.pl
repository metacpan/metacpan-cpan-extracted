  use AI::NNEasy ;

  my $NN_FILE = 'test-xor.nne' ; 

  unlink($NN_FILE) ;

  my $nn = AI::NNEasy->new(
  $NN_FILE ,
  [qw(0 1)] ,
  0 ,
  2 ,
  1 ,
  [3] ,
  ) ;

  my @set = (
  [0,0] => [0],
  [0,1] => [1],
  [1,0] => [1],
  [1,1] => [0],
  );

  my $set_err = $nn->get_set_error(\@set) ;
  
  print "SET ERROR NOW: $set_err\n" ; 

  while ( $set_err > $nn->{ERROR_OK} ) {
    $nn->learn_set( \@set , undef , undef , 1) ;
    $set_err = $nn->get_set_error(\@set) ;
  }
  
  $nn->save ;
  
  print "-------------------------------------------\n" ;
  
  print "ERR_OK: $nn->{ERROR_OK}\n" ;
  
  print "-------------------------------------------\n" ;
  
  my @in = ( 0.9 , 1 ) ;
  my $out = $nn->run(\@in) ;
  my $out_win = $nn->run_get_winner(\@in) ;
  print "@in => @$out_win > @$out\n" ;
      
  print "-------------------------------------------\n" ;

  for (my $i = 0 ; $i < @set ; $i+=2) {
    my $out = $nn->run($set[$i]) ;
    my $out_win = $nn->run_get_winner($set[$i]) ;
    print "@{$set[$i]}) => @$out_win > @$out\n" ;
  }



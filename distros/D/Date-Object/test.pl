#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 48 } ;

use Date::Object ;

use strict ;
use warnings qw'all' ;

sub synchronize {
  print "Synchronizing clock seconds...\n" ;
  my $time = time ;
  while( $time == time ) { select(undef,undef,undef,0.01) ;}
}

#########################
{

  synchronize() ;
  my $d0 = Date::O() ;
  my $d1 = Date::O_zone(-3) ;
  my $d2 = Date::O_local() ;
  
  ok($d0 == $d1) ;
  ok($d1 == $d2) ;
  
  my $d01 = Date::Object->new() ;
  my $d11 = Date::Object->new_zone(-3) ;
  my $d21 = Date::Object->new_local() ;
  
  ok($d0 == $d01) ;
  ok($d1 == $d11) ;
  ok($d2 == $d21) ;
  
  my $d02 = Date::Object->new($d0) ;
  my $d12 = Date::Object->new_zone(-3 , $d0) ;
  my $d22 = Date::Object->new_local($d0) ;
  
  ok($d0 == $d02) ;
  ok($d1 == $d12) ;
  ok($d2 == $d22) ;  
  
  ok( $d02->zone == 0 ) ;
  ok( $d12->zone == -3 ) ;
  
}
#########################
{

  my $max_int = 2147483647 ;

  my $err ;

  for (my $i = 1 ; $i <= $max_int ; $i += 60*60*24*30 ) {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($i);
    ++$mon ;
    $year += 1900 ;
    
    my $d = Date::O_gmt( $year , $mon , $mday , $hour , $min , $sec ) ;
    
    if ( $i != $d->time ) {
      warn("Leap seconds error: $d != $i") ;
      $err = 1 ;
    }
  }
  
  ok(!$err) ;

}
#########################
{

  my $d0 = Date::O_zone( -3 , 2004 , 1 , 1 ) ;
  my $d1 = Date::O_zone( 0 , 2004 , 1 , 1 ) ;
  
  ok($d0 > $d1) ;
  
  my $d2 = Date::O_zone( 0 , 2004 , 1 , 1 ) ;
  my $d3 = Date::O_zone( 0 , 2004 , 1 , 2 ) ;
  
  ok($d2 < $d3) ;

}
#########################
{
  
  my ($year , $mon , $mday , $hour , $min , $sec) = qw(2004 03 20 23 20 34) ;
  
  my $d0 = Date::O( $year , $mon , $mday , $hour , $min , $sec ) ;
  my $d1 = Date::O_zone( -3 , $year , $mon , $mday , $hour , $min , $sec ) ;
  my $d2 = Date::O_local( $year , $mon , $mday , $hour , $min , $sec ) ;
  
  ok($d0->date_zone , "2004-03-20 23:20:34 +0000") ;
  ok($d1->date_zone , "2004-03-20 23:20:34 -0300") ;
  ok($d2->date_zone , "2004-03-20 23:20:34 " . $d2->zone_gmt) ;  
  
  $d0->set_zone(-3) ;
  ok($d0->date_zone , "2004-03-20 20:20:34 -0300") ;
  
}
#########################
{

  synchronize() ;
  my $d0 = Date::O_local() ;
  my $d1 = Date::O() ;
  my $d2 = Date::O() ;
  my $d3 = Date::O_local() ;
  
  $d1->set_local ;
  ok($d0 == $d1) ;
  ok($d1->date , $d0->date) ;  
  
  $d3->set_local ;
  ok($d3->date , $d1->date) ;

  $d2->set_zone( $d0->zone ) ;
  ok($d0 == $d2) ;
  
}
#########################
{

  my $d0 = Date::O_zone(-3 , 2004 , 1 , 1) ;
  my $d1 = Date::O_gmt(2004 , 1 , 1) ;
  
  ok($d0->hours_from($d1) , 3) ;
  ok($d0->hours_until($d1) , -3) ;
  ok($d0->hours_between($d1) , 3) ;  
  
  $d0 = Date::O_zone(3 , 2004 , 1 , 1) ;
  $d1 = Date::O_gmt(2004 , 1 , 1) ;
  
  ok($d0->hours_from($d1) , -3) ;
  ok($d0->hours_until($d1) , 3) ;
  ok($d0->hours_between($d1) , 3) ;  

}
#########################
{

  synchronize() ;
  my $d0 = Date::O(2004 , 2 , 29) ;
  
  ok($d0->date , "2004-02-29 00:00:00") ;
  
  $d0->sub_year(1) ;
  
  ok($d0->date , "2003-02-28 00:00:00") ;
  
  $d0->add_year(1) ;
  
  ok($d0->date , "2004-02-28 00:00:00") ;
  
}
#########################
{

  synchronize() ;
  my $d0 = Date::O(2004 , 2 , 29) ;
  
  ok($d0->{date} , "2004-02-29 00:00:00") ;
  ok($d0->{serial} , "10780128001200") ;
  
}
#########################
{

  my $date = Date::O_gmt( 2004 , 5 , 19 , 21 , 30 ) ;
  
  my $serial = $date->serial ;
  
  ok($serial , 10850022001200) ;
  
  my $date2 = Date::O($serial) ;
  
  ok( $date2->date_zone , '2004-05-19 21:30:00 +0000') ;  
  
  ok($serial , $date2->serial) ;
  
}
#########################
{

  my $date1 = Date::O_gmt( 2004 , 5 , 19 , 21 , 30 ) ;
  my $date2 = Date::O( "2004/5/19 21:30" , 'ymd') ;
  
  ok($date1 , $date2) ;

}
#########################
{

  my $date1 = Date::O_gmt( 2004 , 5 , 19 , 21 , 30 ) ;
  my $date2 = Date::O_gmt( 2005 , 5 , 19 , 21 , 30 ) ;
  
  ok($date1 , '2004-05-19 21:30:00') ;
  ok($date2 , '2005-05-19 21:30:00') ;
  
  $date2->set_serial( $date1->serial ) ;
  
  ok($date1 , $date2) ;

}
#########################
{

  eval(q`use Storable qw(thaw freeze) ;`) ;
  
  if ( !$@ ) {
  
    my $date1 = Date::O_gmt( 2004 , 5 , 19 , 21 , 30 ) ;
    
    my $freeze = freeze($date1) ;
  
    my $date2 = thaw($freeze) ;
    
    ok($date1 , '2004-05-19 21:30:00') ;
    ok($date2 , '2004-05-19 21:30:00') ;
    
    ok($date1 , $date2) ;
  
  }
}
#########################
{

  my $date1 = Date::O_gmt( 2004 , 5 , 19 , 21 , 30 ) ;
  my $date2 = Date::O_gmt( $date1->{y} , $date1->{mo} , 1 ) ;
  
  $date2->add_month ;
  $date2->sub_day ;
  
  ok($date1 , '2004-05-19 21:30:00') ;
  ok($date2 , '2004-05-31 00:00:00') ;
  
  $date1->set( undef , undef , 32 ) ;
  
  ok($date1 , '2004-05-31 21:30:00') ;

}
#########################
{

  my $d = Date::Object->new_local(2005 , 1 , 5 , 20 , 0 , 0) ;
  my $d2 = Date::Object->new_local(2005 , 1 , 31 , 20 , 0 , 0) ;
  my $d_gmt = Date::Object->new_gmt(2005 , 1 , 31 , 23 , 0 , 0) ;
  
  my $d_end = $d->clone->set(undef,undef,31) ;
  
  ok($d != $d_end) ;
  ok($d2 == $d_end) ;
  ok($d_gmt == $d_end) ;

}
#########################

print "\nThe End! By!\n" ;

1 ;

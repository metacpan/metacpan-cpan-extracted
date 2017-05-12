# Tests that ill-defined pivoter objects are flagged correctly

use Data::Pivoter;
use strict;


sub main {
  my ($i,$n);
  print "1..6\n";
  $n = 1;
  
  my $pivoter=Data::Pivoter->new(test=>1);
# All definitions fail  
if (not($pivoter->ok)){
    print "ok $n\n";
  }else{
    print "not ok $n\n";}
  
  $n++;
  


  $pivoter=Data::Pivoter->new(col=> 1, row=> 1, data=> 2, test=>1);
# The same columns are used for col and row data  
  if (not($pivoter->ok)){
    print "ok $n\n";
  }else{
    print "not ok $n\n";}
  
  $n++;

  $pivoter=Data::Pivoter->new(col=> 1, row=> 1, test=>1);
# Data fails
  if (not($pivoter->ok)){
    print "ok $n\n";
  }else{
    print "not ok $n\n";}
  
  $n++;
  
  $pivoter=Data::Pivoter->new(col=> 1, data=> 1, test=>1);
# Row fails
  if (not($pivoter->ok)){
    print "ok $n\n";
  }else{
    print "not ok $n\n";}
  
  $n++;
  
  $pivoter=Data::Pivoter->new(data=> 1, row=> 1, test=>1);
# Col fails
  if (not($pivoter->ok)){
    print "ok $n\n";
  }else{
    print "not ok $n\n";}
  
  $n++;

  
#  $pivoter=Data::Pivoter->new(data=> 1, row=> 1, test=>1,donotvalidate=>1);

  $pivoter=Data::Pivoter->new(col=> 1, row=> 1, data=> 2, donotvalidate=>1);
# Col fails, but do not validate is set
  if ($pivoter->ok){
    print "ok $n\n";
  }else{
    print "not ok $n\n";}
  
  $n++;
}


main ();
1;

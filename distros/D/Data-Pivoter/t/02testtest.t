# This test will give a nok ok to check for false positives in test 01simple

use Data::Pivoter;
use strict;


sub comparray{
  my($arry1,$arry2) = @_;
  my $ok = 'TRUE' if $#{$arry1} == $#{$arry2};	
  for (my ($line)=0;$line <= $#{$arry1}; ++$line){
    for (my ($row)=0;$row <= $#{$arry1->[$line]};++$row){
      print "[$line],[$row]: $arry1->[$line][$row] | $arry2->[$line][$row]\n"
	if $ENV{TEST_DEBUG};
      $ok = 0 unless ($#{$arry1->[$line]} == $#{$arry2->[$line]});
      #my $warn=$^W;
      local $^W=0;
      $ok = 0 if ($arry1->[$line][$row] ne  $arry2->[$line][$row]);
      $ok = 0 if ($arry1->[$line][$row] !=  $arry2->[$line][$row]);
      #$^W=$warn;
      return $ok unless $ok;
    }
  }
  return $ok;
}
	

sub main {
  my (@lines,$i,$n);
  print "1..4\n";
  $n = 1;
  open (INFILE,"<t/table1.dat");

  while(<INFILE>){
    chomp;
    $lines[$i++]=[split];
  }  
  
  my $pivoter=Data::Pivoter->new(col=> 0, row=> 1, data=> 2);
  my @pivtable = @{$pivoter->pivot(\@lines)};
  
  my (@pivcheck);
  @pivcheck=(['ERROR!!','mar','feb','jan'],
	     ['ERROR!!',5,7,1],
	     [2001,6,5,4]);
  
  unless (comparray(\@pivtable,\@pivcheck)){
    print "ok $n\n";
  }else{
    print "not ok 1\n";}
  
  $n++;
  
  $pivoter=Data::Pivoter->new(col=> 1, row=> 1, data=> 2, donotvalidate=>1);
  @pivtable = @{$pivoter->pivot(\@lines)}; 
  
  @pivcheck =(['ERROR!!',2000,2001],
	      [2000,3,undef],
	      [2001,undef,6]);
  
  unless (comparray(\@pivtable,\@pivcheck)){
    print "ok $n\n"
  }else{
    print "not ok 1\n"
  }
  
  $n++;
  @pivcheck = ([1,1],[1,1]);
 
  unless (comparray(\@pivtable,\@pivcheck)){
    print "ok $n\n"
  }else{
    print "not ok 1\n"
  }	
  
  $n++;
  @pivcheck = ([1,1],[1,1],[1,1]);
 
  unless (comparray(\@pivtable,\@pivcheck)){
    print "ok $n\n"
  }else{
    print "not ok 1\n"
  }	
   

}


main ();
1;

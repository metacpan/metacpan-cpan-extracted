# Simple testing of Data::Pivoter

use Data::Pivoter;
use strict;


sub comparray{
  my($arry1,$arry2) = @_;
  my $ok = 'TRUE' if $#{$arry1} == $#{$arry2};	
  for (my ($line)=0;$line <= $#{$arry1}; ++$line){
    for (my ($row)=0;$row <= $#{$arry1->[$line]};++$row){
      print STDERR 
	"[$line],[$row]: $arry1->[$line][$row] | $arry2->[$line][$row]\n"
	if $ENV{TEST_DEBUG};
      $ok = 0 unless ($#{$arry1->[$line]} == $#{$arry2->[$line]});
      local $^W=0;
      $ok = 0 if ($arry1->[$line][$row] ne  $arry2->[$line][$row]);
      $ok = 0 if ($arry1->[$line][$row] !=  $arry2->[$line][$row]);
    }
  }
  return $ok;
}
	




sub main {
  my (@lines,$i,$n);
  print "1..2\n";
  $n = 1;
  open (INFILE,"<t/table1.dat");

  while(<INFILE>){
  #  next if /^\s*\i$/;
    chomp;
    $lines[$i++]=[split];
  }  
  
  my $pivoter=Data::Pivoter->new(col=> 0, row=> 1, data=> 2);
  my @pivtable = @{$pivoter->pivot(\@lines)};
  
  my (@pivcheck);
  @pivcheck=([undef,'feb','jan','mar'],
	     [2000,2,1,3],
	     [2001,5,4,6]);
  
  if (comparray(\@pivtable,\@pivcheck)){
    print "ok $n\n";
  }else{
    print "not ok $n\n";}
  
  $n++;
  
  $pivoter=Data::Pivoter->new(col=> 1, row=> 1, data=> 2, donotvalidate=>1);
  @pivtable = @{$pivoter->pivot(\@lines)}; 
  
  @pivcheck =([undef,2000,2001],
	      [2000,3,undef],
	      [2001,undef,6]);
  
  if (comparray(\@pivtable,\@pivcheck)){
    print "ok $n\n"
  }else{
    print "not ok $n\n"
  }
  
}


main ();
1;

# Testing of sort - functions 

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
  print "1..3\n";
  $n = 1;
  open (INFILE,"<t/table2.dat");

  while(<INFILE>){
  #  next if /^\s*\i$/;
    chomp;
    $lines[$i++]=[split];
  }  
  
  my $pivoter=Data::Pivoter->new(col=> 0, row=> 1, data=> 2);
  my @pivtable = @{$pivoter->pivot(\@lines)};
  
  my (@pivcheck);
  @pivcheck=([undef,1,20,3],
	     ['apr',undef,2002,undef],
	     ['feb',2000,undef,2002],
	     ['jan',2000,2000,2002],
	     ['mar',2000,undef,2001]
	     );
  
  if (comparray(\@pivtable,\@pivcheck)){
    print "ok $n\n";
  }else{
    print "not ok 1\n";}
  
  $n++;
  
  $pivoter=Data::Pivoter->new(col=> 0, row=> 1, data=> 2, numeric=>'C');
  @pivtable = @{$pivoter->pivot(\@lines)}; 
  
  @pivcheck =([undef,1,3,20],
	      ['apr',undef,undef,2002],
              ['feb',2000,2002,undef],
	      ['jan',2000,2002,2000],
	      ['mar',2000,2001,undef],
	     
);
  
  if (comparray(\@pivtable,\@pivcheck)){
    print "ok $n\n"
  }else{
    print "not ok $n\n"
  }

$n++;

 $pivoter=Data::Pivoter->new(col=> 1, row=> 0, data=> 2, numeric=>'R');
  @pivtable = @{$pivoter->pivot(\@lines)}; 
  
  @pivcheck =([undef,'apr','feb','jan','mar'],
              [1,undef,2000,2000,2000],
	      [3,undef,2002,2002,2001],
	      [20,2002,undef,2000,undef]);

  
  if (comparray(\@pivtable,\@pivcheck)){
    print "ok $n\n"
  }else{
    print "not ok $n\n"
  }
  
}


main ();
1;

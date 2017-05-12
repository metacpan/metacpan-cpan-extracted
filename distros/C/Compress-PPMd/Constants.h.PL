#!/usr/local/bin/perl

use strict;
use warnings;

use integer;

use constant UNIT_SIZE => 12;
use constant N1 => 4;
use constant N2 => 4;
use constant N3 => 4;
use constant N4 => int((128+3-1*N1-2*N2-3*N3)/4);
use constant N_INDEXES => N1+N2+N3+N4;

use constant UP_FREQ => 5;
use constant INT_BITS => 7;
use constant PERIOD_BITS => 7;
use constant TOT_BITS => INT_BITS+PERIOD_BITS;
use constant INTERVAL => 2 ** INT_BITS;
use constant BIN_SCALE => 2 ** TOT_BITS;
use constant MAX_FREQ => 124;
use constant O_BOUND => 9;



sub print_array (*$\@) {
  my $file=shift;
  my $type=shift;
  my @a=@{$_[0]};
  printf $file ("%s[%d] = {", $type, scalar(@a));
  my $i=16;
  for (@a) {
    if (++$i<=16) {
      print $file " ";
    }
    else {
      $i=0;
      print $file "\n\t";
    }
    printf $file "0x%x,", $_;
  }
  print $file " };\n\n";
}

open C, "> Constants.h" or die "unable to open Constants.h";

print C "#if !defined(__PPMD_CONSTANTS_H__)\n#define __PPMD_CONSTANTS_H__\n\n\n";

printf C ("enum { UNIT_SIZE=%d, N1=%d, N2=%d, N3=%d, N4=%d, N_INDEXES=%d };\n\n",
	  UNIT_SIZE,
	  N1, N2, N3, N4,
	  N_INDEXES);

printf C ("enum { UP_FREQ=%d, INT_BITS=%d, PERIOD_BITS=%d, TOT_BITS=%d,\n".
	  "\tINTERVAL=%d, BIN_SCALE=%d, MAX_FREQ=%d, O_BOUND=%d };\n\n",
	  UP_FREQ, INT_BITS, PERIOD_BITS, TOT_BITS,
	  INTERVAL, BIN_SCALE, MAX_FREQ, O_BOUND );

print C "\n#endif\n";

close C or die "unable to write to Constants.h";


my ($i, $k, $m, $Step);
my (@Indx2Units, @Units2Indx, @NS2BSIndx, @QTable);

for ($i=0, $k=1; $i<N1; $i++, $k+=1) {
  $Indx2Units[$i]=$k;
}

for ($k++; $i<N1+N2; $i++, $k+=2) {
  $Indx2Units[$i]=$k;
}

for ($k++; $i<N1+N2+N3; $i++, $k+=3) {
  $Indx2Units[$i]=$k;
}

for ($k++;$i < N1+N2+N3+N4;$i++,$k += 4) {
  $Indx2Units[$i]=$k;
}

for ($k=$i=0;$k < 128;$k++) {
  $i+=($Indx2Units[$i]<$k+1);
  $Units2Indx[$k]=$i;
}

$NS2BSIndx[0]=2*0;
$NS2BSIndx[1]=2*1;
# memset(NS2BSIndx+2,2*2,9);
splice @NS2BSIndx, 2, 9, (2*2) x (9);
# memset(NS2BSIndx+11,2*3,256-11);
splice @NS2BSIndx, 11, 256-11, (2*3) x (256-11);

for ($i=0;$i < UP_FREQ;$i++) {
  $QTable[$i]=$i;
}
for ($m=$i=UP_FREQ, $k=$Step=1;$i < 260;$i++) {
  $QTable[$i]=$m;
  if ( !--$k ) {
    $k = ++$Step;
    $m++;
  }
}

open C2, "> Constants2.h" or die "unable to open Constants2.h";

print C2 "#if !defined(__PPMD_CONSTANTS2_H__)\n",
  "#define __PPMD_CONSTANTS2_H__\n\n\n";

print_array(*C2, 'static BYTE NS2BSIndx', @NS2BSIndx);
print_array(*C2, 'static BYTE QTable', @QTable);
print_array(*C2, 'static BYTE Indx2Units', @Indx2Units);
print_array(*C2, 'static BYTE Units2Indx', @Units2Indx);

print C2 "\n#endif\n";

close C2 or die "unable to write Constants2.h";

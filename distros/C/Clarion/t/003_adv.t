# -*- perl -*-

# t/003_adv.t - checking GROUP and MEMO fields. Sequential access

use strict;
use Test::More tests => 12;
use Clarion;

my $csv=readFile('dat/adv.csv');

for my $i(1..3)
{
 my $z=new Clarion "dat/adv$i.dat", 1;
 isa_ok ($z, 'Clarion');
 $z->close;

 $z=new Clarion "dat/adv$i.dat";
 isa_ok ($z, 'Clarion');
 is($z->file_struct, readFile("dat/adv$i.cla"), 'Schema is correct');
 is(getCSV($z), $csv, 'Data read correctly');
}

sub readFile
{
 my $s=shift;
 open F, $s
    or die "Cannot open '$s': $!\n";
 local $/=undef;
 $s=<F>;
 close F;
 return $s;
}

sub getCSV
{
 my $z=shift;
 my $s='';
 foreach my $f(@{$z->{fields}})
 {
  $s.=';'	if length($s);
  $s.=$f->{Name};
 }
 $s.="\n";
 while(my @x=$z->get_record())
 {
  next	if shift @x;
  my $ss='';
  foreach my $n(@x)
  {
   $ss.=';'	if length($ss);
   $ss.=$n||'';
  }
  $s.=$ss."\n";
 }
 return $s;
}

__END__

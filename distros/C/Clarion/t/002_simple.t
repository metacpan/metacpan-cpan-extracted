# -*- perl -*-

# t/002_simple.t - basic reading of .dat-files. Random access

use strict;
use Test::More tests => 9;
use Clarion;

my $csv=readFile('dat/test.csv');

for my $i(1..3)
{
 my $z=new Clarion "dat/test$i.dat";
 isa_ok ($z, 'Clarion');
 is($z->file_struct, readFile("dat/test$i.cla"), 'Schema is correct');
 is(getCSV($z), $csv, "Data read correctly");
 $z->close;
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
 for my $i(1 .. $z->last_record)
 {
  my @x=$z->get_record($i);
  next	if shift @x;
  my $ss='';
  foreach my $n(@x)
  {
   $ss.=';'	if length($ss);
   $ss.=$n;
  }
  $s.=$ss."\n";
 }
 return $s;
}

__END__

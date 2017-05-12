#Make #line directive in pl/perl scripts points to real line in file
use strict;

for my $file (<*.sql>) {
  my $script;
  my $found = 0;
  open IN, $file or die "can't open file $file";
  while ($_ = <IN>) {
    if (/^#line\s+(\d+)$/ && $1 != $.) {
      $_ = "#line $.\n";
      $found++;
    }
    $script .= $_;
  }
  close IN;
  next unless $found;

  print "fixed $found #line in $file\n";
  open OUT, ">", $file or die "can't create file $file";
  print OUT $script;
  close OUT;
}

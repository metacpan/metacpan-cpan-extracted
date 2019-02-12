#!/usr/bin/perl -w

while (defined($_=<>)) {
  if (/^$/ || /^\%\%/) {
    print;
    next;
  }
  chomp;
  ($w,@f) = split(/\t/,$_);
  $loc = "[loc] ".shift(@f) if (@f && $f[0] =~ /^\d+ \d+/);
  $_ = "[toka] $_" foreach (@f);
  print join("\t", $w, (defined($loc) ? $loc : qw()), @f), "\n";
}

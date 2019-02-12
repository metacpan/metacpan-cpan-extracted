#!/usr/bin/perl -w

my ($w,@f,$dmw,$mw,$mt,$ml);

print join("\t", map {"%%$_"} qw(W_OLD W_NEW TAG LEMMA)), "\n";
while (defined($_=<>)) {
  if (/^$/ || /^\%\%/) {
    print;
    next;
  }
  chomp;
  ($w,@f) = split(/\t/,$_);
  $dmw=$mt=$ml= '@UNKNOWN';
  $mw=undef;
  foreach (@f) {
    if    (/^\[dmoot\/tag\] (.*)$/)   { $dmw = $1; }
    elsif (/^\[moot\/word\] (.*)$/)  { $mw = $1; }
    elsif (/^\[moot\/tag\] (.*)$/)   { $mt = $1; }
    elsif (/^\[moot\/lemma\] (.*)$/) { $ml = $1; }
  }
  print join("\t", $w, (defined($mw) ? $mw : $dmw), $mt, $ml), "\n";
}

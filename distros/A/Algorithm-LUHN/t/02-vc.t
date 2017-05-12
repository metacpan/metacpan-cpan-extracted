#!/usr/bin/perl -w

use strict;
use Test;
use Algorithm::LUHN qw/valid_chars/;

BEGIN { plan tests => 6 }

# Check the valid_chars contents
{
  my %chars = valid_chars();
  my @chars = keys %chars;
  ok(@chars, 10, "  Expected 10 valid chars but got ${\(@chars)}\n") or
    Algorithm::LUHN::_dump_map();

  my $ok = 1;
  my $msg;
  for (@chars) {
    $ok = ($_ == $chars{$_}); # char should be same as value
    $msg="  Char $_ has value $chars{$_}, but expected $_\n", last
      unless $ok;
  }
  ok($ok, 1, $msg);
}

# Now keep the same number of keys, but change the values
{
  valid_chars(map {$_ => (9-$_)} 0..9);
  my %chars = valid_chars();
  my @chars = keys %chars;
  ok(@chars, 10, "  Expected 10 valid chars but got ${\(@chars)}\n") or
    Algorithm::LUHN::_dump_map();

  my $ok = 1;
  my $msg;
  for (@chars) {
    $ok = ($_ == 9-$chars{$_}); # char should be same as value
    $msg = "  Char $_ has value $chars{$_}, but expected ".(9-$_)."\n", last
      unless $ok;
  }
  ok($ok, 1, $msg);
}

{
  valid_chars(map {$_ => $_} 0..9); # reset to normal
  valid_chars(map {$_ => ord($_)-ord('A')+10} 'A'..'Z'); # add a bunch of alphas
  my %chars = valid_chars();
  my @chars = keys %chars;
  ok(@chars, 36, "  Expected 36 valid chars but got ${\(@chars)}\n") or
    Algorithm::LUHN::_dump_map();

  my $ok = 1;
  my $msg;
  for (@chars) {
    if ($_ =~ /\d/) {
      $ok = ($_ == $chars{$_}); # char should be same as value
    } else {
      $ok = (ord($_)-ord('A')+10 == $chars{$_});
    }
    $msg = "  Char $_ has unexpected value $chars{$_}\n", last
      unless $ok;
  }
  ok($ok, 1, $msg);
}

__END__

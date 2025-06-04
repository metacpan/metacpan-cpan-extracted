#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', # Test2::V0 etc.
                  qw/bug displaystr fmt_codestring timed_run
                     mycheckeq_literal mycheck @quotes
                     $debug/;

use Scalar::Util qw(refaddr);
use List::Util qw(shuffle);
use Math::BigInt;

use Data::Dumper::Interp qw/:all alvis addrvis_digits addrvis_forget/;
$Data::Dumper::Interp::Foldwidth = 0;  # no folding

#$Data::Dumper::Interp::Debug = 1;

BEGIN {
  *addrvis_ndigits   = *Data::Dumper::Interp::addrvis_ndigits;
  *addrvis_seen      = *Data::Dumper::Interp::addrvis_seen;
  *addrvis_dec_abbrs = *Data::Dumper::Interp::addrvis_dec_abbrs;
  *_ADDRVIS_SHARED_MARK = *Data::Dumper::Interp::_ADDRVIS_SHARED_MARK;
}

use vars qw/$addrvis_ndigits $addrvis_seen $addrvis_dec_abbrs/;
my $addrvis_re = qr/[A-Za-z][:\w]*\<\d+:[\da-fA-F]+\>/;

use Test2::Require::Module 'threads';  # skip entire test if not available on this platform
use Test2::Require::Module 'threads::shared';
use threads;
use threads::shared;

my $href = { "zort" => 12345 };
my $unshared_var = 111;
my $ref_to_unshared = \$unshared_var;
my $shared_var :shared = 222;
my $ref_to_shared = \$shared_var;

my $shared_cloned_var = shared_clone $href;


like(dvis('dvis: $ref_to_unshared $ref_to_shared $shared_cloned_var $href'),
     "dvis: ref_to_unshared=\\111 ref_to_shared=\\222 shared_cloned_var={zort => 12345} href={zort => 12345}");

sub count_digits($) {
  local $_ = shift;
  # Here we don't care which side the marker is on
  /<(\Q${\_ADDRVIS_SHARED_MARK}\E)?(\d+):(\Q${\_ADDRVIS_SHARED_MARK}\E)?([a-fA-F0-9]+)>/ or die;
  my $dec = $2;
  my $hex = $4;
  my $marker = $1 || $3;
  oops dvis '$_ $dec $hex $marker'
    unless length($dec)==length($hex) && $marker;
  return length($dec);
}
sub lower_n_hexdigits($$) {
  (local $_, my $ndig) = @_;
  /<(\Q${\_ADDRVIS_SHARED_MARK}\E)?(\d+):(\Q${\_ADDRVIS_SHARED_MARK}\E)?([a-fA-F0-9]+)>/ or die;
  my $hex = $4;
  oops unless length($hex) >= $ndig;
  return substr($hex,-$ndig,$ndig)
}


addrvis_forget();
$Data::Dumper::Interp::addrvis_ndigits  = 1;
note "1d: dvisr(ref_to_unshared) = ",visnew->dvisr('$ref_to_unshared'), "\n";
note "1d: dvisr(ref_to_shared) = ",visnew->dvisr('$ref_to_shared'), "\n";
note "1d: addrvis(ref_to_unshared) = ",u(addrvis($ref_to_unshared)), "\n";
note "1d: addrvis(ref_to_shared) = ",u(addrvis($ref_to_shared)), "\n";
note "1d: addrvis(shared_cloned_var) = ",u(addrvis($shared_cloned_var)), "\n";
note "1d: addrvis(href) = ",u(addrvis($href)), "\n";
{ my @items;
  my $MAX_ITEMS = 100;
  addrvis_forget();
  $addrvis_ndigits  = 1;
  my $prev_ndig = $addrvis_ndigits;
  my @prev_got;
  for my $ni (0..$MAX_ITEMS-1) {
    #note dvis '--- $ni ---\n';
    # Re-check that previous items have not changed
    for my $ri (0..$ni-1) {
      my $num_entries = @{[keys %$addrvis_dec_abbrs]};
      oops dvis '$ri Expecting $ni entries (not $num_entries): $addrvis_dec_abbrs'
        unless $num_entries == $ni;
      my $got = addrvis($items[$ri]);
      oops dvis '$ri $got $prev_got[$ri] $prev_ndig'
        unless $got eq $prev_got[$ri] and count_digits($got) == $prev_ndig;
    }
    oops unless @items == $ni;
    my $new_item = shared_clone $href;
    push @items, $new_item;
    my $new_got = addrvis($items[$ni]);
    push @prev_got, $new_got;
    my $ndig = count_digits($new_got);
    if ($ndig != $prev_ndig) {
      note ivis 'Multi-digit jump from $prev_ndig to $ndig digits. $new_got\n'
        unless $ndig == $prev_ndig+1;
      # Verify that old values did not get corrupted
      for my $ri (0..$#prev_got) {
        my $newg = addrvis($items[$ri]);
        oops dvis '$ri '.$items[$ri].' $newg $prev_got[$ri] $prev_ndig'
                 .'\n ${\lower_n_hexdigits($newg,$prev_ndig)}'
                 .'\n ${\lower_n_hexdigits($prev_got[$ri],$prev_ndig)}'
          unless lower_n_hexdigits($newg,$prev_ndig)
              eq lower_n_hexdigits($prev_got[$ri],$prev_ndig);
        $prev_got[$ri] = $newg;
      }
      $prev_ndig = $ndig;
    }
    note "1d: addrvis new ref #$ni = $new_got\n";
    last if $ndig >= 4;
  }
  addrvis_forget();
}

addrvis_digits(10);

note "dvisr(ref_to_unshared) = ",visnew->dvisr('$ref_to_unshared'), "\n";
note "dvisr(ref_to_shared) = ",visnew->dvisr('$ref_to_shared'), "\n";
note "addrvis(ref_to_unshared) = ",u(addrvis($ref_to_unshared)), "\n";
note "addrvis(ref_to_shared) = ",u(addrvis($ref_to_shared)), "\n";
note "addrvis(shared_cloned_var) = ",u(addrvis($shared_cloned_var)), "\n";
note "addrvis(href) = ",u(addrvis($href)), "\n";

my $unshared_re = qr/\<(\d{10}):([a-fA-F0-9]{10})\>/;
my $shared_re   = qr/\<(\d{10}):\Q${\_ADDRVIS_SHARED_MARK}\E([a-fA-F0-9]{10})\>/;

like(visnew->Refaddr(1)->ivis('$ref_to_unshared'), qr/\A${unshared_re}\\111\z/);
like(visnew->Refaddr(1)->dvis('$ref_to_unshared'), qr/\Aref_to_unshared=${unshared_re}\\111\z/);

like(visnew->Refaddr(1)->dvis('$ref_to_shared'), qr/\Aref_to_shared=${shared_re}\\222\z/);

like(visnew->Refaddr(1)->dvis('$ref_to_unshared $ref_to_shared'), qr/\Aref_to_unshared=${unshared_re}\\111 ref_to_shared=${shared_re}\\222\z/);

like(visnew->Refaddr(1)->dvis('dvis: $ref_to_unshared $ref_to_shared $shared_cloned_var'),
  qr/\Advis: ref_to_unshared=${unshared_re}\\111 ref_to_shared=${shared_re}\\222 shared_cloned_var=${shared_re}\{.*\}\z/);

like(visnew->dvisr('dvis: $shared_cloned_var $href'),
     qr/\Advis: shared_cloned_var=${shared_re}\{zort => 12345\} href=${unshared_re}\{zort => 12345\}\z/);

done_testing();

exit 0;

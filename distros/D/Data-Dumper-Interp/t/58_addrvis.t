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

use Data::Dumper::Interp qw/:all alvis set_addrvis_digits/;
$Data::Dumper::Interp::Foldwidth = 0;  # no folding

my $addrvis_re = qr/[A-Za-z][:\w]*\<\d+:[\da-fA-F]+\>/;

##################################################
# Check addrvis() auto-increasing number of digits
##################################################
BEGIN {
  *addrvis_ndigits   = *Data::Dumper::Interp::addrvis_ndigits;
  *addrvis_seen      = *Data::Dumper::Interp::addrvis_seen;
  *addrvis_dec_abbrs = *Data::Dumper::Interp::addrvis_dec_abbrs;
}
use vars qw/$addrvis_ndigits $addrvis_seen $addrvis_dec_abbrs/;

# How is addrvis() implemented today?
my $hexordec = "dec";  # maxdigits applies to hex or decimal
sub fmtra($) { $hexordec eq "dec" ? $_[0] : sprintf("0x%x",$_[0]) }

{
  my ($ndigits, @addresses);
  sub check_addrvis() {
    for my $n (@addresses) {
      my $decchars = substr(sprintf("%010d",$n),-$ndigits);
      my $hexchars = substr(sprintf("%016x",$n),-$ndigits);
      my $re = qr/^\<${decchars}:${hexchars}\>$/;
      my $act = addrvis($n);
      unless ($act =~ /$re/) {
        croak
          sprintf("addrvis(%d = 0x%x) wrong Got:%s re: %s\n", $n,$n, $act, $re),
            "Expecting $ndigits ($hexordec) digits\n",
            "addrvis_ndigits = ", $addrvis_ndigits, "\n",
            "Cache _seen contains ", scalar(keys %$addrvis_seen), " entries:  \n",
            alvis(sort { $a <=> $b } keys %$addrvis_seen),"\n ",
            "Cache _dec_abbrs contains ", scalar(keys %$addrvis_dec_abbrs), " entries:  \n",
            alvis(sort { $a <=> $b } keys %$addrvis_dec_abbrs),"\n ";
      }
    }
  }

  sub maxoff($) {
    my $ndigits = shift;
    my $base = $hexordec eq "dec" ? 10 : 16;
    ($base ** $ndigits) - 1;
  }

  Data::Dumper::Interp::addrvis_forget();
  $ndigits = 3;

  my $first = 0x42000;
  #my $first = 0;
  my $last = $first + maxoff($ndigits);
  my @starting_addresses = shuffle($first..$last);
  @addresses = (@starting_addresses, shuffle($first..($first+16)));

  check_addrvis();
  ok(1, "addrvis stays with 3 $hexordec digits for ".fmtra($first)."..".fmtra($last));

  $ndigits = 4;
  my $next = $first+maxoff(3)+1;
  for my $a ($next..($next+99)) {
    $next = $a;
    unshift @addresses, $a;
    check_addrvis();
  }
  $next = $first+maxoff(4);
  unshift @addresses, $next;
  check_addrvis();
  ok(1, "addrvis advanced to 4 $hexordec digits correctly for ".fmtra($first)."..".fmtra($next));

  $ndigits = 6;
  unshift @addresses, $first+maxoff(5)+1, $first+maxoff(6);
  check_addrvis();
  for my $n (1..50) {
    unshift @addresses, $first+maxoff(5)+$n;
    check_addrvis();
  }
  unshift @addresses, $first+maxoff(6);
  check_addrvis();
  ok(1, "addrvis jumped to 6 digits correctly");

  Data::Dumper::Interp::addrvis_forget();
  @addresses = @starting_addresses;
  $ndigits = 3;
  check_addrvis();
  ok(1, "addrvis_forget()");

  set_addrvis_digits(10);
  $ndigits = 10;
  check_addrvis();
  ok(1, "set_addrvis_digits()");
}

##################################################

my $aref = [100,101,102];
my $href = {aaa => 100};
my $sref = \42;
my $bigint = Math::BigInt->new("1234567890987654321234567890987654321");
my $complicated = [ 42, $aref, $aref, $href, $href, $sref, $sref, $bigint ];

sub refaddress_part($) { addrvis(refaddr $_[0]) }
my $aref_ra;
my $href_ra;
my $sref_ra;
my $bigint_ra;
my $complicated_ra;

my $saved_ndigits = 0;
sub reget_addrvis() {
  # Pre-run in case number of digits needs to increase from before or mid-way
  () = (visnew->Objects(0)->rvis($bigint));
  foreach ($aref, $href, $sref, $bigint, $complicated) { () = (addrvis) }
  my $nd = $Data::Dumper::Interp::addrvis_ndigits;

  $aref_ra   = refaddress_part $aref;
  $href_ra   = refaddress_part $href;
  $sref_ra   = refaddress_part $sref;
  $bigint_ra = refaddress_part $bigint;
  $complicated_ra = refaddress_part $complicated;
  oops unless $nd == $Data::Dumper::Interp::addrvis_ndigits;

  if ($nd != $saved_ndigits) {
    note "[line ".(caller(0))[2]."] addrvis_ndigits is now $nd" if $debug;
    $saved_ndigits = $nd;
    return 1 # Return true if ndigits changed
  } else {
    note "[line ".(caller(0))[2]."] addrvis_ndigits is unchanged" if $debug;
    return 0
  }
}
reget_addrvis;

my $aref_vis  = vis($aref);
my $href_vis  = vis($href);
my $sref_vis  = vis($sref);
my $bigint_vis= vis($bigint);

if ($debug) {
  note "aref_vis=$aref_vis";
  note "href_vis=$href_vis";
  note "sref_vis=$sref_vis";
  note "bigint_vis=$bigint_vis";

  note "rvis('foo')=",rvis('foo');
  note "rvis(42)=",rvis(42);
  note "rvis(\$href)=",rvis($href);
  note "rvis(\$aref)=",rvis($aref);
  note "rvis(\$sref)=",rvis($sref);
  note "rvis(\$bigint)=",rvis($bigint);
  note "visnew->Objects(0)->rvis(\$bigint)=",visnew->Objects(0)->rvis($bigint);
}

fail("Unexpected ndigits change") if reget_addrvis;

# Basic tests
{
  my $decchars = substr(sprintf("%020d",refaddr($aref)),-$addrvis_ndigits);
  my $hexchars = substr(sprintf("%020x",refaddr($aref)),-$addrvis_ndigits);
  is( addrvis($aref),  "ARRAY<${decchars}:${hexchars}>", "Basic addrvis(ref)",
      dvis('$addrvis_ndigits'));
  is( addrvis(refaddr $aref),
      "<${decchars}:${hexchars}>", "Basic addrvis(number)" );
  is( addrvisl($aref), "ARRAY ${decchars}:${hexchars}", "Basic addrvisl(ref)");
  is( addrvisl(refaddr $aref),
      "${decchars}:${hexchars}", "Basic addrvisl(number)");
}

#
### rvis, rvisq ###
#
sub check_rvis($) {
  my $item = shift;
  my $addr = refaddr($item);
  my $abbr_addr = addrvis($addr);
  my ($exp, $desc);
  my $vis_result = vis($item);
  my $visq_result = visq($item);
  if (defined $addr) {
    my $reftype = reftype($item);
    my $ref     = ref($item); # class name if blessed
    confess dvis 'mal-formed addrvis(refaddr) result $abbr_addr ($addr)'
      unless defined($abbr_addr)
             && $abbr_addr =~ /^\<\d{3,99}:[\da-f]{3,99}\>$/;
    $exp = $abbr_addr.$vis_result;
    $desc = sprintf "rvis(%s) is %s", u($item), rvis($exp);
  } else {
    # item is not a reference
    die "addrvis(undef) should be 'undef' not <<$abbr_addr>>"
      unless $abbr_addr eq "undef";
    $exp = $vis_result;
    $desc = sprintf "NON-ref: rvis(%s) eq vis eq %s", u($item), vis($exp);
    #FIXME: what about addrvis(non-ref) ??
  }
  $desc .= " [line ".(caller(0))[2]."]";
  my $rvis_result = rvis($item);
  is($rvis_result, $exp, $desc);
}
check_rvis($href);
check_rvis($aref);
check_rvis($sref);
check_rvis($bigint);
check_rvis(42);
check_rvis(undef);

fail("Unexpected ndigits change") if reget_addrvis;

{ my $s = rvisq({aaa => "hello"});
  like($s, qr/^<\d+:[\da-fA-F]+>\{aaa => 'hello'\}$/, "rvisq result is $s");
}

note "avisr(\@\$aref)=",avisr(@$aref) if $debug;
is (avisr(@$aref), "(100,101,102)", "avisr with non-ref ary elements");

for ([$aref,"ARRAY"], [$href,"HASH"], [$sref,"SCALAR"], [$bigint,"Math::BigInt"]) {
  my ($theref, $type) = @$_;
  my $plain = vis($theref);
  # avis & hvis might increase the number of addrvis digits even if all the
  # arguments have already been seen by addrvis, so we must run it
  # twice (to ensure it is internally consistent in number of digits)
  # and then re-get the addrvis for components
  #
  # This is because avis & hvis put their args into a temp [] or {} for
  # formatting which, with 'r'/Refaddr, will prepend an addrvis prefix
  # to the temp container.   The prefix will be discarded and the [] or {}
  # changed to () in the final result.

  my $rvis_re = qr/\<\d+:[\dA-Fa-f]+\>\Q${plain}\E/a;

  { my $got = avisr(42,$theref,44);
    my $exp_re = qr/^\(42,${rvis_re},44\)$/;
    like($got, $exp_re, "avisr with $type $plain [s,r,s]");
  }
  { # Subsequent duplicate refs are shown just as <dec:hex>[...] etc.
    my $got; for (1,2){ $got = visnew->avisr($theref,$theref,44); }
    my $addrvis = addrvis($theref);
    my $abbr_addr = refaddress_part($theref);
    my $exp_re = qr/^\(${rvis_re},(?:\Q${addrvis}\E|\Q${abbr_addr}\E[\[\{]\.\.\..),44\)$/;
    like($got, $exp_re, "avisr with $type $plain [r,r,s]");
  }
}

reget_addrvis;

#
### rivis, dvisr etc.
#
my $complicated_vis = vis($complicated);
note "complicated_vis=$complicated_vis" if $debug;

$Data::Dumper::Interp::Foldwidth = 0;
my $str = '$href $aref $sref $bigint\n$complicated';
my $dvis_normal = dvis $str;
note "normal dvis: $dvis_normal" if $debug;
fail("Unexpected ndigits change") if reget_addrvis;

my $dvis_r = dvisr $str;
note "r dvis: $dvis_r" if $debug;
fail("Unexpected ndigits change") if reget_addrvis;
like($dvis_r, qr/^\Qhref=${href_ra}${href_vis} aref=${aref_ra}${aref_vis} sref=${sref_ra}${sref_vis}\E\s+\Qbigint=${bigint_ra}${bigint_vis}\E\s+complicated=\Q${complicated_ra}[42,${aref_ra}${aref_vis},${aref_ra}[...]\E.*/, "dvisr test");

done_testing();

exit 0;

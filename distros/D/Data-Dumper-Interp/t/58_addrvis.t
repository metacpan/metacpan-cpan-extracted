#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', # Test::More etc.
                  qw/bug displaystr fmt_codestring timed_run 
                     checkeq_literal check @quotes/;

use Data::Dumper::Interp;
use Scalar::Util qw(refaddr);
use List::Util qw(shuffle);
use Math::BigInt;

my $href = {aaa => 100};
my $aref = [100,101,102];
my $sref = \42;
my $bigint = Math::BigInt->new("1234567890987654321234567890987654321");

note "addrvis(\$href)=",addrvis($href);
note "addrvis(refaddr \$href)=",addrvis(refaddr $href);
note "refvis('foo')=",refvis('foo');
note "refvis(42)=",refvis(42);
note "refvis(\$href)=",refvis($href);
note "refvis(\$aref)=",refvis($aref);
note "refvis(\$sref)=",refvis($sref);
note "refvis(\$bigint)=",refvis($bigint);
note "visnew->Objects(0)->refvis(\$bigint)=",visnew->Objects(0)->refvis($bigint);

sub check_refvis($) {
  my $item = shift;
  my $vis_result = vis($item);
  my $refvis_result = refvis($item);
  my $addr = refaddr($item);
  my $abbr_addr = addrvis($item);
  my ($exp, $desc);
  if (defined $addr) {
    my $reftype = reftype($item);
    confess "mal-formed addrvis($reftype) result ($abbr_addr)" 
      unless $abbr_addr =~ /^${reftype}\<\d{3,99}:[\da-f]{3,99}\>$/;
    $exp = $abbr_addr.$vis_result;
    $desc = sprintf "refvis(%s) is %s", u($item), vis($exp);
  } else {
    # item is not a reference
    confess "mal-formed addrvis(non-ref) result ($abbr_addr)" 
      unless !defined($item) || $abbr_addr =~ /^\d{3,99}:[\da-f]{3,99}$/;
    $exp = $vis_result;
    $desc = sprintf "NON-ref: refvis(%s) eq vis eq %s", u($item), vis($exp);
    #FIXME: what about addrvis(non-ref) ??
  }
  $desc .= " [line ".(caller(0))[2]."]";
  ok( $refvis_result eq $exp, $desc);
}
check_refvis($href);
check_refvis($aref);
check_refvis($sref);
check_refvis($bigint);
check_refvis(42);
check_refvis(undef);

##################################################
# Check auto-increasing number of digits
##################################################
BEGIN {
  *addrvis_ndigits = *Data::Dumper::Interp::addrvis_ndigits;
  *addrvis_a2abv = *Data::Dumper::Interp::addrvis_a2abv;
}
use vars qw/$addrvis_ndigits $addrvis_a2abv/;

my @starting_addresses = shuffle(0x42000..0x42FFF);

my ($ndigits, @addresses);
sub check_addrvis() {
  for my $n (@addresses) {
    my $hexchars = substr(sprintf("%09x",$n),-$ndigits);
    my $act = addrvis($n); 
    my $re = qr/^\d+:${hexchars}$/;
    unless ($act =~ /$re/) {
#      for my $addr (sort { $a <=> $b } keys %$addrvis_a2abv) {
#        diag sprintf "  addrvis_a2abv{%x}=%s", 
#                     $addr, vis($addrvis_a2abv->{$addr}) ;
#      }
      die sprintf("addrvis(0x%x) wrong (%s) re: %s\n", $n, $act, $re),
          "Cache contains ", 
            scalar(keys %$addrvis_a2abv), " entries\n",
          "addrvis_ndivgits = ", $addrvis_ndigits, " ";
    }
  }
}

Data::Dumper::Interp::addrvis_forget();
@addresses = (@starting_addresses, shuffle(0x42000..0x42020));
$ndigits = 3;
check_addrvis();
ok(1, "addrvis stays with 3 digits for 000..FFF");

unshift @addresses, 0x103000;
$ndigits = 4;
check_addrvis();
unshift @addresses, 0x113001;
check_addrvis();
ok(1, "addrvis advanced to 4 digits correctly");

unshift @addresses, 0x203000;
$ndigits = 6;
check_addrvis();
ok(1, "addrvis jumped to 6 digits correctly");

Data::Dumper::Interp::addrvis_forget();
@addresses = @starting_addresses;
$ndigits = 3;
check_addrvis();
ok(1, "addrvis_forget()");

done_testing();

exit 0;

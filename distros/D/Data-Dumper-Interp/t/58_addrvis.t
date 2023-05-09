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
note "rvis('foo')=",rvis('foo');
note "rvis(42)=",rvis(42);
note "rvis(\$href)=",rvis($href);
note "rvis(\$aref)=",rvis($aref);
note "rvis(\$sref)=",rvis($sref);
note "rvis(\$bigint)=",rvis($bigint);
note "visnew->Objects(0)->rvis(\$bigint)=",visnew->Objects(0)->rvis($bigint);

sub check_rvis($) {
  my $item = shift;
  my $addr = refaddr($item);
  my $abbr_addr = addrvis($item);
  my ($exp, $desc);
  my $vis_result = vis($item);
  my $visq_result = visq($item);
  if (defined $addr) {
    my $reftype = reftype($item);
    confess "mal-formed addrvis($reftype) result ($abbr_addr)" 
      unless $abbr_addr =~ /^${reftype}\<\d{3,99}:[\da-f]{3,99}\>$/;
    $exp = $abbr_addr.$vis_result;
    $desc = sprintf "rvis(%s) is %s", u($item), rvis($exp);
  } else {
    # item is not a reference
    confess "mal-formed addrvis(non-ref) result ($abbr_addr)" 
      unless !defined($item) || $abbr_addr =~ /^\d{3,99}:[\da-f]{3,99}$/;
    $exp = $vis_result;
    $desc = sprintf "NON-ref: rvis(%s) eq vis eq %s", u($item), vis($exp);
    #FIXME: what about addrvis(non-ref) ??
  }
  $desc .= " [line ".(caller(0))[2]."]";
  my $rvis_result = rvis($item);
  ok( $rvis_result eq $exp, $desc);
}
check_rvis($href);
check_rvis($aref);
check_rvis($sref);
check_rvis($bigint);
check_rvis(42);
check_rvis(undef);

{ my $s = rvisq({aaa => "hello"});
  like($s, qr/^HASH<\d+:[\da-fA-F]+>\{aaa => 'hello'\}$/, "rvisq result is $s");
}

##################################################
# Check auto-increasing number of digits
##################################################
BEGIN {
  *addrvis_ndigits = *Data::Dumper::Interp::addrvis_ndigits;
  *addrvis_a2abv = *Data::Dumper::Interp::addrvis_a2abv;
}
use vars qw/$addrvis_ndigits $addrvis_a2abv/;

# How is addrvis() implemented today?
my $hexordec = "dec";  # maxdigits applies to hex or decimal
sub fmtra($) { $hexordec eq "dec" ? $_[0] : sprintf("0x%x",$_[0]) }

my ($ndigits, @addresses);
sub check_addrvis() {
  for my $n (@addresses) {
    my $hexchars = substr(sprintf("%09x",$n),-$ndigits);
    my $decchars = substr(sprintf("%09d",$n),-$ndigits);
    my $re = qr/^${decchars}:${hexchars}$/;
    my $act = addrvis($n); 
    unless ($act =~ /$re/) {
#      for my $addr (sort { $a <=> $b } keys %$addrvis_a2abv) {
#        diag sprintf "  addrvis_a2abv{%x}=%s", 
#                     $addr, vis($addrvis_a2abv->{$addr}) ;
#      }
      croak 
        sprintf("addrvis(%d = 0x%x) wrong Got:%s re: %s\n", $n,$n, $act, $re),
          "Expecting $ndigits ($hexordec) digits\n",
          "addrvis_ndigits = ", $addrvis_ndigits, "\n",
          "Cache contains ", scalar(keys %$addrvis_a2abv), " entries:\n",
          avisl(sort { $a <=> $b } keys %$addrvis_a2abv),"\n ";
    }
  }
}

sub maxoff($) {
  my $ndigits = shift;
  my $base = $hexordec eq "dec" ? 10 : 16;
  ($base ** $ndigits) - 1;
}

my $first = 0x42000;
#my $first = 0;
my $last = $first + maxoff(3);
my @starting_addresses = shuffle($first..$last);

Data::Dumper::Interp::addrvis_forget();
$ndigits = 3;
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

done_testing();

exit 0;

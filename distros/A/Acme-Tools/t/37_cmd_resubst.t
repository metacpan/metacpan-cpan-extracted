# make test
# perl Makefile.PL; make; perl -Iblib/lib t/37_cmd_resubst.t

use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests    => 2;
my $gzip=(grep -x$_, '/bin/gzip', '/usr/bin/gzip')[0];
warn <<"" and map ok(1),1..2 and exit if $^O!~/^(linux|cygwin)$/ or !$gzip;
Tests for cmd_due not available for $^O, only linux and cygwin

my $tmp=tmp();
srand(7);
writefile("$tmp/$_",join("",map{"$_ ".($_%10?"":rand())."\n"}1..100)) for 1..20;
sub test {
  my($ok,@a)=@_;
  my $p=printed{Acme::Tools::cmd_resubst(@a)};
  $p=~s,/tmp/\w+,/tmp/x,g;
  is($p, $ok);
}
test(<<".",'-v','-f',6,map"$tmp/$_",1..20);
 1/20 26/26               560 =>     534 b (95%) /tmp/x/1
 2/20 50/24               563 =>     539 b (95%) /tmp/x/2
 3/20 78/28               564 =>     536 b (95%) /tmp/x/3
 4/20 105/27              565 =>     538 b (95%) /tmp/x/4
 5/20 131/26              565 =>     539 b (95%) /tmp/x/5
 6/20 158/27              563 =>     536 b (95%) /tmp/x/6
 7/20 181/23              565 =>     542 b (95%) /tmp/x/7
 8/20 205/24              560 =>     536 b (95%) /tmp/x/8
 9/20 231/26              564 =>     538 b (95%) /tmp/x/9
10/20 256/25              563 =>     538 b (95%) /tmp/x/10
11/20 281/25              563 =>     538 b (95%) /tmp/x/11
12/20 306/25              561 =>     536 b (95%) /tmp/x/12
13/20 334/28              562 =>     534 b (95%) /tmp/x/13
14/20 362/28              564 =>     536 b (95%) /tmp/x/14
15/20 387/25              562 =>     537 b (95%) /tmp/x/15
16/20 415/28              562 =>     534 b (95%) /tmp/x/16
17/20 443/28              562 =>     534 b (95%) /tmp/x/17
18/20 471/28              563 =>     535 b (95%) /tmp/x/18
19/20 498/27              562 =>     535 b (95%) /tmp/x/19
20/20 523/25              560 =>     535 b (95%) /tmp/x/20
Replaces: 523  Bytes before: 11253  After: 10730   Change: -4.6%
.
qx($gzip $tmp/*);
test(<<".",'-o','bz2','-9','-v','-f',7,map"$tmp/$_.gz",1..20);
 1/20 26/26               270 =>     241 b (89%) /tmp/x/1.gz
 2/20 53/27               270 =>     244 b (90%) /tmp/x/2.gz
 3/20 81/28               269 =>     250 b (92%) /tmp/x/3.gz
 4/20 107/26              271 =>     242 b (89%) /tmp/x/4.gz
 5/20 134/27              270 =>     240 b (88%) /tmp/x/5.gz
 6/20 159/25              269 =>     248 b (92%) /tmp/x/6.gz
 7/20 185/26              272 =>     252 b (92%) /tmp/x/7.gz
 8/20 213/28              269 =>     241 b (89%) /tmp/x/8.gz
 9/20 240/27              271 =>     242 b (89%) /tmp/x/9.gz
10/20 268/28              272 =>     247 b (90%) /tmp/x/10.gz
11/20 295/27              271 =>     248 b (91%) /tmp/x/11.gz
12/20 320/25              271 =>     240 b (88%) /tmp/x/12.gz
13/20 346/26              268 =>     238 b (88%) /tmp/x/13.gz
14/20 371/25              268 =>     244 b (91%) /tmp/x/14.gz
15/20 396/25              271 =>     243 b (89%) /tmp/x/15.gz
16/20 423/27              270 =>     240 b (88%) /tmp/x/16.gz
17/20 448/25              267 =>     244 b (91%) /tmp/x/17.gz
18/20 473/25              269 =>     243 b (90%) /tmp/x/18.gz
19/20 500/27              268 =>     243 b (90%) /tmp/x/19.gz
20/20 525/25              271 =>     244 b (90%) /tmp/x/20.gz
Replaces: 525  Bytes before: 5397  After: 4874   Change: -9.7%
.

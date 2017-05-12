#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'IP tests';
$testdir = '';
$testdir = $t->testdir();

$t->use_ok("NetAddr::IP",'feature');
$t->skip_all('IP tests ignored (install NetAddr::IP to test)','NetAddr::IP');

$t->use_ok("NetAddr::IP::Lite",'feature');
$t->skip_all('IP tests ignored (install NetAddr::IP::Lite to test)','NetAddr::IP::Lite');

use Data::Checker;
$obj   = new Data::Checker;

sub test {
   my($data,$opts) = @_;
   my($pass,$fail,$info,$warn) = $obj->check($data,"IP",$opts);
   my @out = ("PASS");
   if (ref($pass) eq 'ARRAY') {
      push(@out,sort @$pass);
   } else {
      push(@out,sort keys %$pass);
   }

   push(@out,"FAIL");
   foreach my $ele (sort keys %$fail) {
      push(@out,join(' ',$ele,@{ $$fail{$ele} }));
   }

   push(@out,"INFO");
   foreach my $ele (sort keys %$info) {
      push(@out,join(' ',$ele,@{ $$info{$ele} }));
   }

   push(@out,"WARN");
   foreach my $ele (sort keys %$warn) {
      push(@out,join(' ',$ele,@{ $$warn{$ele} }));
   }

   return @out;
}

$tests=q(

[ foo.bar.com 1.2.3.4/a 1.2.3.4/33 ] { }
   =>
   PASS
   FAIL
   '1.2.3.4/33 Not a valid IP'
   '1.2.3.4/a Not a valid IP'
   'foo.bar.com Not a valid IP'
   INFO
   WARN

[ 1.2.3.4 1:2:3:4:5:6:7:8 ] { ipv4 __undef__ }
   =>
   PASS
   1.2.3.4
   FAIL
   '1:2:3:4:5:6:7:8 IPv4 IP required'
   INFO
   WARN

[ 1.2.3.4 1:2:3:4:5:6:7:8 ] { ipv4 { negate 1 } }
   =>
   PASS
   1:2:3:4:5:6:7:8
   FAIL
   '1.2.3.4 Non-IPv4 IP required'
   INFO
   WARN

[ 1.2.3.4 1:2:3:4:5:6:7:8 ] { ipv6 __undef__ }
   =>
   PASS
   1:2:3:4:5:6:7:8
   FAIL
   '1.2.3.4 IPv6 IP required'
   INFO
   WARN

[ 1.2.3.4 1:2:3:4:5:6:7:8 ] { ipv6 { negate 1 } }
   =>
   PASS
   1.2.3.4
   FAIL
   '1:2:3:4:5:6:7:8 Non-IPv6 IP required'
   INFO
   WARN

[ 1.2.3.4 ] { in_network { network 1:2:3:4:5:6:7:0/100 } }
   =>
   PASS
   FAIL
   '1.2.3.4 in_network and IP must both be IPv4 or IPv6'
   INFO
   WARN

[ 1.2.3.4 ] { in_network { network foo.bar.com } }
   =>
   PASS
   FAIL
   '1.2.3.4 in_network must be a valid IP'
   INFO
   WARN

[ 1.2.3.4 ] { in_network { network 1.2.3.5 } }
   =>
   PASS
   FAIL
   '1.2.3.4 in_network must be a valid network IP'
   INFO
   WARN

[ 1.2.3.4 10.20.30.40 ] { in_network { network 1.2.3.0/24 } }
   =>
   PASS
   1.2.3.4
   FAIL
   '10.20.30.40 IP not in network'
   INFO
   WARN

[ 1.2.3.4 10.20.30.40 ] { in_network { network 1.2.3.0/24 negate 1 } }
   =>
   PASS
   10.20.30.40
   FAIL
   '1.2.3.4 IP contained in network'
   INFO
   WARN

[ 1.2.3.4 ] { network_ip __undef__ }
   =>
   PASS
   FAIL
   '1.2.3.4 IP must include network information for network/broadcast check'
   INFO
   WARN

[ 1.2.3.0/24 1.2.3.10/24 1.2.3.255/24 ] { network_ip __undef__ }
   =>
   PASS
   1.2.3.0/24
   FAIL
   '1.2.3.10/24 Network IP required'
   '1.2.3.255/24 Network IP required'
   INFO
   WARN

[ 1.2.3.0/24 1.2.3.10/24 1.2.3.255/24 ] { broadcast_ip __undef__ }
   =>
   PASS
   1.2.3.255/24
   FAIL
   '1.2.3.0/24 Broadcast IP required'
   '1.2.3.10/24 Broadcast IP required'
   INFO
   WARN

);

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:


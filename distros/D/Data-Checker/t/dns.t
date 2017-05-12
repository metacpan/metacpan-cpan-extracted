#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'DNS tests';
}

$testdir = '';
$testdir = $t->testdir();

$t->use_ok("Net::DNS",'feature');
$t->skip_all('DNS tests ignored (install Net::DNS to test)','Net::DNS');

use Data::Checker;
$obj   = new Data::Checker;

# Net::DNS fails with some versions:
#   Okay: 0.74 0.77 0.78 0.80 (?)
#   Fail: 0.75 0.76 0.79

my $v    = $Net::DNS::VERSION;
my $fail = 1  if ( ($v >= 0.75  &&  $v < 0.77)  ||  ($v >= 0.79  &&  $v < 0.80) );
$t->skip_all('Net::DNS tests skipped for this version of Net::DNS')  if ($fail);

sub test {
   my($data,$opts) = @_;
   my($pass,$fail,$info,$warn) = $obj->check($data,"DNS",$opts);
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

[ foo bar foo.com bar.com 100.101.0.103 ] { qualified __undef__ }
   =>
   PASS
   bar.com
   foo.com
   FAIL
   '100.101.0.103 Only hostnames can be check with qualified'
   'bar Host is not fully qualified'
   'foo Host is not fully qualified'
   INFO
   WARN

[ foo bar foo.com bar.com ] { qualified { negate 1 } }
   =>
   PASS
   bar
   foo
   FAIL
   'bar.com Host is fully qualified'
   'foo.com Host is fully qualified'
   INFO
   WARN

[ iana.org xyzxyz.iana.org ]
   =>
   PASS
   iana.org
   FAIL
   'xyzxyz.iana.org Host is not defined in DNS'
   INFO
   WARN

[ iana.org xyzxyz.iana.org ] { dns __undef__ }
   =>
   PASS
   iana.org
   FAIL
   'xyzxyz.iana.org Host is not defined in DNS'
   INFO
   WARN

[ iana.org xyzxyz.iana.org ] { dns { negate 1 } }
   =>
   PASS
   xyzxyz.iana.org
   FAIL
   'iana.org Host is already in DNS'
   INFO
   WARN

{ iana.org { ip [ 192.0.43.8 ] } blackhole-1.iana.org { ip [ 1.2.3.4 ] } }
{ dns __undef__ expected_ip __undef__ }
   =>
   PASS
   iana.org
   FAIL
   'blackhole-1.iana.org DNS ip value does not match expected value'
   INFO
   WARN

[ blackhole-1.iana.org www.ufl.edu ]
{ dns __undef__ expected_domain { value iana.org } }
   =>
   PASS
   blackhole-1.iana.org
   FAIL
   'www.ufl.edu DNS domain value does not match expected value'
   INFO
   WARN

{ blackhole-1.iana.org { domain iana.org } blackhole-2.iana.org { domain [ iana.org perl.com ] } prisoner.iana.org { domain perl.com } }
{ dns __undef__ expected_domain __undef__ }
   =>
   PASS
   blackhole-1.iana.org
   blackhole-2.iana.org
   FAIL
   'prisoner.iana.org DNS domain value does not match expected value'
   INFO
   WARN

[ 207.171.7.91 ]
{ nameservers 128.227.30.254 }
   =>
   PASS
   207.171.7.91
   FAIL
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


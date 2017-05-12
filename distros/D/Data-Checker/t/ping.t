#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Ping tests';
}

$testdir = '';
$testdir = $t->testdir();

$t->use_ok("Net::Ping::External",'feature');
$t->skip_all('Ping tests ignored (install Net::Ping::External to test)','Net::Ping::External');

use Data::Checker;
$obj   = new Data::Checker;

# Don't run tests for installs
unless ($ENV{RELEASE_TESTING}) {
   $t->skip_all("PING testing: disabled for installation");   
}

sub test {
   my($data,$opts) = @_;
   my($pass,$fail,$info,$warn) = $obj->check($data,"Ping",$opts);
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

[ cpansearch.perl.org aaa.bbb.ccc ] { external __undef__ }
   =>
   PASS
   cpansearch.perl.org
   FAIL
   'aaa.bbb.ccc Host does not respond to external pings'
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


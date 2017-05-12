#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'Date tests';
$testdir = '';
$testdir = $t->testdir();

$t->use_ok("Date::Manip",'feature');
$t->skip_all('Date tests ignored (install Date::Manip to test)','Date::Manip');

use Data::Checker;
$obj   = new Data::Checker;

sub test {
   my($data,$opts) = @_;
   my($pass,$fail,$info,$warn) = $obj->check($data,"Date",$opts);
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

[ now 2016-01-01-12:00:00 some-string ] { }
   =>
   PASS
   2016-01-01-12:00:00
   now
   FAIL
   'some-string Not a valid date'
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


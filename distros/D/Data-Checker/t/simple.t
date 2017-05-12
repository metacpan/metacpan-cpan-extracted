#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'simple function';
$testdir = '';
$testdir = $t->testdir();

use Data::Checker;
$obj   = new Data::Checker;

sub mycheck {
   my($obj,$ele,$desc,$opts) = @_;
   my(@err,@info,@warn);

   if ($ele =~ /e/) {
      push(@err,"Error in $ele");
   }
   if ($ele =~ /i/) {
      push(@info,"Info for $ele");
   }
   if ($ele =~ /w/) {
      push(@warn,"Warn about $ele");
   }
   return ($ele,\@err,\@warn,\@info);
}

sub test {
   my($data) = @_;
   my($pass,$fail,$warn,$info) = $obj->check($data,\&mycheck);
   my @out = ("PASS",(sort @$pass));

   push(@out,"FAIL");
   foreach my $ele (sort keys %$fail) {
      push(@out,@{ $$fail{$ele} });
   }

   push(@out,"INFO");
   foreach my $ele (sort keys %$info) {
      push(@out,@{ $$info{$ele} });
   }

   push(@out,"WARN");
   foreach my $ele (sort keys %$warn) {
      push(@out,@{ $$warn{$ele} });
   }

   return @out;
}

$tests=q(

[ az ez iz wz eiz ewz iwz eiwz ] =>
   PASS
   az
   iwz
   iz
   wz
   FAIL
   'Error in eiwz'
   'Error in eiz'
   'Error in ewz'
   'Error in ez'
   INFO
   'Info for eiwz'
   'Info for eiz'
   'Info for iwz'
   'Info for iz'
   WARN
   'Warn about eiwz'
   'Warn about ewz'
   'Warn about iwz'
   'Warn about wz'

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


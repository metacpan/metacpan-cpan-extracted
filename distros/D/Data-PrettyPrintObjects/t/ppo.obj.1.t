#!/usr/bin/perl -w

our $t;
BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'objects';
}

$testdir = '';
$testdir = $t->testdir();

BEGIN { $t->use_ok('Date::Manip::Date','feature'); }
BEGIN { $t->use_ok('Archive::Zip','feature'); }

$t->skip_all('Date::Manip 6.xx required','Date::Manip::Date');
$t->skip_all('Archive::Zip required','Archive::Zip');

use Data::PrettyPrintObjects;

$date = new Date::Manip::Date;
$date->parse('2010-01-01 00:00:00');
$zip  = new Archive::Zip;
$foo  = new PPOtest;

sub test {
  my($var) = @_;
  $out = PPO($var);

  my $i = 0;
  while ($out =~ /(0x[0-9a-f]{2,})/) {
    my $ref = $1;
    my $rep = '1x' . sprintf('%06x',$i++);
    $out    =~ s/$ref/$rep/g;
  }
  return $out;
}

@tests = ();
@exp   = ();

push @tests, [ { 'date' => $date, 'foo' => $foo, 'zip' => $zip } ];
push @exp,   [
"{
  date => Date::Manip::Date=HASH(1x000000),
  foo  => PPOtest=HASH(1x000001),
  zip  => Archive::Zip::Archive=HASH(1x000002)
}
"];


$t->tests(func     => \&test,
          tests    => \@tests,
          expected => \@exp);
$t->done_testing();

package PPOtest;

sub new {
   my $self = { 'a' => 'foo',
                'b' => 'bar' };
   bless $self;
   return $self;
}

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: -2
#End:


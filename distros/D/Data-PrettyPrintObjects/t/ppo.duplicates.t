#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'duplicates';
$testdir = '';
$testdir = $t->testdir();

use Data::PrettyPrintObjects;

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

$list1 = ['a','b'];

push(@tests, [ [ $list1, $list1 ] ]);
push(@exp,   ["[
  [
    a,
    b
  ],
  \$VAR->[0]
]
"]);

$list1 = ['c','d'];
push(@$list1,$list1);
push(@exp,   ["[
  c,
  d,
  \$VAR
]
"]);

push(@tests, [ $list1 ]);

$t->tests(func     => \&test,
          tests    => \@tests,
          expected => \@exp);
$t->done_testing();

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


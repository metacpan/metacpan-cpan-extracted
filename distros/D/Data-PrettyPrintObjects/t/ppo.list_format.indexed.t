#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'list_format=indexed';
$testdir = '';
$testdir = $t->testdir();

use Data::PrettyPrintObjects;

PPO_Options('list_format' => 'indexed');

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

## Scalars

push @tests, ["abc"];
push @exp,   ["abc\n"];

push @tests, ["ab'c"];
push @exp,   ["'ab'c'\n"];

push @tests, [" abc"];
push @exp,   ["' abc'\n"];

push @tests, ["abc\n"];
push @exp,   ["'abc\\n'\n"];

push @tests, ["abc\n\n\n"];
push @exp,   ["'abc\\n\\n\\n'\n"];

push @tests, [undef];
push @exp,   ["undef\n"];

push @tests, [''];
push @exp,   ["''\n"];

## Hashes

push @tests, [ { 'a' => 1, 'b' => 2 } ];
push @exp,   [
"{
  a => 1,
  b => 2
}
"];

push @tests, [ { 'a' => 1, 'b' => { 'c' => 2, 'd' => 3 } } ];
push @exp,   [
"{
  a => 1,
  b => {
    c => 2,
    d => 3
  }
}
"];

## Lists

push @tests, [ [ 'a', 'b' ] ];
push @exp,   [
"[
  0: a,
  1: b
]
"];

push @tests, [ [ 'a', [ 'b', 'c' ] ] ];
push @exp,   [
"[
  0: a,
  1: [
    0: b,
    1: c
  ]
]
"];

## Nested

push @tests, [ [ 'a', { 'b' => 1, 'c' => 2 } ] ];
push @exp,   [
"[
  0: a,
  1: {
    b => 1,
    c => 2
  }
]
"];

push @tests, [ { 'a' => 1, 'b' => [ 'c', 'd' ] } ];
push @exp,   [
"{
  a => 1,
  b => [
    0: c,
    1: d
  ]
}
"];

## Deep

push @tests, [ [ 'a', [ 'b', [ 'c', [ 'd' ] ] ] ] ];
push @exp,   [
"[
  0: a,
  1: [
    0: b,
    1: [
      0: c,
      1: [
        0: d
      ]
    ]
  ]
]
"];



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


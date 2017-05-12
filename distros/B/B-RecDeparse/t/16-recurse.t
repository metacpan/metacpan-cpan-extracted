#!perl -T

use strict;
use warnings;

use Test::More tests => 3 * 2 * 5;

use B::RecDeparse;

my @brds = map [ B::RecDeparse->new(level => $_), $_ ], 0, 1, 2, 5, -1;

sub fact {
 my $n = shift;

 if ($n > 0) {
  $n * fact($n - 1);
 } else {
  return 0;
 }
}

my $exp_fact = <<'EXP';
if ($n > 0) {
  $n * fact($n - 1);
}
else {
  return 0;
}
EXP

sub foo { bar($_[0] + 1) }

sub bar { foo($_[0] - 1) }

my $exp_foo0 = <<'EXP';
bar($_[0] + 1);
EXP

my $exp_foo1 = <<'EXP';
sub {
  foo($_[0] - 1);
}->($_[0] + 1);
EXP

my $exp_bar0 = <<'EXP';
foo($_[0] - 1);
EXP

my $exp_bar1 = <<'EXP';
sub {
  bar($_[0] + 1);
}->($_[0] - 1);
EXP

my @tests = (
 [ \&fact, [ $exp_fact            ], 'fact' ],
 [ \&foo,  [ $exp_foo0, $exp_foo1 ], 'foo'  ],
 [ \&bar,  [ $exp_bar0, $exp_bar1 ], 'bar'  ],
);

for (@tests) {
 my ($code, $exps, $desc) = @$_;

 s/^\s*//mg, s/\s*$//mg, $_ = qr/\Q$_\E/ for @$exps;

 for my $i (0 .. $#brds) {
  my ($brd, $level) = @{$brds[$i]};

  my $exp = $exps->[$i];
  $exp    = $exps->[-1] unless defined $exp;

  my $body = eval {
   $brd->coderef2text($code);
  };
  is $@, '', "deparsing $desc at level $level doesn't croak";

  s/^\s*//mg, s/\s*$//mg for $body;

  like $body, qr/$exp/, "deparsing $desc at level $level correctly";
 }
}

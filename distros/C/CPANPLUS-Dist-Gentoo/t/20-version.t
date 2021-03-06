#!perl -T

use strict;
use warnings;

use Test::More tests => 3 + (2 + 2 * 3) * (69 + 4 * 7);

use CPANPLUS::Dist::Gentoo::Version;

sub V () { 'CPANPLUS::Dist::Gentoo::Version' }

eval { V->new() };
like $@, qr/You\s+must\s+specify\s+a\s+version\s+string/, "V->(undef)";

eval { V->new('dongs') };
like $@, qr/Couldn't\s+parse\s+version\s+string/, "V->('dongs')";

eval { my $res = 'dongs' < V->new(1) };
like $@, qr/Couldn't\s+parse\s+version\s+string/, "'dongs' < V->new(1)";

my @tests = (
 [ 0, 0 =>  0 ],
 [ 1, 0 =>  1 ],
 [ 1, 1 =>  0 ],

 [ '00',  '0'  => 0 ],
 [ '01',  '1'  => 0 ],
 [ '001', '1'  => 0 ],
 [ '001', '01' => 0 ],

 [ '1.0',   1       =>  1 ], # Yes, 1.0 > 1. Deal with it
 [ '1.0',   '1.0'   =>  0 ],
 [ '1.1',   1       =>  1 ],
 [ '1.1',   '1.0'   =>  1 ],
 [ '1.1',   '1.1'   =>  0 ],
 [ '1.1',   '1.10'  => -1 ],
 [ '1.1',   '1.01'  =>  1 ],
 [ '1.1',   '1.010' =>  1 ],
 [ '1.01',  '1.010' =>  0 ],

 [ '1.0.0',  1         =>  1 ], # Ditto
 [ '1.0.0',  '1.0'     =>  1 ], # Tritto
 [ '1.0.0',  '1.0.0'   =>  0 ],
 [ '1.0.1',  '1.1'     => -1 ],
 [ '1.0.1',  '1.0.0'   =>  1 ],
 [ '1.0.1',  '1.0.1'   =>  0 ],
 [ '1.0.1',  '1.0.10'  => -1 ],
 [ '1.0.1',  '1.0.01'  =>  1 ],
 [ '1.0.1',  '1.0.010' =>  1 ],
 [ '1.0.01', '1.0.010' =>  0 ],

 [ '1a',    1        =>  1 ],
 [ '1.0a',  1        =>  1 ],
 [ '1.0',   '1a'     =>  1 ], # Same
 [ '1a',    '1b'     => -1 ],
 [ '1.1a',  '1.0b'   =>  1 ],
 [ '1.1a',  '1.01a'  =>  1 ],
 [ '1.01a', '1.010a' =>  0 ],

 map( {
  [ '1.0',        "1.0_${_}"  =>  1 ],
  [ '1.0a',       "1.0_${_}"  =>  1 ],
  [ '1.0',        "1.0_${_}1" =>  1 ],
  [ "1.0_${_}1",  "1.0_${_}1" =>  0 ],
  [ "1.0_${_}1",  "1.0_${_}2" => -1 ],
  [ "1.0a_${_}1", "1.0_${_}2" =>  1 ],
  [ "1.1_${_}1",  "1.0_${_}2" =>  1 ],
 } qw(alpha beta pre rc)),

 [ '1.0',     '1.0_p0' => -1 ],
 [ '1.0',     '1.0_p1' => -1 ],
 [ '1.0_p',   '1.0_p0' =>  0 ],
 [ '1.0a',    '1.0_p'  =>  1 ],
 [ '1.0',     '1.0_p1' => -1 ],
 [ '1.0_p1',  '1.0_p1' =>  0 ],
 [ '1.0_p1',  '1.0_p2' => -1 ],
 [ '1.0a_p1', '1.0_p2' =>  1 ],
 [ '1.1_p1',  '1.0_p2' =>  1 ],

 [ '1.0_alpha1', '1.0_beta1' => -1 ],
 [ '1.0_beta1',  '1.0_pre1'  => -1 ],
 [ '1.0_pre1',   '1.0_rc1'   => -1 ],
 [ '1.0_rc1',    '1.0'       => -1 ],

 [ '1.0_alpha', '1.0_alpha_alpha' =>  1 ],
 [ '1.0_beta',  '1.0_beta_beta'   =>  1 ],
 [ '1.0_pre',   '1.0_pre_pre'     =>  1 ],
 [ '1.0_rc',    '1.0_rc_rc'       =>  1 ],
 [ '1.0_p',     '1.0_p_p'         => -1 ],

 [ '1.0_alpha',    '1.0_alpha_p'     => -1 ],
 [ '1.0_beta',     '1.0_alpha_beta'  =>  1 ],
 [ '1.0_beta',     '1.0_alpha_p'     =>  1 ],
 [ '1.0_pre1_rc2', '1.0_pre1_rc2'    =>  0 ],
 [ '1.0_pre1_rc2', '1.0_pre1_rc3'    => -1 ],

 [ '1.0',    '1.0-r0' =>  0 ],
 [ '1.0',    '1.0-r1' => -1 ],
 [ '1.0-r1', '1.0-r1' =>  0 ],
 [ '1.0-r1', '1.0-r2' => -1 ],
 [ '1.1-r1', '1.0-r2' =>  1 ],

 [ '1.2_p0-r0',      '1.2_p',             0 ],
 [ '1.2_p1-r1',      '1.2_p1',            1 ],
 [ '1.2_p1-r1',      '1.2_p1_p1',        -1 ],
 [ '1.2_p1_pre2-r1', '1.2_p1-r1',        -1 ],
 [ '1.2_p1_pre2-r1', '1.2_p1_beta3-r1',   1 ],
 [ '1.2_p1_pre2-r1', '1.2_p1_beta3-r4',   1 ],
 [ '1.2_p1_pre2-r1', '1.2_p2_beta3-r4',  -1 ],
 [ '1.2_p1_pre2-r1', '1.2a_p1_beta3-r1', -1 ],
);

sub compare_ok {
 my ($a, $cmp, $b, $exp) = @_;

 my $desc = join " $cmp ", map { ref() ? "V->new('$_')" : "'$_'" } $a, $b;

 my ($err, $c);
 {
  local $@;
  $c   = eval "\$a $cmp \$b";
  $err = $@;
 }

 if (ref $exp eq 'Regexp') {
  like $err, $exp, "$desc should fail";
 } elsif ($err) {
  fail "$desc failed but shouldn't: $err";
 } else {
  is $c, $exp, "$desc == '$exp'";
 }
}

for (@tests) {
 my ($s1, $s2, $exp) = @$_;

 my $v1 = eval { V->new($s1) };
 is $@, '', "'$s1' parses fine";

 my $v2 = eval { V->new($s2) };
 is $@, '', "'$s2' parses fine";

 for my $r (0 .. 1) {
  if ($r) {
   ($v1, $v2) = ($v2, $v1);
   ($s1, $s2) = ($s2, $s1);
   $exp = -$exp;
  }

  compare_ok($v1, '<=>', $v2, $exp);
  compare_ok($v1, '<=>', $s2, $exp);
  compare_ok($s1, '<=>', $v2, $exp);
 }
}

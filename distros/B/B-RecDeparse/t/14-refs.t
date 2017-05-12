#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * (4 + 3) * 4;

use B::RecDeparse;

{
 BEGIN {
  strict->unimport('vars') if "$]" >= 5.021;
 }
 sub dummy { }
 sub add { $_[0] + $_[1] }
 sub call ($$$) { my $x = \&dummy; $_[0]->($_[1], $_[2]) }
 sub foo { call(\&add, $_[0], 1); }
 sub bar { my $y = \&call; $y->(\&add, $_[0], 1); }
}

sub which {
 my ($brd, $coderef, $yfunc, $yref, $nfunc, $nref, $l) = @_;
 my $code = $brd->coderef2text($coderef);
 for (@$yfunc) {
  like($code, qr/\b(?<!\\&)$_\b/, "expansion at level $l contains the function $_");
 }
 for (@$yref) {
  like($code, qr/\b(?<=\\&)$_\b/, "expansion at level $l contains the ref $_");
 }
 for (@$nfunc) {
  unlike($code, qr/\b(?<!\\&)$_\b/, "expansion at level $l does not contain the function $_");
 }
 for (@$nref) {
  unlike($code, qr/\b(?<=\\&)$_\b/, "expansion at level $l does not contain the ref $_");
 }
 $code = eval 'sub ' . $code;
 is($@, '', "result compiles at level $l");
 is_deeply( [ defined $code, ref $code ], [ 1, 'CODE' ], "result compiles to a code reference at level $l");
 is($code->(2), $coderef->(2), "result compiles to the good thing at level $l");
}

my $bd_args = '-sCi0v1';

my $brd = B::RecDeparse->new(deparse => $bd_args, level => -1);
which $brd, \&foo, [ ], [ qw<add dummy> ], [ qw<add call> ], [ ], -1;
which $brd, \&bar, [ ], [ qw<add call> ], [ qw<add call> ], [ ], -1;

$brd = B::RecDeparse->new(deparse => $bd_args, level => 0);
which $brd, \&foo, [ qw<call> ], [ qw<add> ], [ qw<add> ], [ qw<dummy> ], 0;
which $brd, \&bar, [ ], [ qw<add call> ], [ qw<add> ], [ qw<dummy> ], 0;

$brd = B::RecDeparse->new(deparse => $bd_args, level => 1);
which $brd, \&foo, [ ], [ qw<add dummy> ], [ qw<add call> ], [ ], 1;
which $brd, \&bar, [ ], [ qw<add call> ], [ qw<add call> ], [ ], 1;

$brd = B::RecDeparse->new(deparse => $bd_args, level => 2);
which $brd, \&foo, [ ], [ qw<add dummy> ], [ qw<add call> ], [ ], 2;
which $brd, \&bar, [ ], [ qw<add call> ], [ qw<add call> ], [ ], 2;

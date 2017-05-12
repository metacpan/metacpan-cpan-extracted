#!perl -T

use strict;
use warnings;

use Test::More tests => (3 + 3) * 5 + 1;

use B::RecDeparse;

sub add { $_[0] + $_[1] }
sub mul { $_[0] * $_[1] }
sub fma { add mul($_[0], $_[1]), $_[2] }
sub wut { fma $_[0], 2, $_[1] }

sub which {
 my ($brd, $yes, $no, $l) = @_;
 my $code = $brd->coderef2text(\&wut);
 for (@$yes) {
  like($code, qr/\b$_\b/, "expansion at level $l contains $_");
 }
 for (@$no) {
  unlike($code, qr/\b$_\b/, "expansion at level $l does not contain $_");
 }
 $code = eval 'sub ' . $code;
 is($@, '', "result compiles at level $l");
 is_deeply( [ defined $code, ref $code ], [ 1, 'CODE' ], "result compiles to a code reference at level $l");
 is($code->(1, 3), wut(1, 3), "result compiles to the good thing at level $l");
}

my $bd_args = '-sCi0v1';

my $brd = B::RecDeparse->new(deparse => [ $bd_args ], level => -1);
which $brd, [ ], [ qw<add mul fma> ], -1;

$brd = B::RecDeparse->new(deparse => [ $bd_args ], level => 0);
which $brd, [ qw<fma> ], [ qw<add mul> ], 0;

$brd = B::RecDeparse->new(deparse => [ $bd_args ], level => 1);
which $brd, [ qw<add mul> ], [ qw<fma> ], 1;

$brd = B::RecDeparse->new(deparse => [ $bd_args ], level => 2);
which $brd, [ ], [ qw<add mul fma> ], 2;

$brd = B::RecDeparse->new(deparse => [ $bd_args ], level => 3);
which $brd, [ ], [ qw<add mul fma> ], 2;

sub fakegv { return @_ }
eval { $brd->coderef2text(sub { return fakegv() }) };
is($@, '', 'don\'t croak on non-CV GV\'s at level >= 1');

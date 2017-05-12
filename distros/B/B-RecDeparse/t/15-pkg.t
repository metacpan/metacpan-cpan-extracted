#!perl -T

use strict;
use warnings;

use Test::More tests => (3 + 3) * 5;

use B::RecDeparse;

sub wut { Dongs::fma($_[0], 2, $_[1]) }
sub Dongs::fma { Hlagh::add(main::mul($_[0], $_[1]), $_[2]) }
sub Hlagh::add { $_[0] + $_[1] }
sub mul ($$) { $_[0] * $_[1] }

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
which $brd, [ ], [ qw<Hlagh::add mul Dongs::fma> ], -1;

$brd = B::RecDeparse->new(deparse => [ $bd_args ], level => 0);
which $brd, [ qw<fma> ], [ qw<Hlagh::add mul> ], 0;

$brd = B::RecDeparse->new(deparse => [ $bd_args ], level => 1);
which $brd, [ qw<add mul> ], [ qw<Dongs::fma> ], 1;

$brd = B::RecDeparse->new(deparse => [ $bd_args ], level => 2);
which $brd, [ ], [ qw<Hlagh::add mul Dongs::fma> ], 2;

$brd = B::RecDeparse->new(deparse => [ $bd_args ], level => 3);
which $brd, [ ], [ qw<Hlagh::add mul Dongs::fma> ], 2;

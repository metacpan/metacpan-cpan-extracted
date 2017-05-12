#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

use B::RecDeparse;

my $brd = B::RecDeparse->new;
ok(defined $brd, 'BRD object is defined');
is(ref $brd, 'B::RecDeparse', 'BRD object is valid');
ok($brd->isa('B::Deparse'), 'BRD is a BD');

my $brd2 = $brd->new;
ok(defined $brd2, 'BRD::new called as an object method works' );
is(ref $brd2, 'B::RecDeparse', 'BRD::new called as an object method works is valid');
ok($brd2->isa('B::Deparse'), 'BRD is a BD');

my $brd3 = B::RecDeparse::new();
ok(defined $brd3, 'BRD::new called as a function works ');
is(ref $brd3, 'B::RecDeparse', 'BRD::new called as a functions returns a B::RecDeparse object');
ok($brd3->isa('B::Deparse'), 'BRD is a BD');

eval { $brd2 = B::RecDeparse->new(qw<a b c>) };
like($@, qr/Optional\s+arguments/, 'BRD::new gets parameters as key => value pairs');

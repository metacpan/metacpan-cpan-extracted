#!perl

use strict;
use warnings;

use Chess::FIDE;
use Test::More tests => 3;

use Net::Ping;

my $fide = Chess::FIDE->new();
isa_ok($fide, 'Chess::FIDE');
is_deeply($fide, {meta => {}, players => [],}, "empty object");
$fide = Chess::FIDE->new(
	-www => 1,
	-url => 'http://non-existing-url.somewhere/nothing',
);
is($fide, 0, "failure expected at unreachable address");

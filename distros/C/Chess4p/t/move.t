# -*- mode: cperl -*-

use v5.36;

use Test::More;

use utf8;

use Config;
skip_all('Only 64 bit systems are supported.') unless $Config{ptrsize} && $Config{ptrsize} == 8;

require Chess4p;


use Chess4p::Common qw(E2 E4 F4 F7 F8);


my $move = Chess4p::Move->new(E2, E4);

ok(defined $move, 'move was created');
is($move->from(), E2, 'correct from');
is($move->to(), E4, 'correct to');
is($move->uci(), 'e2e4', 'uci = e2e4');

$move = Chess4p::Move->new(F7, F8, 'Q');
ok(defined $move, 'move was created');
is($move->from(), F7, 'correct from');
is($move->to(), F8, 'correct to');
is($move->promotion(), 'Q', 'correct promotion piece');
is($move->uci(), 'f7f8q', 'uci = f7f8q');

my $str = "$move";
is($str, 'f7f8q', 'Move stringified');



done_testing;

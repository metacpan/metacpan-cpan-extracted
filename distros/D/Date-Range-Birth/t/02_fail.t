use strict;
use Test::More 'no_plan';

use Date::Simple;
use Date::Range::Birth;

my @fail = (
    24, '2001-00-00', qr/date should be given/,
    'foo', undef, qr/invalid argument/,
    [ 24, 25, 26 ], undef, qr/invalid number/,
);

while (my($age, $date, $ex) = splice(@fail, 0, 3)) {
    eval {
	my $range = Date::Range::Birth->new($age, $date);
    };
    like $@, $ex, $@;
}


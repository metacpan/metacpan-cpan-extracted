
use Test::More 'no_plan';
use Data::Dumper;

use_ok('Algorithm::Voting::Plurality');
use_ok('Algorithm::Voting::Ballot');

my $ballot = sub {
    return Algorithm::Voting::Ballot->new($_[0]);
};

my $box = Algorithm::Voting::Plurality->new();
ok($box);

ok($box->add($ballot->('frank')));
is($box->count,1);

ok($box->add($ballot->('mary')));
is($box->count,2);

ok($box->add($ballot->('frank')));
is($box->count,3);

ok($box->add($ballot->('mary')));
is($box->count,4);

ok($box->add($ballot->('frank')));
is($box->count,5);

is_deeply($box->tally, { frank => 3, mary => 2 }) or diag(Dumper($box));

is_deeply([$box->result], [[3, 'frank'], [2, 'mary']],'known result')
    or diag(Dumper([$box->result]));

my $s = $box->as_string;

like($s, qr/1: frank, 3 votes/);
like($s, qr/2: mary, 2 votes/);


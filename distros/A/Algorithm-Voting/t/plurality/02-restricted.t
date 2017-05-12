
use Test::More 'no_plan';
use Test::Exception;

use_ok('Algorithm::Voting::Plurality');
use_ok('Algorithm::Voting::Ballot');

my $ballot = sub {
    return Algorithm::Voting::Ballot->new($_[0]);
};

my $box = Algorithm::Voting::Plurality->new( candidates => [qw/ frank mary judy /] );
ok($box);

ok($box->add($ballot->('frank')));
is($box->count,1);

ok($box->add($ballot->('mary')));
is($box->count,2);

ok($box->add($ballot->('judy')));
is($box->count,3);

ok($box->add($ballot->('mary')));
is($box->count,4);

ok($box->add($ballot->('frank')));
is($box->count,5);

# try to insert an invalid ballot
dies_ok { $box->add($ballot->('steve')) } 'dies on invalid candidate';
is($box->count,5);

is_deeply($box->tally, {frank => 2, mary => 2, judy => 1});

my @r = $box->result;
is($r[0][0], 2);
is_deeply([ sort @{$r[0]}[1,2] ], [qw/frank mary/]);
is($r[1][0], 1);
is($r[1][1], 'judy');

my $s = $box->as_string;
like($s, qr/2: judy, 1 /) or diag($s);


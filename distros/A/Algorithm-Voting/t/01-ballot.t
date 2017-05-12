#!perl -T

use Test::More tests => 3;

use_ok('Algorithm::Voting::Ballot');

{
    my $ballot = Algorithm::Voting::Ballot->new('Fred');
    is($ballot->candidate, 'Fred');
}

{
    my $ballot = Algorithm::Voting::Ballot->new(candidate => 'Larry');
    is($ballot->candidate, 'Larry');
}


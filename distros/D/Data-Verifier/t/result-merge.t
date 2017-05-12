use strict;
use Test::More;

use Data::Verifier;

my $verifier = Data::Verifier->new(
    profile => {
        name    => {
            required => 1
        },
        grade   => {
            required => 1,
            type => 'Int'
        },
        location => {
            type => 'Str'
        }
    }
);
my $results = $verifier->verify({
    grade => 'abc',
    location => 'TN'
});

my $verifier2 = Data::Verifier->new(
    profile => {
        position    => {
            required => 1,
        },
        rank        => {
            type => 'Int'
        },
        serial => {
            type => 'Str'
        }
    }
);
my $results2 = $verifier2->verify({
    rank => 'abc',
    serial => 'abc123'
});

$results->merge($results2);

ok($results->is_missing('name'), 'name missing');
ok($results->is_missing('position'), 'position missing');
ok($results->is_invalid('grade'), 'grade invalid');
ok($results->is_invalid('rank'), 'rank invalid');
cmp_ok($results->get_value('location'), 'eq', 'TN', 'get_value location');
cmp_ok($results->get_value('serial'), 'eq', 'abc123', 'get_value serial');

is_deeply( [$results->get_values('location', 'serial')], ['TN', 'abc123'], '"get_values" method');

done_testing;
use strict;
use Test::More;

use Data::Verifier;
use Moose::Util::TypeConstraints;

{
    my $verifier = Data::Verifier->new(
        profile => {
            age    => {
                type => 'Int'
            },
            age2    => {
                type => 'Int',
            },
            deep_hash => { type => 'HashRef' },
        }
    );

    my $results = $verifier->verify({
        age => 'foo',
        age2 => '12',
        deep_hash => { foo => { bar => { baz => 'buzz' } } },
    });

    ok(!$results->success, 'failed');
    cmp_ok($results->invalid_count, '==', 1, '1 invalid');
    ok(defined($results->is_invalid('age')), 'age is invalid');
    ok(!defined($results->get_value('age')), 'get_value(age) is undefined');
    cmp_ok($results->get_value('age2'), '==', 12, 'get_value(age2) is 12');
}

{
    my $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Int');
    my $verifier = Data::Verifier->new(
        profile => {
            age    => {
                type => $cons
            },
        }
    );

    my $results = $verifier->verify({ age => 12 });

    ok($results->success, 'success: type using an instance of TypeConstraint');
}

done_testing;

use strict;
use Test::More;

use Data::Verifier;
use Moose::Util::TypeConstraints;

my $verifier = Data::Verifier->new(
    profile => {
        name    => {
            type => 'Str',
            required => 1,
            min_length => 3
        },
        name2 => {
            type => 'Str',
            max_length => 5
        },
        name3 => {
            type => 'Str',
            min_length => 3,
            max_length => 10
        }
    }
);

{
    my $results = $verifier->verify({ name => 'cory', name2 => 'jen', name3 => 'brenley'  });

    ok($results->success, 'all good');
}

{
    my $results = $verifier->verify({ name2 => 'jen', name3 => 'brenley'  });

    ok(!$results->success, '1 missing');
    ok($results->is_missing('name'), 'name missing');
}

{
    my $results = $verifier->verify({ name => 'g', name2 => 'jennifer', name3 => 'babybrenley'  });

    ok(!$results->success, 'all bad');
    ok($results->is_invalid('name'), 'name too short');
    ok($results->is_invalid('name2'), 'name2 too long');
    ok($results->is_invalid('name3'), 'name3 too long');
}

{
    my $results = $verifier->verify({ name => 'cory', name2 => 'jen', name3 => 'bb'  });

    ok(!$results->success, '1 invalid');
    ok(!$results->is_invalid('name'), 'name is fine');
    ok($results->is_invalid('name3'), 'name3 too short');
}

done_testing;
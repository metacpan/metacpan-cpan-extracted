use strict;
use Test::More;

use Data::Verifier;

{
    my $verifier = Data::Verifier->new(
        profile => {
            name    => {
                required => 1
            }
        }
    );

    my $results = $verifier->verify({ name => 'foo', bar => 'reject me' });

    ok($results->success, 'success');
    cmp_ok($results->valid_count, '==', 1, '1 valid');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');
    ok($results->is_valid('name'), 'name is valid');
    ok(!$results->is_valid('bar'), 'unspecified name is not valid');
    cmp_ok($results->get_value('name'), 'eq', 'foo', 'get_value');
    cmp_ok($results->get_original_value('name'), 'eq', 'foo', 'get_original_value');
}

done_testing;

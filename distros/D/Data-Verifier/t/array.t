use strict;
use Test::More;

use Data::Verifier;

{
    my $verifier = Data::Verifier->new(
        profile => {
            name    => {
                required => 1,
                type => 'ArrayRef[Str]'
            }
        }
    );

    my $results = $verifier->verify({ name => [ 'foo' ] });

    ok($results->success, 'success');
    cmp_ok($results->valid_count, '==', 1, '1 valid');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');
    is_deeply($results->get_value('name'), [ 'foo' ], 'got my name back');
    ok($results->is_valid('name'), 'name is valid');
}

{
    my $verifier = Data::Verifier->new(
        profile => {
            name    => {
                required => 1,
                type => 'ArrayRef[Str]'
            }
        }
    );

    my $results = $verifier->verify({ name => [ 'foo', 'bar' ], bar => 'reject me' });

    ok($results->success, 'success');
    cmp_ok($results->valid_count, '==', 1, '1 valid');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');
    ok(ref($results->get_value('name')) eq 'ARRAY', 'got array from name');
    ok($results->is_valid('name'), 'name is valid');
    ok(!$results->is_valid('bar'), 'unspecified name is not valid');
}

{
    my $verifier = Data::Verifier->new(
        filters => [qw(flatten)],
        profile => {
            name    => {
                required => 1,
                type => 'ArrayRef[Str]'
            }
        }
    );

    my $results = $verifier->verify({ name => [ 'foo ', 'bar ' ], bar => 'reject me' });

    my $ovalues = $results->get_original_value('name');
    cmp_ok($ovalues->[0], 'eq', 'foo ', 'first original value not filtered');
    cmp_ok($ovalues->[1], 'eq', 'bar ', 'second original value not filtered');


    my $pfvalues = $results->get_post_filter_value('name');
    cmp_ok($pfvalues->[0], 'eq', 'foo', 'first post_filter value filtered');
    cmp_ok($pfvalues->[1], 'eq', 'bar', 'second post_filter value filtered');


    my $values = $results->get_value('name');
    cmp_ok($values->[0], 'eq', 'foo', 'first value filtered');
    cmp_ok($values->[1], 'eq', 'bar', 'second value filtered');
}

done_testing;

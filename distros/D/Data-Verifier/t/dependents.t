use strict;
use Test::More;

use Data::Verifier;


my $verifier = Data::Verifier->new(
    profile => {
        username    => { length => 5 },
        password    => {
            length => 10,
            dependent => {
                password2 => {
                    required => 1,
                    length => 10
                }
            }
        }
    }
);

{
    my $results = $verifier->verify({
        username => 'foobar',
        password => 'longpassword',
        password2 => 'longpassword'
    });

    ok($results->success, 'success');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');
    cmp_ok($results->get_value('username'), 'eq', 'foobar', 'get_value username');
    cmp_ok($results->get_value('password'), 'eq', 'longpassword', 'get_value password');
}

{
    my $results = $verifier->verify({
        username => 'foobar',
    });

    ok($results->success, 'success (dependent not tripped)');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');
    cmp_ok($results->get_value('username'), 'eq', 'foobar', 'get_value username');
}

{
    my $results = $verifier->verify({
        username => 'foobar',
        password => 'longpassword'
    });

    ok(!$results->success, 'failure (dependent tripped)');
    cmp_ok($results->invalid_count, '==', 1, '1 invalid');
    cmp_ok($results->missing_count, '==', 1, '1 missing');
    cmp_ok($results->get_value('username'), 'eq', 'foobar', 'get_value username');
    ok(!defined($results->get_value('password')), 'get_value password');
}

{
    my $dv = Data::Verifier->new(
        profile => {
            id => {
                required => 1,
                type => "ArrayRef[Int]",
                dependent => {
                    comment => {
                        required => 1,
                        type => "ArrayRef[Str]",
                    },
                },
                post_check => sub {
                    my $r = shift;
                    @{ $r->get_value('id') } == @{ $r->get_value('comment') };
                },
            },
        }
    );

    ok( !$dv->verify( {} )->success, 'missing' );
    ok( $dv->verify( { id => [], comment => [] } )->success, 'success (even if [])' );
    ok( $dv->verify( { id => [qw(1 2 3)], comment => [qw(one two three)] } )->success, 'success (pairs id&comment)');
    ok( !$dv->verify( { id => [qw(1 2 3 4)], comment => [qw(one two three)] } )->success, 'invalid' );
    ok( !$dv->verify( { id => [qw(1 2 3)], comment => [qw(one two three four)] } )->success, 'invalid'  );
    ok( !$dv->verify( { id => [qw(1 2 3 four)], comment => [qw(one two three four)] } )->success, 'invalid'  );
}

done_testing;

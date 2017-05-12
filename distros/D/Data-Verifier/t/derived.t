use strict;
use Test::More;

use Data::Verifier;

# A successful verification
{
    my $verifier = Data::Verifier->new(
        profile => {
            first_name => {
                required => 1
            },
            last_name => {
                required => 1
            }
        },
        derived => {
            'full_name' => {
                required => 1,
                fields => [qw(first_name last_name)],
                deriver => sub {
                    my $r = shift;
                    return $r->get_value('first_name').' '.$r->get_value('last_name')
                }
            }
        }
    );

    my $results = $verifier->verify({ first_name => 'John', last_name => 'Anderson' });
    ok($results->success, 'success');
    cmp_ok($results->get_value('full_name'), 'eq', 'John Anderson', 'got derived field');
}

# Failed derive
{
    my $verifier = Data::Verifier->new(
        profile => {
            first_name => {
                required => 1
            },
            last_name => {
                required => 1
            }
        },
        derived => {
            'full_name' => {
                required => 1,
                fields => [qw(first_name last_name)],
                deriver => sub {
                    return undef;
                }
            }
        }
    );

    my $results = $verifier->verify({ first_name => 'John', last_name => 'Anderson' });
    ok(!$results->success, 'not successful');
    cmp_ok($results->get_field('full_name')->valid, '==', 0, 'derived field is not valid');
    cmp_ok($results->get_field('first_name')->valid, '==', 0, 'source field is not valid');
    cmp_ok($results->get_field('last_name')->valid, '==', 0, 'source field is not valid');
}

# Failed derive
{
    my $verifier = Data::Verifier->new(
        profile => {
            first_name => {
                required => 1
            },
            last_name => {
                required => 1
            }
        },
        derived => {
            'full_name' => {
                required => 0,
                fields => [qw(first_name last_name)],
                deriver => sub {
                    return undef;
                }
            }
        }
    );

    my $results = $verifier->verify({ first_name => 'John', last_name => 'Anderson' });
    ok($results->success, 'successful (!required)');
    cmp_ok($results->get_field('full_name')->valid, '==', 1, 'derived field is valid');
    cmp_ok($results->get_field('first_name')->valid, '==', 1, 'source field is valid');
    cmp_ok($results->get_field('last_name')->valid, '==', 1, 'source field is valid');
}

done_testing;
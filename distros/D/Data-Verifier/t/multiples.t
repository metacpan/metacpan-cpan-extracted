use warnings;
use strict;

use Test::More;

use Data::Verifier;
use Moose::Util::TypeConstraints;

subtype 'BlahBlahBlahNumberOver10'
    => as 'Num'
    => where { $_ > 10 };

# Plain parameterized
{
    my $verifier = Data::Verifier->new(
        profile => {
            foos => {
                type => 'ArrayRef[Str]',
            }
        }
    );

    my $results = $verifier->verify({
        foos => [
            'Foo 1',
            'Foo 2',
            'Foo 3',
            'Foo 4',
        ]
    });

    ok( $results->success, 'verification is successful' );
}

# Parameterized with real type
{
    my $verifier = Data::Verifier->new(
        profile => {
            foos => {
                type => 'ArrayRef[BlahBlahBlahNumberOver10]',
            }
        }
    );

    my $results = $verifier->verify({
        foos => [
            1,
            2,
            30,
            40,
        ]
    });

    ok( !$results->success, 'verification is not successful' );
    is_deeply(
        $results->get_value('foos'),
        [
            30,
            40
        ],
        'get_value on list returns only valids'
    );
}

# Test a member_post_check
{
    my $verifier = Data::Verifier->new(
        profile => {
            foos => {
                type => 'ArrayRef[Str]',
                member_post_check => sub {
                    my $r = shift;
                    return $r->get_value('foos') =~ /^Foo/;
                }
            }
        }
    );

    my $results = $verifier->verify({
        foos => [
            'Foo 1',
            'Foo 2',
            'Invalid on post check',
            'Foo 3',
            'Foo 4',
            5, # Invalid on type? Probably not, but whatever :)
        ]
    });

    ok( !$results->success, 'verification is not successful' );
    is_deeply(
        $results->get_value('foos'),
        [
            'Foo 1',
            'Foo 2',
            'Foo 3',
            'Foo 4',
        ],
        'get_value on list returns only valids'
    );
}

# Test a normal post-check
{
    my $verifier = Data::Verifier->new(
        profile => {
            foos => {
                type => 'ArrayRef[Str]',
                member_post_check => sub {
                    my $r = shift;
                    return $r->get_value('foos') =~ /^Foo/;
                },
                post_check => sub {
                    my $r = shift;
                    return scalar(@{ $r->get_value('foos') }) == 5
                }
            }
        }
    );

    my $results = $verifier->verify({
        foos => [
            'Foo 1',
            'Foo 2',
            'Foo 3',
            'Foo 4',
        ]
    });

    ok( !$results->success, 'verification is not successful' );
    ok(!defined($results->get_value('foos')), 'values emptied out from post_check');
}


done_testing;

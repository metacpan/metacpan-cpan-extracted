package 
    Data::Verifier::Test::Object;

use Moose;

#use overload '""' => sub { shift->value };

has 'value' => (
    is  => 'ro',
    isa => 'Str'
);

package main;

use strict;
use Test::More;

use Data::Verifier;
use Moose::Util::TypeConstraints;


{
    my %table = ( 'one' => 1, 'two' => 2, 'three' => 3 );


    coerce 'Int'
        => from 'Str'
            => via { $table{ $_ } };

    subtype 'ContrivedObject'
        => as 'Data::Verifier::Test::Object';
    coerce 'ContrivedObject'
        => from 'Str'
        => via { Data::Verifier::Test::Object->new( value => $_ ) };

    my $verifier = Data::Verifier->new(
        profile => {
            num => {
                type   => 'Int',
                coerce => 1,
            },
            object => {
                type => 'ContrivedObject',
                coerce => 1
            }
        }
    );

    my $results = $verifier->verify({ num => 'two', object => 'foo' });

    ok($results->success, 'success');
    cmp_ok($results->get_original_value('num'), 'eq', 'two', 'get_original_value');
    cmp_ok($results->get_value('num'), '==', 2, 'get_value(num) is 2');
}

{

    my $verifier = Data::Verifier->new(
        profile => {
            str => {
                type     => 'Str',
                coercion => Data::Verifier::coercion(from => 'Int', via => sub { (qw[ one two three ])[ ($_ - 1) ] }),
            },
        }
    );

    my $results = $verifier->verify({ str => 2 });

    ok($results->success, 'success');
    cmp_ok($results->get_original_value('str'), '==', 2, 'get_original_value');
    cmp_ok($results->get_value('str'), 'eq', 'two', 'get_value(str) is two');
}

done_testing;

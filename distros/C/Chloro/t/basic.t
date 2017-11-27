use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Chloro::Test::Login;
use Chloro::Types qw( Bool Str );
use List::AllUtils qw( all );

my $form = Chloro::Test::Login->new();

{
    my %fields = map { $_->name() => { $_->dump() } } $form->fields();

    is_deeply(
        \%fields, {
            username => {
                type     => Str,
                required => 1,
                secure   => 0,
            },
            password => {
                type     => Str,
                required => 1,
                secure   => 1,
            },
            remember => {
                type     => Bool,
                required => 0,
                secure   => 0,
                default  => 0,
            },
        },
        'field metadata'
    );
}

{
    my $result_set = $form->process(
        params => {
            username => 'foo',
            password => 'bar',
            remember => undef,
        }
    );

    ok(
        $result_set->is_valid(),
        'the returned result set says the form values are valid'
    );

    ok(
        ( all { $_->is_valid() } $result_set->_result_values() ),
        'all individual results are marked as valid'
    );

    is_deeply(
        $result_set->results_as_hash(), {
            username => 'foo',
            password => 'bar',
            remember => 0,
        },
        'results_as_hash returns expected values'
    );
}

{
    my $result_set = $form->process(
        params => {
            username => 'foo',
            password => 'bar',
            remember => 1,
        }
    );

    is_deeply(
        $result_set->results_as_hash(), {
            username => 'foo',
            password => 'bar',
            remember => 1,
        },
        'results_as_hash returns expected values (remember == 1)'
    );
}

{
    my $result_set = $form->process(
        params => {
            username => 'foo',
        }
    );

    ok(
        !$result_set->is_valid(),
        'result set is not valid when password is not provided'
    );

    my $pw_result = $result_set->result_for('password');

    is_deeply(
        $pw_result->param_names(),
        ['password'],
        'param_names returns expected value'
    );

    ok(
        !$pw_result->is_valid(),
        'result for password is not valid'
    );

    is_deeply(
        [
            map { $_->message()->category, $_->message()->text() }
                $pw_result->errors()
        ],
        [
            'missing',
            'The password field is required.'
        ],
        'errors for password result'
    );

    is_deeply(
        [ map { $_->result() } $pw_result->errors() ],
        [ $pw_result, ],
        'error refers back to result object'
    );
}

{
    my $result_set = $form->process(
        params => {
            username => 'foo',
            password => undef,
        }
    );

    my $pw_result = $result_set->result_for('password');

    ok(
        !$pw_result->is_valid(),
        'result for password is not valid (password is undef)'
    );

    is_deeply(
        [
            map { $_->message()->category, $_->message()->text() }
                $pw_result->errors()
        ],
        [
            'missing',
            'The password field is required.'
        ],
        'errors for password result'
    );
}

{
    my $result_set = $form->process(
        params => {
            username => 'foo',
            password => q{},
        }
    );

    my $pw_result = $result_set->result_for('password');

    ok(
        !$pw_result->is_valid(),
        'result for password is not valid (password is empty string)'
    );

    is_deeply(
        [
            map { $_->message()->category, $_->message()->text() }
                $pw_result->errors()
        ],
        [
            'missing',
            'The password field is required.'
        ],
        'errors for password result'
    );
}

{
    my $result_set = $form->process(
        params => {
            username => 'foo',
            password => [],
        }
    );

    my $pw_result = $result_set->result_for('password');

    ok(
        !$pw_result->is_valid(),
        'result for password is not valid (password is an array ref)'
    );

    is_deeply(
        [
            map { $_->message()->category, $_->message()->text() }
                $pw_result->errors(),
        ],
        [
            'invalid',
            'The password field did not contain a valid value.'
        ],
        'errors for password result'
    );
}

done_testing();

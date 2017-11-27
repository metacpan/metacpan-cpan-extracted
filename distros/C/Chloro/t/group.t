use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Chloro::Test::Address;
use Chloro::Types qw( Bool Str );
use List::AllUtils qw( all );

my $form = Chloro::Test::Address->new();

{
    my %fields = map { $_->name() => { $_->dump() } } $form->fields();

    is_deeply(
        \%fields, {
            allows_mail => {
                type     => Bool,
                required => 0,
                secure   => 0,
                default  => 1,
            },
        },
        'field metadata (does not include groups)'
    );

    my %groups = map { $_->name() => { $_->dump() } } $form->groups();

    is_deeply(
        \%groups, {
            address => {
                repetition_key => 'address_id',
                fields         => {
                    street1 => {
                        type     => Str,
                        required => 1,
                        secure   => 0,
                    },
                    street2 => {
                        type     => Str,
                        required => 0,
                        secure   => 0,
                    },
                    city => {
                        type     => Str,
                        required => 1,
                        secure   => 0,
                    },
                    state => {
                        type     => Str,
                        required => 1,
                        secure   => 0,
                    },
                },
            },
        },
        'group metadata'
    );
}

{
    my $result_set = $form->process(
        params => {
            allows_mail          => 0,
            address_id           => [ 42, 'x' ],
            'address.42.street1' => '100 Some St',
            'address.42.street2' => 'Apt C',
            'address.42.city'    => 'Minneapolis',
            'address.42.state'   => 'MN',
            'address.x.street1'  => '150 Some St',
            'address.x.street2'  => 'Apt X',
            'address.x.city'     => 'Minneapolis',
            'address.x.state'    => 'MN',
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
            allows_mail => 0,
            address     => {
                42 => {
                    street1 => '100 Some St',
                    street2 => 'Apt C',
                    city    => 'Minneapolis',
                    state   => 'MN',
                },
                x => {
                    street1 => '150 Some St',
                    street2 => 'Apt X',
                    city    => 'Minneapolis',
                    state   => 'MN',
                }
            },
            address_id => [ 42, 'x' ],
        },
        'results_as_hash returns expected values'
    );

    for my $group_result ( grep { $_->isa('Chloro::Result::Group') }
        $result_set->_result_values() ) {

        my $prefix = $group_result->prefix();

        for my $field_result ( $group_result->_result_values() ) {
            my $expect = $prefix . q{.} . $field_result->field()->name();
            is_deeply(
                $field_result->param_names(),
                [$expect],
                "got expected param_names for group result field ($expect)"
            );
        }
    }
}

{
    my $result_set = $form->process(
        params => {
            allows_mail          => 0,
            address_id           => 42,
            'address.42.street1' => '100 Some St',
            'address.42.street2' => 'Apt C',
            'address.42.city'    => 'Minneapolis',
            'address.42.state'   => 'MN',
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
            allows_mail => 0,
            address     => {
                42 => {
                    street1 => '100 Some St',
                    street2 => 'Apt C',
                    city    => 'Minneapolis',
                    state   => 'MN',
                },
            },
            address_id => [42],
        },
        'results_as_hash returns expected values'
    );
}

{
    my $result_set = $form->process(
        params => {
            allows_mail          => 0,
            address_id           => [ 42, 'x' ],
            'address.42.street1' => '100 Some St',
            'address.42.street2' => 'Apt C',
            'address.42.city'    => 'Minneapolis',
            'address.42.state'   => 'MN',
            'address.x.street1'  => undef,
            'address.x.street2'  => undef,
            'address.x.city'     => undef,
            'address.x.state'    => undef,
        }
    );

    ok(
        $result_set->is_valid(),
        'the returned result set says the form values are valid (one group is entirely empty)'
    );

    ok(
        ( all { $_->is_valid() } $result_set->_result_values() ),
        'all individual results are marked as valid'
    );

    is_deeply(
        $result_set->results_as_hash(), {
            allows_mail => 0,
            address     => {
                42 => {
                    street1 => '100 Some St',
                    street2 => 'Apt C',
                    city    => 'Minneapolis',
                    state   => 'MN',
                },
            },
            address_id => [42],
        },
        'results_as_hash returns expected values (empty group is ignored)'
    );
}

{
    my $result_set = $form->process(
        params => {
            allows_mail          => 42,
            address_id           => [ 42, 'x' ],
            'address.42.street1' => '100 Some St',
            'address.42.street2' => 'Apt C',
            'address.42.city'    => 'Minneapolis',
            'address.42.state'   => 'MN',
            'address.x.street1'  => '150 Some St',
            'address.x.street2'  => undef,
            'address.x.city'     => undef,
            'address.x.state'    => undef,
        }
    );

    ok(
        !$result_set->is_valid(),
        'the returned result set is not valid (one group is partially empty) '
    );

    my %errors = $result_set->field_errors();
    is(
        scalar keys %errors, 3,
        'three fields have errors'
    );

    ok(
        $errors{$_},
        "There is an error for the $_ field"
    ) for qw( allows_mail address.x.city address.x.state );

    ok(
        !$errors{'address.x.street2'},
        'No error for missing optional field',
    );

    is_deeply(
        _error_breakdown( \%errors ), {
            allows_mail => [
                [
                    'invalid',
                    'The allows mail field did not contain a valid value.'
                ]
            ],
            'address.x.city' => [
                [
                    'missing',
                    'The city field is required.'
                ]
            ],
            'address.x.state' => [
                [
                    'missing',
                    'The state field is required.'
                ]
            ],
        },
        'got the expected type of errors'
    );
}

done_testing();

sub _error_breakdown {
    my $errors = shift;

    my %break;

    for my $key ( keys %{$errors} ) {
        $break{$key}
            = [ map { [ $_->message()->category(), $_->message()->text() ] }
                @{ $errors->{$key} } ];
    }

    return \%break;
}

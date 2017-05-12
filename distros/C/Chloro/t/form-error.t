use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Chloro::Test::User;

my $form = Chloro::Test::User->new();

{
    my $set = $form->process(
        params => {
            username      => 'Foo',
            email_address => 'foo@example.com',
        }
    );

    ok(
        $set->is_valid(),
        'form is valid when no password fields are present'
    );
}

{
    my $set = $form->process(
        params => {
            username      => 'Foo',
            email_address => 'foo@example.com',
            password      => 'pw',
            password2     => 'pw',
        }
    );

    ok(
        $set->is_valid(),
        'form is valid when password fields match'
    );
}

{
    my $set = $form->process(
        params => {
            username      => 'Foo',
            email_address => 'foo@example.com',
            password      => 'pw',
        }
    );

    ok(
        !$set->is_valid(),
        'form is invalid when one password field is empty'
    );

    is_deeply(
        [
            map { [ $_->message()->category(), $_->message()->text() ] }
                $set->form_errors()
        ],
        [
            [
                'invalid',
                'The two password fields must match.'
            ]
        ],
        'got expected form errors'
    );
}

{
    my $set = $form->process(
        params => {
            username      => 'Foo',
            email_address => 'foo@example.com',
            password      => 'pw',
            password2     => 'bad',
        }
    );

    ok(
        !$set->is_valid(),
        'form is invalid when password fields do not match'
    );

    is_deeply(
        [
            map { [ $_->message()->category(), $_->message()->text() ] }
                $set->form_errors()
        ],
        [
            [
                'invalid',
                'The two password fields must match.'
            ]
        ],
        'got expected form errors'
    );
}

{
    my $set = $form->process(
        params => {
            username      => 'Special',
            email_address => 'foo@example.com',
            password      => 'pw',
            password2     => 'bad',
        }
    );

    ok(
        !$set->is_valid(),
        'form is invalid when password fields do not match'
    );

    is_deeply(
        [
            map { [ $_->message()->category(), $_->message()->text() ] }
                $set->form_errors()
        ],
        [
            [
                'invalid',
                'The two password fields must match.'
            ],
            [
                'missing',
                'Special is no good.'
            ]
        ],
        'got expected form errors'
    );
}

done_testing();

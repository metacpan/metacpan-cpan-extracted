use strict;
use warnings;
use Test::More tests => 1;
use JSON::Tiny qw(decode_json);

package Validator {
    use Moo;
    use Data::FormValidator::Constraints qw(:closures);

    with 'Dancer2::Plugin::FormValidator::Role::HasProfile';

    sub profile {
        return {
            required => [qw(name email)],
            constraint_methods => {
                email => email,
            },
        };
    };
}

package App {
    use Dancer2;

    BEGIN {
        set plugins => {
            FormValidator => {
                session  => {
                    namespace => '_form_validator'
                },
                messages => {
                    missing => '<span>%s is missing.</span>',
                    invalid => '<span>%s is invalid.</span>',
                    ucfirst => 0,
                },
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    post '/' => sub {
        my $result = validate body_parameters->as_hashref => Validator->new;

        to_json $result->messages;
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(POST '/', [email => 'alexpan.org']);

is_deeply(
    decode_json($result->content),
    {
        'name'  => '<span>name is missing.</span>',
        'email' => '<span>email is invalid.</span>'
    },
    'Check messages form dancer config'
);

use strict;
use warnings;
use Test::More tests => 1;
use JSON::MaybeXS;

package Validator {
    use Moo;

    with 'Dancer2::Plugin::FormValidator::Role::Profile';

    sub profile {
        return {
            name  => [qw(required)],
            email => [qw(required email)],
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
                forms   => {
                    login => 'Validator',
                },
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    post '/' => sub {
        if (not validate_form 'login') {
            to_json errors;
        }
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(POST '/', [email => 'alexpan.org']);

is_deeply(
    decode_json($result->content),
    {
        name  => ['Name is required'],
        email => ['Email is not a valid email'],
    },
    'Check dsl: validate'
);

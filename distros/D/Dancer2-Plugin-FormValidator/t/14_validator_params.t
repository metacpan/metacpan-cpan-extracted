use strict;
use warnings;
use Test::More tests => 1;

package Validator {
    use Moo;

    with 'Dancer2::Plugin::FormValidator::Role::Profile';

    sub profile {
        return {
            password     => [qw(required)],
            password_cnf => [qw(required same:password)],
            role         => [qw(required enum:user,agent)]
        };
    };
}

package App {
    use Dancer2;

    BEGIN {
        set plugins => {
            FormValidator => {
                session => {
                    namespace => '_form_validator'
                },
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    post '/' => sub {
        if (not validate 'Validator') {
            to_json errors;
        }
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(POST '/', [password => 'pass1', password_cnf => 'pass', role => 'agent']);

is(
    $result->content,
    '{"password_cnf":["Password_cnf must be the same as password"]}',
    'Check validator params',
);

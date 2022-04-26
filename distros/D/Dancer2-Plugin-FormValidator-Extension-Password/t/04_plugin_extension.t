use strict;
use warnings;
use Test::More tests => 1;

package Validator {
    use Moo;

    with 'Dancer2::Plugin::FormValidator::Role::Profile';

    sub profile {
        return {
            email    => [qw(required email)],
            password => [qw(required password_robust)],
        };
    };
}

package App {
    use Dancer2;
    use URI::Escape;

    BEGIN {
        set plugins => {
            FormValidator => {
                session    => {
                    namespace => '_form_validator'
                },
                extensions => {
                    password => {
                        provider => 'Dancer2::Plugin::FormValidator::Extension::Password',
                    }
                }
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    post '/' => sub {
        if (not validate profile => Validator->new) {
            to_json errors;
        }
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(POST '/', [email => 'alex@cpan.org', password => 'dsgr-232As']);

is(
    $result->content,
    '{"password":["Password must be minimum 8 characters long and contain at least one letter, a number, and a special character"]}',
    'Check extension from config'
);

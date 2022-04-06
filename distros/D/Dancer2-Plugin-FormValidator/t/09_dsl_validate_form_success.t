use strict;
use warnings;
use Test::More tests => 1;

package Validator {
    use Moo;

    with 'Dancer2::Plugin::FormValidator::Role::Profile';

    sub profile {
        return {
            email => [qw(required email)],
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
                forms   => {
                    login => 'Validator',
                },
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    post '/' => sub {
        to_json validate_form 'login';
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(POST '/', [email => 'alexp@cpan.org', name => 'hacker']);

is(
    $result->content,
    '{"email":"alexp@cpan.org"}',
    'Check dsl: validate',
);

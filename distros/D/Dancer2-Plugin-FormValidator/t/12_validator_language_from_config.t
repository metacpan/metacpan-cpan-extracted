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
    use URI::Escape;

    BEGIN {
        set plugins => {
            FormValidator => {
                session => {
                    namespace => '_form_validator'
                },
                messages => {
                    language => 'de',
                },
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    post '/' => sub {
        if (not validate 'Validator') {
            to_json errors, {utf8 => 0};
        }
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(POST '/', [email => 'alex.cpan.org']);

is(
    $result->content,
    '{"email":["Email enthält keine gültige E-Mail-Adresse"]}',
    'Check language settings from config'
);

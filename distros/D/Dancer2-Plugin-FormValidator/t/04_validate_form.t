use strict;
use warnings;
use Test::More tests => 1;

package Validator {
    use Moo;
    use Data::FormValidator::Constraints qw(:closures);

    with 'Dancer2::Plugin::FormValidator::Role::HasProfile';

    sub profile {
        return {
            required => [qw(email)],
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
my $result = $app->request(POST '/', [email => 'alexp@cpan.org']);

is($result->content, '{"email":"alexp@cpan.org"}', 'Check response from validated route');

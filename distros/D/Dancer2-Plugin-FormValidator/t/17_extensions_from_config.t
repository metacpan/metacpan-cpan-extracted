use strict;
use warnings;

use FindBin;
use Test::More tests => 1;

require "$FindBin::Bin/lib/validator.pl";

package Email {
    use Moo;

    with 'Dancer2::Plugin::FormValidator::Role::Validator';

    sub message {
        return {
            en => '%s is a message from extension email',
        };
    }

    sub validate {
        return 0;
    }
}

package Extension {
    use Moo;

    with 'Dancer2::Plugin::FormValidator::Role::Extension';

    sub validators {
        return {
            email    => 'Email',
        }
    }
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
                    extension => {
                        provider => 'Extension',
                    }
                }
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    my $validator = Validator->new(profile_hash =>
        {
            email => [qw(required email)],
        }
    );

    post '/' => sub {
        if (not validate profile => $validator) {
            to_json errors;
        }
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(POST '/', [email => 'alex.cpan.org']);

is(
    $result->content,
    '{"email":["Email is a message from extension email"]}',
    'Check extension from config'
);

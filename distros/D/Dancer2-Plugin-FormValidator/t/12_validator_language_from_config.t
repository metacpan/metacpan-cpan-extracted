use strict;
use warnings;

use FindBin;
use Test::More tests => 1;

require "$FindBin::Bin/lib/validator.pl";

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

    my $validator = Validator->new(profile_hash =>
        {
            email => [qw(required email)],
        }
    );

    post '/' => sub {
        if (not validate profile => $validator) {
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

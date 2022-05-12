use strict;
use warnings;

use FindBin;
use Test::More tests => 1;
use JSON::MaybeXS;

require "$FindBin::Bin/lib/validator.pl";

package App {
    use Dancer2;

    BEGIN {
        set plugins => {
            FormValidator => {
                session  => {
                    namespace => '_form_validator'
                },
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    my $validator = Validator->new(profile_hash =>
        {
            name  => [qw(required)],
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
my $result = $app->request(POST '/', [email => 'alexpan.org']);

is_deeply(
    decode_json($result->content),
    {
        name  => ['Name is required'],
        email => ['Email is not a valid email'],
    },
    'Check dsl: validate'
);

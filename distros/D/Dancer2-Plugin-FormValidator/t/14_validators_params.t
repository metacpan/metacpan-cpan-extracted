use strict;
use warnings;
use utf8;

use FindBin;
use Test::More tests => 1;

require "$FindBin::Bin/lib/validator.pl";

# In this test ve wanna test validators params, like same:password.

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

    my $validator = Validator->new(profile_hash =>
        {
            password     => [ qw(required) ],
            password_cnf => [ qw(required same:password) ],
            name         => [ qw(alpha:u) ],
            role         => [ 'required', 'enum:user,agent' ],
        }
    );

    post '/' => sub {
        if (not validate profile => $validator){
            to_json errors;
        }
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(POST '/', [password => 'pass1', password_cnf => 'pass', name => 'Вася', role => 'agent']);

is(
    $result->content,
    '{"password_cnf":["Password_cnf must be the same as password"]}',
    'Check validator params',
);

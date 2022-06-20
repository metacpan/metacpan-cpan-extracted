use strict;
use warnings;
use utf8;

use FindBin;
use Test::More tests => 1;

require "$FindBin::Bin/lib/validator.pl";

# Test default input set form get request.

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
            name => [ 'alpha' ],
            role => [ 'required', 'enum:user,agent' ],
        }
    );

    get '/' => sub {
        if (not validate profile => $validator){
            to_json errors;
        }
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(GET '/?role=agent&name=123');

is(
    $result->content,
    '{"name":["Name must contain only latin alphabetical symbols"]}',
    'Check default input set form get request',
);

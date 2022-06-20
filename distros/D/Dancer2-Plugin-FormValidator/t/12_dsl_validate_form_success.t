use strict;
use warnings;

use FindBin;
use Test::More tests => 1;

require "$FindBin::Bin/lib/validator.pl";

package App {
    use Dancer2;
    use Dancer2::Plugin::FormValidator;

    my $validator = Validator->new(profile_hash =>
        {
            email => [qw(required email)],
        }
    );

    post '/' => sub {
        to_json validate profile => $validator;
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

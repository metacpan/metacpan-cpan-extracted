use strict;
use warnings;

use Test::More tests => 5;

package App {
    use Dancer2;

    BEGIN {
        set plugins => { CSRFI => { validate_post => 1 } };
    }

    use Dancer2::Plugin::CSRFI;

    get '/token' => sub {
        return csrf_token;
    };

    post '/form' => sub {
        return body_parameters->{field};
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app = Plack::Test->create(App->to_app);
my $result;
my $token;
my $cookie;

# TEST 1 with cookie - should be valid.
$result = $app->request(GET '/token');
$token  = $result->content;

($cookie) =  $result->header('set-cookie') =~ /(dancer\.session=[^;]*)/;

$result = $app->request(
    POST '/form',
    [csrf_token => $token, field => 'y'],
    Cookie => $cookie,
    Referer => 'http://localhost/token'
);

is($result->content, 'y', 'Test1: valid token with valid session and referer');

# TEST 2 without cookie - should be invalid.
$result = $app->request(GET '/token');
$token  = $result->content;

$result = $app->request(
    POST '/form',
    [csrf_token => $token, field => 'y'],
    Referer => 'http://localhost/token'
);

is($result->code, 403, 'Test2: valid token without valid session and referer');


### Now check custom error_status and csrf_field.

package App2 {
    use Dancer2;

    BEGIN {
        set plugins => {
            CSRFI => {
                validate_post => 1,
                field_name    => 'custo',
                error_status  => 419,
            }
        };
    }

    use Dancer2::Plugin::CSRFI;

    get '/token' => sub {
        return csrf_token;
    };

    post '/form' => sub {
        return body_parameters->{field};
    };
}

$app = Plack::Test->create(App2->to_app);

# TEST 3 with cookie - should be valid.
$result = $app->request(GET '/token');
$token  = $result->content;

($cookie) =  $result->header('set-cookie') =~ /(dancer\.session=[^;]*)/;

$result = $app->request(
    POST '/form',
    [custo => $token, field => 'y'],
    Cookie => $cookie,
    Referer => 'http://localhost/token'
);

is($result->content, 'y', 'Test3: valid token with valid session and referer');

# TEST 4 without cookie - should be invalid.
$result = $app->request(GET '/token');
$token  = $result->content;

$result = $app->request(
    POST '/form',
    [custo => $token, field => 'y'],
    Referer => 'http://localhost/token'
);

is($result->code, 419, 'Test4: valid token without valid session and referer');

### Now check custom hook.

package App3 {
    use Dancer2;

    BEGIN {
        set plugins => { CSRFI => { validate_post => 1 } };
    }

    use Dancer2::Plugin::CSRFI;

    hook after_validate_csrf => sub {
        $_[1]->{error_status} = 503;
    };

    get '/token' => sub {
        return csrf_token;
    };

    post '/form' => sub {
        return body_parameters->{field};
    };
}

$app = Plack::Test->create(App3->to_app);

# TEST 5 without cookie - should be invalid.
$result = $app->request(GET '/token');
$token  = $result->content;

$result = $app->request(
    POST '/form',
        [csrf_token => $token, field => 'y'],
        Referer => 'http://localhost/token'
);

is($result->code, 503, 'Test5: valid token without valid session and referer');

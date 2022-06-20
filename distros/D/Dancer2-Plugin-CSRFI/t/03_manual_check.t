use strict;
use warnings;

use Test::More tests => 7;

package App {
    use Dancer2;
    use Dancer2::Plugin::CSRFI;

    get '/token' => sub {
        return csrf_token;
    };

    post '/validate' => sub {
        return validate_csrf(body_parameters->{csrf_token}) ? 'valid' : 'invalid';
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
    POST '/validate',
    [csrf_token => $token],
    Cookie => $cookie,
    Referer => 'http://localhost/token'
);

is($result->content, 'valid', 'Test1: valid token with valid session and referer');

# TEST 2 with cookie but issue two tokens and use first - should be valid.
$result = $app->request(GET '/token');
$token  = $result->content;

# One more token issue.
$app->request(GET '/token');

($cookie) =  $result->header('set-cookie') =~ /(dancer\.session=[^;]*)/;

$result = $app->request(
    POST '/validate',
    [csrf_token => $token],
    Cookie => $cookie,
    Referer => 'http://localhost/token'
);

is($result->content, 'valid', 'Test2: valid first token with valid session and referer after second issue');

# TEST 3 without cookie and referer - should be invalid.
$result = $app->request(GET '/token');
$token  = $result->content;

$result = $app->request(
    POST '/validate',
    [csrf_token => $token]
);

isnt($result->content, 'valid', 'Test3: valid token without session and referer');

# TEST 4 without cookie but with referer - should be invalid.
$result = $app->request(GET '/token');
$token  = $result->content;

$result = $app->request(
    POST '/validate',
    [csrf_token => $token],
    Referer => 'http://localhost/token'
);

isnt($result->content, 'valid', 'Test4: valid token without session but with referer');

# TEST 5 with cookie but without referer - should be invalid.
$result = $app->request(GET '/token');
$token  = $result->content;

($cookie) =  $result->header('set-cookie') =~ /(dancer\.session=[^;]*)/;

$result = $app->request(
    POST '/validate',
    [csrf_token => $token],
    Cookie => $cookie,
);

isnt($result->content, 'valid', 'Test5: valid token with session but without referer');

### Now test how token refreshes.

package App2 {
    use Dancer2;

    BEGIN {
        set plugins => { CSRFI => { refresh => 1 } };
    }

    use Dancer2::Plugin::CSRFI;

    get '/token' => sub {
        return csrf_token;
    };

    post '/validate' => sub {
        return validate_csrf(body_parameters->{csrf_token}) ? 'valid' : 'invalid';
    };
}

$app = Plack::Test->create(App2->to_app);

# TEST 6 with cookie - should be valid.
$result = $app->request(GET '/token');
$token  = $result->content;

($cookie) =  $result->header('set-cookie') =~ /(dancer\.session=[^;]*)/;

$result = $app->request(
    POST '/validate',
        [csrf_token => $token],
        Cookie => $cookie,
        Referer => 'http://localhost/token'
);

is($result->content, 'valid', 'Test6: valid token with valid session and referer');

# TEST 7 with cookie but issue two tokens and use first - should be invalid.
$result = $app->request(GET '/token');
$token  = $result->content;

# We need to use first session.
($cookie) =  $result->header('set-cookie') =~ /(dancer\.session=[^;]*)/;

# One more token issue.
$app->request(GET '/token', Cookie => $cookie);

$result = $app->request(
    POST '/validate',
        [csrf_token => $token],
        Cookie => $cookie,
        Referer => 'http://localhost/token'
);

isnt($result->content, 'valid', 'Test7: valid first token with valid session and referer after second issue');

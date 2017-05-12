# TODO: handle line-endings better.  Perhaps we should just look for an 
# identifying part of each page rather than trying to do an exact match
# of the entire page.  The problem is on win32, some responses come back with
# dos-style line endings (not all of them though).  Not sure what MacOS does
# and I don't have a Mac to test with.  Currently, we just strip CR's out of
# responses to make the tests pass on Unix and Win32.  
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use utf8;

use Apache::Test '-withtestmore';
use Apache::TestUtil;
use Apache::TestRequest qw(GET POST GET_BODY);
use Encode qw(encode);

Apache::TestRequest::user_agent( reset => 1, requests_redirectable => 0 );

plan tests => 33, need_lwp;

ok 1, 'Test initialized';

# TODO: the test descriptions should be things other than 'test #' here.

# check that /docs/index.html works.  If this fails, the test environment did
# not configure properly.
subtest 'get index.html' => sub {
    plan tests => 1;

    my $url = '/docs/index.html';
    my $data = strip_cr(GET_BODY $url);

    like($data, qr/Get the protected document/s,
         '/docs/index.html seems to work');
};

# test no_cookie failure
subtest 'no cookie' => sub {
    plan tests => 1;

    my $url = '/docs/protected/get_me.html';
    my $r = GET $url;

    like($r->content, qr/Failure reason: 'no_cookie'/s,
         'no_cookie works');
};

# should succeed with redirect.
subtest 'login redirects' => sub {
    plan tests => 2;

    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Hero'
    ]);

    is($r->code, 302, 'login produces redirect');
    is($r->header('Location'), '/docs/protected/get_me.html',
       'redirect header exists, and contains expected url');
};

subtest 'redirect with bad session key' => sub {
    plan tests => 3;

    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Heroo'
    ]);

    is($r->code, 302, 'programmer:Heroo login replies with redirect');

    is($r->header('Location'), '/docs/protected/get_me.html',
       'programmer:Heroo location header contains expected URL');

    is($r->header('Set-Cookie'),
       'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/',
       'programmer:Heroo cookie header contains expected data');
};

# get protected document with valid cookie.  Should succeed.
subtest 'redirect wit valid cookie' => sub {
    plan tests => 2;

    my $uri = '/docs/protected/get_me.html';

    my $r = GET(
        $uri,
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'
    );

    is($r->code, '200', 'get protected document');
    like($r->content, qr/Congratulations, you got past AuthCookie/s,
         'check protected document content');
};

subtest 'directory index' => sub {
    plan tests => 2;

    my $uri = '/docs/protected/';

    my $r = GET(
        $uri,
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'
    );

    is($r->code, '200', 'get protected document');
    like($r->content, qr/Congratulations, you got index\.html/s,
         'check protected index.html document content');
};

# should have a Set-Cookie header that expired at epoch.
subtest 'logout deletes cookie' => sub {
    plan tests => 1;

    my $url = '/docs/logout.pl';

    my $r = GET($url);

    my $data = $r->header('Set-Cookie');
    my $expected = 'Sample::AuthCookieHandler_WhatEver=; expires=Mon, 21-May-1971 00:00:00 GMT; path=/';

    is($data, $expected, 'logout tries to delete the cookie');
};

# check the session key
subtest 'session key data' => sub {
    plan tests => 1;

    my $data = GET_BODY(
        '/docs/echo_cookie.pl',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'
    );

    is(strip_cr($data), 'programmer:Hero', 'session key contains expected data');
};

# should fail because of 'require user programmer'
subtest 'invalid user' => sub {
    plan tests => 1;

    my $r = GET(
        '/docs/protected/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:duck;'
    );

    is($r->code, '403', 'user "some-user" is not authorized');
};

# should get the login form back (bad_cookie).
subtest 'invalid cookie' => sub {
    plan tests => 1;

    my $data = GET_BODY(
        '/docs/protected/get_me.html',
        Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Heroo'
    );

    like($data, qr/Failure reason: 'bad_cookie'/, 'invalid cookie');
};

# should get the login form back (bad_credentials)
subtest 'bad credentials' => sub {
    plan tests => 1;

    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'Hero'
    ]);

    like($r->content, qr/Failure reason: 'bad_credentials'/,
         'invalid credentials');
};

subtest 'AuthAny' => sub {
    plan tests => 3;

    my $r = POST('/LOGIN', [
        destination  => '/docs/authany/get_me.html',
        credential_0 => 'some-user',
        credential_1 => 'mypassword'
    ]);

    is($r->header('Location'), '/docs/authany/get_me.html',
       'Location header is correct');

    is($r->header('Set-Cookie'), 
       'Sample::AuthCookieHandler_WhatEver=some-user:mypassword; path=/',
       'Set-Cookie header is correct');

    is($r->code, 302, 'redirect code is correct');
};

# should fail because all requirements are not met
subtest 'AuthAll' => sub {
    plan tests => 3;

    my $r = GET(
        '/docs/authall/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword'
    );

    is($r->code(), 403, 'unauthorized if requirements are not met');

    # should pass, ALL requirements are met
    $r = GET(
        '/docs/authall/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero'
    );

    is($r->code, '200', 'get protected document');
    like($r->content, qr/Congratulations, you got past AuthCookie/s,
         'check protected document content');
};

subtest 'POST to GET conversion' => sub {
    plan tests => 1;

    my $r = POST('/docs/protected/get_me.html', [
        utf8 => 'programmør'
    ]);

    like($r->content, qr#"/docs/protected/get_me\.html\?utf8=programm%c3%b8r"#,
         'POST -> GET conversion works');
};

subtest 'QUERY_STRING is preserved' => sub {
    plan tests => 1;

    my $data = GET_BODY('/docs/protected/get_me.html?foo=bar');

    like($data, qr#"/docs/protected/get_me\.html\?foo=bar"#,
         'input query string exists in desintation');
};

# should succeed (any requirement is met)
subtest 'AuthAny' => sub {
    plan tests => 3;

    my $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword'
    );

    like($r->content, qr/Congratulations, you got past AuthCookie/,
         'AuthAny access allowed');

    # any requirement, username=0 works.
    $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=0:mypassword'
    );

    like($r->content, qr/Congratulations, you got past AuthCookie/,
         'username=0 access allowed');

    # no AuthAny requirements met
    $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=nouser:mypassword'
    );

    is($r->code, 403, 'AuthAny forbidden');
};

# local authz provider test for 2.4 (works same as authany on older versions)
subtest 'Authz Provider' => sub {
    plan tests => 1;

    my $r = GET(
        '/docs/myuser/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero'
    );

    like($r->content, qr/Congratulations, you got past AuthCookie/,
         'myuser=programmer access allowed');
};

# login with username=0 works
subtest 'login with username=0' => sub {
    plan tests => 2;

    my $r = POST('/LOGIN', [
        destination  => '/docs/authany/get_me.html',
        credential_0 => '0',
        credential_1 => 'mypassword'
    ]);

    is($r->code, 302, 'username=0 login produces redirect');
    is($r->header('Location'), '/docs/authany/get_me.html',
       'redirect header exists, and contains expected url');
};

subtest 'parameter encoding' => sub {
    plan tests => 5;

    my $r = POST('/LOGIN', [
        destination => '/docs/authany/get_me.html',
        credential_0 => '程序员',
        credential_1 => 'Hero'
    ]);

    is($r->code, 302, 'UTF-8 username works');
    is($r->header('Location'), '/docs/authany/get_me.html',
       'redirect header exists, and contains expected url');

    like $r->header('Set-Cookie'),
        qr#Sample::AuthCookieHandler_WhatEver=%E7%A8%8B%E5%BA%8F%E5%91%98:Hero;#,
        'response contains the session key cookie';

    $r = GET('/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=%E7%A8%8B%E5%BA%8F%E5%91%98:Hero;'
    );

    is $r->code, 200;
    like($r->content, qr/Congratulations, you got past AuthCookie/s,
         'check protected document content');
};

# Should succeed and cookie should have HttpOnly attribute
subtest 'HttpOnly cookie attribute' => sub {
    plan tests => 3;

    my $r = POST('/LOGIN-HTTPONLY', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Heroo'
    ]);

    is($r->header('Location'), '/docs/protected/get_me.html',
       'HttpOnly location header');

    is($r->header('Set-Cookie'),
       'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/; HttpOnly',
       'cookie contains HttpOnly attribute');

    is($r->code, 302, 'check redirect response code');
};

# test SessionTimeout
subtest 'session timeout' => sub {
    plan tests => 1;

    my $r = GET(
        '/docs/stimeout/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero'
    );

    like($r->header('Set-Cookie'),
         qr/^Sample::AuthCookieHandler_WhatEver=.*expires=.+/,
         'Set-Cookie contains expires property');
};

# should return bad credentials page, and credentials should be in a comment.
# We are checking here that $r->prev->pnotes('WhatEverCreds') works.
subtest 'creds are in pnotes' => sub {
    plan tests => 1;

    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'Hero'
    ]);

    like($r->content, qr/creds: fail Hero/s, 'WhatEverCreds pnotes works');
};

# regression - Apache2::URI::unescape_url() does not handle '+' to ' '
# conversion.
subtest 'unescape URL with spaces' => sub {
    plan tests => 1;

    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'one two'
    ]);

    like($r->content, qr/creds: fail one two/,
         'read form data handles "+" conversion');
};

# variation of '+' to ' ' regression.  Make sure we do not remove encoded
# '+'
subtest 'do not remove encoded +' => sub {
    plan tests => 1;

    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'one+two'
    ]);

    like($r->content, qr/creds: fail one\+two/,
         'read form data handles "+" conversion with encoded +');
};

# XSS attack prevention.  make sure embedded \r, \n, \t is escaped in the destination.
subtest 'XSS: no newlines in destination' => sub {
    plan tests => 4;

    my $r = POST('/LOGIN', [
        destination  => "/docs/protected/get_me.html\r\nX-Test-Bar: True\r\nX-Test-Foo: True\r\n",
        credential_0 => 'programmer',
        credential_1 => 'Hero'
    ]);

    ok(!defined $r->header('X-Test-Foo'), 'anti XSS injection');
    ok(!defined $r->header('X-Test-Bar'), 'anti XSS injection');

    # try with escaped CRLF also.
    $r = POST('/LOGIN', [
        destination  => "/docs/protected/get_me.html%0d%0aX-Test-Foo: True%0d%0aX-Test-Bar: True\r\n",
        credential_0 => 'programmer',
        credential_1 => 'Hero'
    ]);

    ok(!defined $r->header('X-Test-Foo'), 'anti XSS injection with escaped CRLF');
    ok(!defined $r->header('X-Test-Bar'), 'anti XSS injection with escaped CRLF');
};

# embedded html tags in destination
subtest 'XSS: no embedded HTML in destination' => sub {
    plan tests => 1;

    my $r = POST('/LOGIN', [
        destination  => '"><form method="post">Embedded Form</form>'
    ]);

    like $r->content, qr{"%22%3E%3Cform method=%22post%22%3EEmbedded Form%3C/form%3E"};
};

# embedded script tags
subtest 'XSS: no embedded script' => sub {
    plan tests => 1;

    my $r = POST('/LOGIN', [
        destination => q{"><script>alert('123')</script>}
    ]);

    ok index($r->content, q{<script>alert('123')</script>}) == -1;
};

subtest 'preserve / in password' => sub {
    plan tests => 1;

    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'one/two'
    ]);

    like($r->content, qr/creds: fail one\/two/,
         'read form data handles "/" conversion with encoded +');
};

# make sure multi-valued form data is preserved.
subtest 'multi-valued form data is preserved' => sub {
    plan tests => 2;

    my $r = POST('/docs/protected/xyz', [
        one => 'abc',
        one => 'def'
    ]);

    # check and make sure we are at the login form now.
    like($r->content, qr/Failure reason: 'no_cookie'/,
         'login form was returned');

    # check for multi-valued form data.
    like($r->content, qr/one=abc&one=def/,
         'post conversion perserves multi-valued fields');
};

# make sure $ENV{REMOTE_USER} gets set up
subtest 'setup $ENV{REMOTE_USER}' => sub {
    plan tests => 1;

    my $r = GET('/docs/protected/echo_user.pl',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero'
    );

    like($r->content, qr/User: programmer/);
};

# test login form response status=OK with SymbianOS
subtest 'SymbianOS login form response code' => sub {
    plan tests => 4;

    my $orig_agent = Apache::TestRequest::user_agent()->agent;

    # should get a 403 response by default
    my $r = GET('/docs/protected/get_me.html');
    is $r->code, 403;
    like $r->content, qr/\bcredential_0\b/, 'got login form';

    Apache::TestRequest::user_agent()
        ->agent('Mozilla/5.0 (SymbianOS/9.1; U; [en]; Series60/3.0 NokiaE60/4.06.0) AppleWebKit/413 (KHTML, like Gecko) Safari/413');

    # should get a 200 response for SymbianOS
    $r = GET('/docs/protected/get_me.html');
    is $r->code, 200;
    like $r->content, qr/\bcredential_0\b/, 'got login form';

    Apache::TestRequest::user_agent()->agent($orig_agent);
};

subtest 'recognize user' => sub {
    plan tests => 1;

    # recognize user
    my $body = GET_BODY('/docs/echo-user.pl',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero');

    is $body, 'programmer';
};

# remove CR's from a string.  Win32 apache apparently does line ending
# conversion, and that can cause test cases to fail because output does not
# match expected because expected has UNIX line endings, and OUTPUT has dos
# style line endings.
sub strip_cr {
    my $data = shift;
    $data =~ s/\r//gs;
    return $data;
}

# vim: ft=perl ts=4 ai et sw=4

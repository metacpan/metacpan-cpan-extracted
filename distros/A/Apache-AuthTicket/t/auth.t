#!perl
#
# test AuthTicket authentication

use strict;
use warnings FATAL => 'all';
use lib qw(t/lib);
use Apache::Test '-withtestmore';
use Apache::TestRequest qw(GET POST);

if (not have_module('DBD::SQLite')) {
    plan skip_all => 'DBD::SQLite is not installed';
}
elsif (not have_module('LWP::UserAgent')) {
    plan skip_all => 'LWP::UserAgent is not installed';
}
else {
    plan tests => 34;
}

# must match value in SQLite DB
my $Secret = 'mvkj39vek@#$R*njdea9@#';

my $CookieFormat = qr/[0-9a-f]{32}\-\-[A-Za-z0-9+\/]+/;

use_ok('Apache::AuthTicket::Base');

Apache::TestRequest::user_agent(
    cookie_jar            => {},
    reset                 => 1,
    requests_redirectable => 0);

# get login form
my $r = GET '/protected/index.html';
isa_ok $r, 'HTTP::Response';
is $r->code, 403, 'got 403 response';
like $r->content, qr/credential_0/, 'content contains credential_0';
like $r->content, qr/credential_0/, 'content contains credential_1';

# login
$r = POST '/login', [
    destination => '/protected/index.html',
    credential_0 => 'programmer',
    credential_1 => 'secret' ];
isa_ok $r, 'HTTP::Response';
is $r->code, 302, 'got 302 response';
is $r->header('Location'), '/protected/index.html', 'Location header';
like $r->header('Set-Cookie'), qr/$CookieFormat/, 'response sets cookie';

# get the protected page.
$r = GET '/protected/index.html';
isa_ok $r, 'HTTP::Response';
is $r->code, 200, 'got 200 response';
like $r->content, qr/congratulations, you got the protected page/;

# logout
$r = GET '/protected/logout';
isa_ok $r, 'HTTP::Response';
is $r->code, 302, 'got 302 response from logout';
like $r->header('Set-Cookie'), qr/::AuthTicket_Protected=;\s+/, 'Cookie was cleared';
is $r->header('Location'), '/protected/index.html', 'Logout sets location header';

# make sure we really logged out.
$r = GET '/protected/index.html';
isa_ok $r, 'HTTP::Response';
is $r->code, 403, 'got 403 response';

### /secure auth area tests.
$r = GET '/secure/protected/index.html';
isa_ok $r, 'HTTP::Response';
is $r->code, 403, 'got 403 response';
like $r->content, qr/credential_0/, 'content contains credential_0';
like $r->content, qr/credential_0/, 'content contains credential_1';

# login
$r = POST '/secure/login', [
    destination => '/secure/protected/index.html',
    credential_0 => 'programmer',
    credential_1 => 'secret' ];
isa_ok $r, 'HTTP::Response';
is $r->code, 302, 'got 302 response';
is $r->header('Location'), '/secure/protected/index.html', 'Location header';
my $cookie = $r->header('Set-Cookie');
like $cookie, qr/AuthTicket_Sec=$CookieFormat/, 'response sets cookie';
ok cookie_has_field($cookie, 'secure'), 'cookie has secure flag set';
ok cookie_has_field($cookie, 'path=/secure'), 'cookie path = /secure';
ok cookie_has_field($cookie, 'domain=.local'), 'cookie domain is .local';
ok check_hash($cookie, ip => 0, browser => 1), 'hash users browser, not ip';

# we have to manually send the cookie here because of secure/domain fields.
$r = GET '/secure/protected/index.html', Cookie => $cookie;
isa_ok $r, 'HTTP::Response';
is $r->code, 200, 'got 200 response';

# lets tamper with the cookie. should get 403
{
    my ($data) = $cookie =~ /--(.*?);/;
    my $ticket = Apache::AuthTicket::Base->unserialize_ticket($data);
    $$ticket{expires} += 1;

    my $new_data = Apache::AuthTicket::Base->serialize_ticket($ticket);
    $cookie =~ s/$data/$new_data/;
    $r = GET '/secure/protected/index.html', Cookie => $cookie;
    isa_ok $r, 'HTTP::Response';
    is $r->code, 403, 'tampered cookie got 403 response';
}

sub cookie_has_field {
    my ($cookie, $expected) = @_;

    my @parts = split /;\s+/, $cookie;

    for my $part (@parts) {
        return 1 if lc $part eq lc $expected;
    }

    return 0;
}

# given a cookie string, recompute the hash and check that it is what we expect.
# options:
#   ip => 0|1      ticket includes ipaddress
#   browser => 0|1 ticket includes user agent string
sub check_hash {
    my ($cookie, %opt) = @_;

    my ($string) = $cookie =~ /AuthTicket_[^=]+=(.*?);/;

    my ($hash, $data) = split '--', $string, 2;

    my @fields = ($Secret, $data);

    if ($opt{ip}) {
        push @fields, '127.0.0.1';
    }

    if ($opt{browser}) {
        push @fields, Apache::TestRequest::user_agent()->agent;
    }

    my $check = Apache::AuthTicket::Base->hash_for(@fields);

    unless ($check eq $hash) {
        diag "Hash mismatch: $hash != $check";
        return 0;
    }

    return 1;
}

# vim: ft=perl

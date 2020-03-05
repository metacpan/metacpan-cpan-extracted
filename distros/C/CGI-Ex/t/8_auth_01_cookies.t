# -*- Mode: Perl; -*-

=head1 NAME

8_auth_01_cookies.t - Testing of the CGI::Ex::Auth cookies.

=cut

use strict;
use Test::More tests => 4;

use CGI::Ex::Auth;

{
    package Fake::CGI::Ex;

    my $cookie;

    sub new         { bless {}, shift }
    sub set_cookie  { shift; $cookie = shift }
    sub get_cookies { +{} }

    sub FAKE_reset  { undef $cookie }
    sub FAKE_cookie { $cookie }
}

my $cgix = Fake::CGI::Ex->new;
my $auth = CGI::Ex::Auth->new({cgix => $cgix});

$auth->set_cookie({
    name    => 'foo',
    value   => 'bar',
});
is_deeply($cgix->FAKE_cookie, {
    -name   => 'foo',
    -path   => '/',
    -value  => 'bar',
}, 'set_cookie works') or diag explain $cgix->FAKE_cookie;
$cgix->FAKE_reset;

$auth->set_cookie({
    domain  => 'example.com',
    name    => 'foo',
    path    => '/baz',
    secure  => 1,
    value   => 'bar',
});
is_deeply($cgix->FAKE_cookie, {
    -domain => 'example.com',
    -name   => 'foo',
    -path   => '/baz',
    -secure => 1,
    -value  => 'bar',
}, 'set_cookie with more args works') or diag explain $cgix->FAKE_cookie;
$cgix->FAKE_reset;

$auth->set_cookie({
    name        => 'foo',
    value       => 'bar',
    samesite    => 'strict',
});
is_deeply($cgix->FAKE_cookie, {
    -name       => 'foo',
    -path       => '/',
    -samesite   => 'strict',
    -value      => 'bar',
}, 'set_cookie with samesite arg works') or diag explain $cgix->FAKE_cookie;
$cgix->FAKE_reset;

my $auth2 = CGI::Ex::Auth->new({cgix => $cgix, cookie_samesite => 'lax'});
$auth2->set_cookie({
    name    => 'foo',
    value   => 'bar',
});
is_deeply($cgix->FAKE_cookie, {
    -name       => 'foo',
    -path       => '/',
    -samesite   => 'lax',
    -value      => 'bar',
}, 'set_cookie with cookie_samesite works') or diag explain $cgix->FAKE_cookie;
$cgix->FAKE_reset;


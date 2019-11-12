use strict;
use warnings;

use Test::More import => ['!pass'];
plan tests => 23;

package FBMock;
use Test::More;

sub as_hash { {username => 'foo', name => 'bar', email => 'a@b.co'} }

sub get_access_token {
    is @_, 3, 'FBMock: passed 3 elements to get_access_token()';
    my ($self, %args) = @_;
    isa_ok $self, 'Net::Facebook::Oauth2', 'FBMock: object checks ok';
    is keys %args, 1, '1 key on get_access_token';
    ok exists $args{code}, 'key is "code"';
    is $args{code}, 'something', 'code received properly';
    return 9876;
}

sub get {
  is @_, 2, 'FBMock: passed two elements to get()';
  my ($self, $arg) = @_;

  isa_ok $self, 'Net::Facebook::Oauth2', 'FBMock: object checks ok';
  is $arg, 'https://graph.facebook.com/v4.0/me', 'FBMock: arguments check on get()';

  return bless {}, 'FBMock';
}


package main;

{
    use Dancer;

    # settings must be loaded before we load the plugin
    setting(plugins => {
        'Auth::Facebook' => {
            application_id     => 1234,
            application_secret => 5678,
            callback_url       => 'http://myserver:3000/auth/facebook/callback',
            callback_success   => '/ok',
            callback_fail      => '/not-ok',
            scope              => 'basic_info email user_birthday',
        },
    });

    eval 'use Dancer::Plugin::Auth::Facebook';
    die $@ if $@;
    ok 1, 'plugin loaded successfully';

    ok auth_fb_init(), 'able to load auth_fb_init()';

    ok my $fb = facebook(), 'facebook object is available to apps';
    isa_ok $fb, 'Net::Facebook::Oauth2';

    like auth_fb_authenticate_url(),
       qr{^https://www\.facebook\.com/v4\.0/dialog/oauth},
       'auth_fb_authenticate_url() returns the proper facebook auth url';
}

use Dancer::Test;

route_exists [ GET => '/auth/facebook/callback' ], 'facebook auth callback route exists';

{
    no warnings qw(redefine once);
    *Net::Facebook::Oauth2::get = *FBMock::get;
    *Net::Facebook::Oauth2::get_access_token = *FBMock::get_access_token;
}

my $res = dancer_response( GET => '/auth/facebook/callback' );
is $res->status, 302, 'auth callback redirects user';
is $res->header('location')->path, '/not-ok', 'auth callback failure';
is session('fb_user'), undef, 'facebook user not set';

$res = dancer_response( GET => '/auth/facebook/callback?error=something' );
is $res->status, 302, 'auth callback with error redirects user';
is $res->header('location')->path, '/not-ok', 'auth callback with error failure';
is session('fb_user'), undef, 'facebook user not set on error';

$res = dancer_response( GET => '/auth/facebook/callback?code=something' );
is $res->status, 302, 'auth callback with code redirects user';
is $res->header('location')->path, '/ok', 'auth callback with success';

is_deeply session('fb_user'), {
    username => 'foo',
    name     => 'bar',
    email    => 'a@b.co',
}, 'got data from facebook mock';


#!perl

use lib './lib';
use strict;
use warnings;
use Test::More tests => 1;

use HTTP::Request::Common qw( GET );
use Plack::Test;

my $password = 'some-secret-password';

{

    package t::lib::TestApp;
    use Dancer2;
    use Dancer2::Plugin::Argon2;
    set plugins => {
        Argon2 => {
            cost        => 4,
            factor      => '32M',
            parallelism => 2,
            size        => 24,
        } };
    get '/passphrase' => sub {
        return passphrase($password)->encoded;
    };
}

subtest 'test app with custom settings' => sub {
    my $app = t::lib::TestApp->to_app;
    is( ref $app, "CODE", "Got a code ref" );

    test_psgi $app => sub {
        my $cb = shift;
        {
            my $res = $cb->( GET '/passphrase' );
            like $res->content, qr/^\$argon2id\$v=19\$m=32768,t=4,p=2\$[\w\+\$\/]+\z/, 'with default settings';
        }
    };

};

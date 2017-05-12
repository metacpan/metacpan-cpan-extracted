use strict;
use warnings;
use Test::More;
use Catalyst::Plugin::Session::State::Header;

my @paths = (
    'api/login',
    'api/login/',
    '/api/login',
    '///api///login/',
    'api////login///'
);

my $proper_path = '/api/login/';

for my $path (@paths) {
    is (Catalyst::Plugin::Session::State::Header::uni_path($path), $proper_path, 'uni_path works properly');
}

is (Catalyst::Plugin::Session::State::Header::uni_path('/'), '/', 'uni_path works properly for root');
is (Catalyst::Plugin::Session::State::Header::uni_path('//'), '/', 'uni_path works properly for root');
done_testing();

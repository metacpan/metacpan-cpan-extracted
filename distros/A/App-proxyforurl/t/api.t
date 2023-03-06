use Mojo::Base -strict;
use Mojo::File qw(path);
use Test::Mojo;
use Test::More;

plan skip_all => 'developer testing only' unless -d '.git';

my $t = Test::Mojo->new(path('script/proxyforurl')->to_abs);

subtest 'gethostbyname' => sub {
  $t->post_ok('/v1/gethostbyname')->status_is(400)->content_is('Host missing.');

  $t->post_ok('/v1/gethostbyname', form => {host => 123})->status_is(400)
    ->content_is('Invalid host: 123');

  $t->post_ok('/v1/gethostbyname', form => {host => 'asdasdasdasdsdasd.com'})->status_is(400)
    ->content_is('No IP found for asdasdasdasdsdasd.com');

  $t->post_ok('/v1/gethostbyname', form => {host => '192.0.2.42'})->status_is(200)
    ->content_is('192.0.2.42');

  $t->post_ok('/v1/gethostbyname', form => {host => 'localhost'})->status_is(200)
    ->content_is('127.0.0.1');
};

subtest 'is-in-net' => sub {
  $t->post_ok('/v1/is-in-net')->status_is(400)->content_is('IP or Net is missing.');

  $t->post_ok('/v1/is-in-net', form => {ip => '192.0.2.4', net => '192.0.2.0', mask => 'a'})
    ->status_is(400)->content_is('Mask is invalid or missing.');

  $t->post_ok('/v1/is-in-net',
    form => {ip => '147.161.169.114', net => '10.82.48.0', mask => '255255255248'})->status_is(400)
    ->content_is('Mask is invalid or missing.');

  $t->post_ok('/v1/is-in-net', form => {ip => '192.0.2.4', net => '192.0.2.0', mask => '24'})
    ->status_is(200)->content_is(1);

  $t->post_ok('/v1/is-in-net', form => {ip => '192.0.2.4', net => '192.0.2.100', mask => '32'})
    ->status_is(200)->content_is(0);

  $t->post_ok('/v1/is-in-net', form => {ip => 'thorsen.pm', net => '192.0.2.100', mask => '32'})
    ->status_is(200)->content_is(0);

  $t->post_ok('/v1/is-in-net', form => {ip => '10.1.1.1', net => '10.1.1.0', mask => '24'})
    ->status_is(200)->content_is(1);
};

done_testing;

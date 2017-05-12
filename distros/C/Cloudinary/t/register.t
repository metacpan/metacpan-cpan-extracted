use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use Mojolicious::Lite;
plugin 'Mojolicious::Plugin::Cloudinary', {cloud_name => 'test'};
get '/image' => sub {
  my $self = shift;
  $self->render(
    text => $self->cloudinary_image(
      "1234567890.jpg" => {w => 50, height => 50},
      {class => 'awesome-class'}
    )
  );
};
get '/js-image' => sub {
  my $self = shift;
  $self->render(text => $self->cloudinary_js_image("1234567890.jpg" => {w => 50, height => 50}));
};
get '/upload'  => sub { $_[0]->cloudinary_upload;  $_[0]->render(text => 'upload') };
get '/destroy' => sub { $_[0]->cloudinary_destroy; $_[0]->render(text => 'destroy') };
get '/url-for' => sub { $_[0]->render(text => $_[0]->cloudinary_url_for('yey.png')) };

my $t = Test::Mojo->new;

$t->get_ok('/image')->content_like(qr{^<img })
  ->content_like(qr{ src="http://res.cloudinary.com/test/image/upload/h_50,w_50/1234567890\.jpg"})
  ->content_like(qr{ class="awesome-class"})->content_like(qr{ alt="1234567890\.jpg"})
  ->content_like(qr{>$});

$t->get_ok('/js-image')->content_like(qr{^<img })->content_like(qr{ src="/image/blank\.png"})
  ->content_like(qr{ class="cloudinary-js-image"})->content_like(qr{ data-src="1234567890\.jpg"})
  ->content_like(qr{ data-width="50"})->content_like(qr{ data-height="50"})
  ->content_like(qr{ alt="1234567890\.jpg"})->content_like(qr{>$});

$t->get_ok('/upload')->status_is(500)->content_like(qr{Usage.*upload\(\{ file});

$t->get_ok('/destroy')->status_is(500)->content_like(qr{Usage.*destroy\(\{ public_id});

$t->get_ok('/url-for')->status_is(200)
  ->content_is('http://res.cloudinary.com/test/image/upload/yey.png');

done_testing;

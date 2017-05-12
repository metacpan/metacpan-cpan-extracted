use Mojo::Base -strict;
use Test::More;
use Mojo::IOLoop;
use Mojolicious::Plugin::Cloudinary;

# Set MOJO_USERAGENT_DEBUG=1 if you want to see the actual
# data sent between you and cloudinary.com

plan skip_all => 'API_KEY is not set'    unless $ENV{API_KEY};
plan skip_all => 'API_SECRET is not set' unless $ENV{API_SECRET};
plan skip_all => 'CLOUD_NAME is not set' unless $ENV{CLOUD_NAME};

my $cloudinary = Mojolicious::Plugin::Cloudinary->new(
  {api_key => $ENV{API_KEY}, api_secret => $ENV{API_SECRET}, cloud_name => $ENV{CLOUD_NAME}});

my $res = $cloudinary->upload({file => {file => 't/test.jpg'}});
ok $res->{public_id}, 'upload';
ok $cloudinary->destroy({public_id => $res->{public_id}}), 'destroy';

done_testing;

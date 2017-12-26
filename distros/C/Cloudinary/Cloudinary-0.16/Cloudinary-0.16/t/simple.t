use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Cloudinary;
use Mojo::Asset::File;

use Mojolicious::Lite;
my $RES = {error => 'upload yikes!'};
post '/v1_1/demo/image/upload', sub {
  my $c = shift;
  $c->render(json => $RES);
};
post '/v1_1/demo/image/destroy', sub {
  my $c = shift;
  $c->render(json => {error => 'destroy yikes!'});
};

my $t          = Test::Mojo->new;
my $cloudinary = Cloudinary->new(
  {api_key => '1234567890', api_secret => 'abcd', cloud_name => 'demo', _api_url => '/v1_1'});

$cloudinary->upload(
  Mojo::Asset::File->new(path => $0),
  sub {
    my ($cloudinary, $res) = @_;
    is @_, 2, 'two arguments for upload';
    isa_ok $cloudinary, 'Cloudinary';
    is_deeply $res, {error => 'upload yikes!'}, 'uploaded';
    Mojo::IOLoop->stop;
  }
);
Mojo::IOLoop->start;

$cloudinary->destroy(
  'sample',
  sub {
    my ($cloudinary, $res) = @_;
    is @_, 2, 'two arguments destroy';
    isa_ok $cloudinary, 'Cloudinary';
    is_deeply $res, {error => 'destroy yikes!'}, 'destroyed';
    Mojo::IOLoop->stop;
  }
);
Mojo::IOLoop->start;

eval { $cloudinary->upload(Mojo::Asset::File->new(path => $0)) };
like $@, qr{upload yikes}, 'upload failed';

$RES = {success => 1};
is_deeply $cloudinary->upload(Mojo::Asset::File->new(path => $0)), {success => 1}, 'upload success';

done_testing;

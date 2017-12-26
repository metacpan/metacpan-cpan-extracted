use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::Asset::File;
use Mojo::IOLoop;
use Cloudinary;

use Mojolicious::Lite;
post '/v1_1/demo/image/upload'  => sub { shift->render(json => {}) };
post '/v1_1/demo/image/destroy' => sub { shift->render(json => {}) };

# test data from
# https://cloudinary.com/documentation/upload_images#request_authentication
my $cloudinary
  = Cloudinary->new({api_key => '1234567890', api_secret => 'abcd', cloud_name => 'demo'});

$cloudinary->_ua(Test::Mojo->new->ua);

is(
  $cloudinary->_api_sign_request(
    {timestamp => 1315060510, public_id => 'sample', file => 'foo bar'}
  ),
  'c3470533147774275dd37996cc4d0e68fd03cd4f',
  'signed request'
);

is(
  $cloudinary->_api_sign_request(
    {timestamp => 1315060510, public_id => 'sample/sample', file => 'foo bar'}
  ),
  'ee4e5fc1304c319141776641e32eeb872d8c53d8',
  'signed request with slash'
);

is(
  $cloudinary->_api_sign_request(
    {timestamp => 1315060510, public_id => 'sample;sample', file => 'foo bar', tags => 'foo;bar'}
  ),
  '1e6f96a0722a59b88bd51d190a20c0ba151cdc5d',
  'signed request - only public_id is URL escaped'
);

$cloudinary->_ua->once(
  start => sub {
    my ($ua, $tx) = @_;
    ok($tx, 'upload() generated $tx');
    is($tx->req->url, 'http://api.cloudinary.com/v1_1/demo/image/upload', '...with correct url');
    is($tx->req->param('timestamp'), 1315060510, '...with timestamp');
    is($tx->req->param('public_id'), 'sample',   '...with public_id');
    is(
      $tx->req->param('signature'),
      'c3470533147774275dd37996cc4d0e68fd03cd4f',
      '...with signed request'
    );
    is($tx->req->param('file'), 'http://dumm.y/myimage.png', '...with file as url');
    $tx->req->url->host($ua->server->nb_url->host)->port($ua->server->nb_url->port);
  }
);

# returns an id. need to use once(start) above to run tests
$cloudinary->upload(
  {file => 'http://dumm.y/myimage.png', timestamp => 1315060510, public_id => 'sample'});

for my $file ({file => $0, filename => 'cloudinary.t'}, Mojo::Asset::File->new(path => $0)) {
  $cloudinary->_ua->once(
    start => sub {
      my ($ua, $tx) = @_;
      ok($tx, "upload($file) generated tx");
      is($tx->req->param('timestamp'), 1315060510, '...with timestamp');
      is($tx->req->param('public_id'), 'sample',   '...with public_id');
      is(
        $tx->req->param('signature'),
        'c3470533147774275dd37996cc4d0e68fd03cd4f',
        '...with signed request'
      );
      for my $part (@{$tx->req->content->parts}) {
        if (ref($part->asset) eq 'Mojo::Asset::File') {
          is($part->asset->path, $0, '...$0 in req->content');
          is(
            $part->headers->content_disposition,
            'form-data; name="file"; filename="cloudinary.t"',
            '...filename=$0'
          );
        }
      }
      $tx->req->url->host($ua->server->nb_url->host)->port($ua->server->nb_url->port);
    }
  );

  # returns an id. need to use once(start) above to run tests
  $cloudinary->upload({file => $file, timestamp => 1315060510, public_id => 'sample'});
}

$cloudinary->_ua->once(
  start => sub {
    my ($ua, $tx) = @_;
    ok($tx, 'destroy() generated $tx');
    is($tx->req->url, 'http://api.cloudinary.com/v1_1/demo/image/destroy', '...with correct url');
    is($tx->req->param('timestamp'), 1315060510, '...with timestamp');
    is($tx->req->param('public_id'), 'sample',   '...with public_id');
    is(
      $tx->req->param('signature'),
      '9c549a22def9e2690384973d77b3ff79d7b734d7',
      '...with signed request'
    );    # different key because of "type" is included in POST
    $tx->req->url->host($ua->server->nb_url->host)->port($ua->server->nb_url->port);
  }
);

# returns an id. need to use once(start) above to run tests
$cloudinary->destroy({timestamp => 1315060510, public_id => 'sample'});

is(
  $cloudinary->url_for('sample.gif'),
  'http://res.cloudinary.com/demo/image/upload/sample.gif',
  'url for sample.gif'
);
is(
  $cloudinary->url_for('sample'),
  'http://res.cloudinary.com/demo/image/upload/sample.jpg',
  'url for sample - with default extension .jpg'
);
is(
  $cloudinary->url_for('sample', {w => 100, h => 140}),
  'http://res.cloudinary.com/demo/image/upload/h_140,w_100/sample.jpg',
  'url for sample - with transformation'
);
is(
  $cloudinary->url_for('billclinton.jpg', {type => 'facebook', width => 100, h => 140}),
  'http://res.cloudinary.com/demo/image/facebook/h_140,w_100/billclinton.jpg',
  'url for facebook image',
);

done_testing;

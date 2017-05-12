use utf8;
use warnings;
use strict;
use Test::More;
use Encode 2.21 'decode_utf8', 'encode_utf8';
use HTTP::Request::Common;
use Compress::Zlib;

{
  package MyApp::Controller::Root;
  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub heart :Path('♥') {
    my ($self, $c) = @_;
    $c->response->content_type('text/html');
    $c->response->body("<p>This is path-heart action ♥</p>");
  }

  package MyApp;
  use Catalyst 'Compress';

  MyApp->config(compression_format => 'gzip');
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

if(MyApp->can('encoding') and MyApp->can('clear_encoding') ) {
  ok my $res = request GET '/root/♥', 'Accept-Encoding' => 'gzip';

  is $res->code, 200, 'OK';
  ok my $gunzip = Compress::Zlib::memGunzip($res->content); 
  
  is decode_utf8($gunzip), "<p>This is path-heart action ♥</p>", 'correct body';
  is $res->content_charset, 'UTF-8';
} else {
  ok 1, 'Skipping the UTF8 Tests for older installed catalyst';
}

done_testing;


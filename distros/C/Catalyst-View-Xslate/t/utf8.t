use utf8;
use warnings;
use strict;
use Test::More;
use Encode 2.21 'decode_utf8';
use File::Spec;
use Cwd;

{
  package MyApp;
  $INC{'MyApp.pm'} = __FILE__;

  use Catalyst;

  package MyApp::Controller::Root;
  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub heart :Path('♥') {
    my ($self, $c) = @_;
    $c->stash(hearts=>'♥♥♥');
    $c->res->content_type('text/html');
    $c->detach('View::HTML');
  }
  package MyApp::View::HTML;
  $INC{'MyApp/View/HTML.pm'} = __FILE__;

  use base 'Catalyst::View::Xslate';

  MyApp::View::HTML->config(
    encode_body => 0,
    encoding => 'UTF-8',
    path => [Cwd::abs_path(MyApp->path_to('t'))],
  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';

if(MyApp->can('encoding') and MyApp->can('clear_encoding') ) {
  ok my $res = request '/root/♥';
  is $res->code, 200, 'OK';
  is decode_utf8($res->content), "<p>This heart literal ♥</p><p>This is heart var ♥♥♥</p>\n", 'correct body';
  is $res->content_charset, 'UTF-8';
} else {
  ok 1, 'Skipping the UTF8 Tests for older installed catalyst';
}

done_testing;


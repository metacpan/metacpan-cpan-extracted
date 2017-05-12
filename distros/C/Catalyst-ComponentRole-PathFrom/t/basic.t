use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::Most;
use MyApp;
use Catalyst::Test 'MyApp';
use File::Spec;

sub fileat {
  return  MyApp->config->{root}->file(@_);
}

{
  my ($res, $c) = ctx_request( '/example/test' );
  is $c->model('Path')->path_from, fileat('example/test.html');

  ok my $action = $c->controller('Example')->action_for('test2');
  is $c->model('Path')->path_from($action), fileat('example/test2.html');

  $c->stash(path_from=>'foo');
  is $c->model('Path')->path_from, fileat('foo.html');

  $c->stash(path_from=>':namespace/foo');
  is $c->model('Path')->path_from, fileat 'example/foo.html';

  $c->stash(path_from=>'/foo');
  is $c->model('Path')->path_from,  File::Spec->catfile('/', 'foo.html');

  $c->stash(path_from=>':actionname/foo');
  is $c->model('Path')->path_from, fileat 'test/foo.html';

  $c->stash(path_from=>':reverse/foo');
  is $c->model('Path')->path_from, fileat 'example/test/foo.html';

  is $c->model('Path')->path_from('boo'), fileat 'boo.html';

}

{
  my ($res, $c) = ctx_request( '/example/test3' );
  is $c->model('Path')->path_from, fileat 'ffffff.html';
}

{
  my ($res, $c) = ctx_request( '/example/test4' );
  is $c->model('Path')->path_from, fileat 'example/ffffff.html';
}

done_testing;

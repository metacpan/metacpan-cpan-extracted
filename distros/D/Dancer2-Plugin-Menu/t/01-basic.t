use strict;
use warnings;
use File::Path;
use Data::Dumper qw(Dumper);
use Test::NoWarnings;
use Test::Output;
use Plack::Test;
use HTTP::Request::Common;
use Test::Most tests => 1, 'die';

BEGIN {
  $ENV{'DANCER_ENVIRONMENT'} = 'testing';
}

my $app_obj;

{
  package MyApp;
  use Dancer2;
  use Dancer2::Plugin::Menu;
  use Data::Dumper qw(Dumper);

  get '/' => sub { return 'hi' };
  menu_item(
    { title => 'My Menu Item', weight => 1 },
    get 'test' => sub { template 'index.tt', { html => 'went_down' } }
  );

  menu_item(
    { title => 'A Tom Tom', weight => 3 },
    get 'test/snig' => sub { template }
  );

  menu_item(
    { title => 'Dinky', weight => 3 },
    get 'test/big' => sub { template },
  );

  menu_item(
    { title => 'Deep One', weight => 3 },
    get 'test/snig/one/baloney pony/three' => sub { template 'index.tt', { html => 'booya' } }
  );

#  menu_item(
#    { title => 'My Single', weight => 7 },
#    get 'single' => sub { return 'test' }
#  );

  #print Dumper $app;
#  $app->plugins->[0]->num;
#  $app->plugins->[0]->_do_stuff;
#
#  $app_obj = bless $app, 'MyApp';

}

my $test = Plack::Test->create( MyApp->to_app );
my $res = $test->request( GET 'test/snig/one/baloney pony/three' );
print Dumper $res->content;
$res = $test->request( GET 'test' );
print Dumper $res->content;





#my $menu = Dancer2::Plugin::Menu->new( app => $test);
#    menu_item();
#    my $result = $menu->_convert_routes_to_array;
#    cmp_deeply($result, [ '/', '/test' ], 'returns array of menu paths');

#{ # 12, 13, 14, 15
#  SKIP: {
#    skip 'test_isolation', 3, if $skip;
#    $res = $test->request( GET 'get_toc' );
#    ok( $res->is_success, 'passed option works');
#    like ($res->content, qr/href="#header_0_aprereqs"/, 'generates toc');
#    unlike ($res->content, qr/class="special"/, 'header class doesn\'t carry over');
#    stdout_like {$test->request( GET 'get_toc' )} qr/cache hit\ncache hit\ncache hit/, 'cache works';
#  }
#}
#
#{ # 16
#  SKIP: {
#    $skip = 0;
#    skip 'test_isolation', 1, if $skip;
#    $res = $test->request( GET 'no_resrouce' );
#    ok( $res->is_success, 'missing resource returns legit page' );
#    like ($res->content, qr/route is not properly configured/, 'displays proper message' );
#  }
#}
#
# Delete cached files

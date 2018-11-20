use strict;
use warnings;
use File::Path;
use Data::Dumper qw(Dumper);
use t::Data;
use Test::NoWarnings;
use Test::Output;
use Plack::Test;
use HTTP::Request::Common;
use Test::Most tests => 5, 'die';

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
        { title => 'Deep One', weight => 3 },
        get '/test/snig/one/baloney pony/three' =>
          sub { template 'index.tt', { html => 'booya' } }
    );

    menu_item( { title => 'My Menu Item', weight => 1 },
        get '/test' => sub { template 'index.tt', { html => 'went_down' } } );

    prefix '/test';
    menu_item(
        { title => 'A Tom Tom', weight => 3 },
        get '/snig' => sub { template }
    );

    menu_item(
        { title => 'Dinky', weight => 3 },
        get '/big' => sub { template },
    );

    menu_item( {}, get '/nut' => sub { template }, );

}

my $test = Plack::Test->create( MyApp->to_app );

my $res = $test->request( GET 'test/snig/one/baloney pony/three' );
cmp_deeply( $res->content, $Data::test1, 'returns proper HTML' );

$res = $test->request( GET 'test' );
cmp_deeply( $res->content, $Data::test2, 'returns proper HTML' );

$res = $test->request( GET 'test' );
cmp_deeply( $res->content, $Data::test2, 'returns proper HTML from cache' );

my $plugin = _dispatch_route('test');
my $cache  = $plugin->_html_cache;
cmp_deeply(
    $cache,
    { '/test' => "<ul>\n\t<li class=\"active\">blah</li>\n</ul>" },
    'html menu in cache'
);

my @warnings = grep { $_->{Message} =~ /fallback to PP version/ }
  &Test::NoWarnings::warnings;
&Test::NoWarnings::clear_warnings if @warnings == &Test::NoWarnings::warnings;

sub _dispatch_route {
    my $path = shift;
    my $app  = Dancer2::Core::App->new();
    $app->with_plugins('Menu');
    $app->plugins->[0]->menu_item(
        { title => 'blah' },
        $app->add_route(
            method => 'get',
            regexp => '/' . $path,
            code   => sub { $app->template( 'index.tt', shift ) }
        )
    );

    my $req = Dancer2::Core::Request->new(
        env => {
            SERVER_NAME => 'localhost',
            SERVER_PORT => 8000,
        }
    );
    my $route = $app->routes->{get}->[0];
    $req->{route}   = $route;
    $req->{cookies} = {};
    $app->{request} = $req;
    $route->execute($app);
    return $app->plugins->[0];
}

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

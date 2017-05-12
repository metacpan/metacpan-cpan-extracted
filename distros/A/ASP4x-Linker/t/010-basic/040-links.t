#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $api; BEGIN { $api = ASP4::API->new }

use_ok('ASP4x::Linker');
use_ok('Router::Generic');

NO_VARS: {
  $api->ua->get('/');

  my $linker = ASP4x::Linker->new();

  $linker->add_widget(
    name  => "widgetA",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetB",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetC",
    attrs => [qw/ size type color /]
  );

  $linker->add_widget(
    name  => "widgetD",
    attrs => [qw/ size type color /]
  );
  


  is( $linker->uri() => '/', "/" );

  is(
    $linker->uri({
      widgetA => { page_number => 2 }
    }) => '/?widgetA.page_number=2'
  );

  is(
    $linker->uri({
      widgetA => {
        page_number => 2,
        page_size   => 20,
        sort_col    => 'name',
        sort_dir    => 'ASC'
      }
    }) => '/?widgetA.page_number=2&widgetA.page_size=20&widgetA.sort_col=name&widgetA.sort_dir=ASC'
  );
};



WITH_VARS: {
  $api->ua->get('/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat');

  my $linker = ASP4x::Linker->new();

  $linker->add_widget(
    name  => "widgetA",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetB",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetC",
    attrs => [qw/ size type color /]
  );

  $linker->add_widget(
    name  => "widgetD",
    attrs => [qw/ size type color /]
  );


  is(
    $linker->uri() => '/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat',
    '/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetA => { page_number => 2 }
    }) => '/?widgetA.page_number=2&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetA => {
        page_number => 2,
        page_size   => 20,
        sort_col    => 'name',
        sort_dir    => 'ASC'
      }
    }) => '/?widgetA.page_number=2&widgetA.page_size=20&widgetA.sort_col=name&widgetA.sort_dir=ASC&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetA => {
        page_number => 2,
        page_size   => 20,
        sort_col    => 'name',
        sort_dir    => 'ASC'
      },
      widgetB => {
        page_size => 10
      }
    }) => '/?widgetA.page_number=2&widgetA.page_size=20&widgetA.sort_col=name&widgetA.sort_dir=ASC&widgetB.page_size=10&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetB => {
        page_size => 10
      },
      widgetC => {
        color => 'red'
      },
      widgetD => {
        color => 'orange'
      }
    }) => '/?widgetA.page_number=24&widgetB.page_size=10&widgetC.color=red&widgetD.color=orange&widgetD.type=hat'
  );

  is(
    $linker->uri({
      NO_EXISTO => { blah => 'blech' },
      widgetB => {
        page_size => 10
      },
      widgetC => {
        color => 'red'
      },
      widgetD => {
        color => 'orange'
      }
    }) => '/?widgetA.page_number=24&widgetB.page_size=10&widgetC.color=red&widgetD.color=orange&widgetD.type=hat'
  );
};



WITH_VARS_AND_ROUTER: {

  my $router = Router::Generic->new();
  $router->add_route(
    name    => 'FooRoute',
    path    => '/foo/:bar/baz',
    target  => '/index.asp',
    method  => 'GET'
  );

  $api->ua->get('/');
  $api->context->config->web->{router} = $router;
  $api->ua->get('/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat');
  
  my $linker = ASP4x::Linker->new();

  $linker->add_widget(
    name  => "widgetA",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetB",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetC",
    attrs => [qw/ size type color /]
  );

  $linker->add_widget(
    name  => "widgetD",
    attrs => [qw/ size type color /]
  );
  
  is_deeply $linker->widget('widgetA')->vars, {
    page_number => 24,
    page_size   => undef,
    sort_col    => undef,
    sort_dir    => undef,
  }, 'widgetA.vars';


  is(
    $linker->uri() => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat',
    '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );
  
  is(
    $linker->uri({yay=>'woot'}) => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat&yay=woot',
    '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat&yay=woot'
  );
  

  is(
    $linker->uri({
      widgetA => { page_number => 2 }
    }) => '/foo/bar/baz/?widgetA.page_number=2&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetA => {
        page_number => 2,
        page_size   => 20,
        sort_col    => 'name',
        sort_dir    => 'ASC'
      }
    }) => '/foo/bar/baz/?widgetA.page_number=2&widgetA.page_size=20&widgetA.sort_col=name&widgetA.sort_dir=ASC&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetA => {
        page_number => 2,
        page_size   => 20,
        sort_col    => 'name',
        sort_dir    => 'ASC'
      },
      widgetB => {
        page_size => 10
      }
    }) => '/foo/bar/baz/?widgetA.page_number=2&widgetA.page_size=20&widgetA.sort_col=name&widgetA.sort_dir=ASC&widgetB.page_size=10&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetB => {
        page_size => 10
      },
      widgetC => {
        color => 'red'
      },
      widgetD => {
        color => 'orange'
      }
    }) => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=10&widgetC.color=red&widgetD.color=orange&widgetD.type=hat'
  );

  is(
    $linker->uri({
      NO_EXISTO => { blah => 'blech' },
      widgetB => {
        page_size => 10
      },
      widgetC => {
        color => 'red'
      },
      widgetD => {
        color => 'orange'
      }
    }) => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=10&widgetC.color=red&widgetD.color=orange&widgetD.type=hat'
  );
  
  $linker->widget('widgetB')->set( page_size => 20 );
  is(
    $linker->uri() => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=20&widgetC.color=blue&widgetD.type=hat',
    'widgetB.page_size = 20'
  );

  is(
    $linker->uri({
      widgetB => {
        page_size => 10
      },
      widgetC => {
        color => 'red'
      },
      widgetD => {
        color => 'orange'
      }
    }) => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=10&widgetC.color=red&widgetD.color=orange&widgetD.type=hat'
  );

  is(
    $linker->uri() => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat',
    '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );
  
  $linker->reset();
  is(
    $linker->uri() => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat',
    '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );
};



WITH_VARS_AND_ROUTER_POSTED: {
last;
  my $router = Router::Generic->new();
  $router->add_route(
    name    => 'FooRoute',
    path    => '/foo/:bar/baz',
    target  => '/index.asp',
    method  => '*'
  );

  $api->ua->get('/');
  $api->context->config->web->{router} = $router;
  $api->ua->post('/foo/bar/baz/', {
    'widgetA.page_number' => 24,
    'widgetB.page_size'   => 100,
    'widgetC.color'       => 'blue',
    'widgetD.type'        => 'hat',
  });
  
  my $linker = ASP4x::Linker->new();

  $linker->add_widget(
    name  => "widgetA",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetB",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetC",
    attrs => [qw/ size type color /]
  );

  $linker->add_widget(
    name  => "widgetD",
    attrs => [qw/ size type color /]
  );
  
  
  is_deeply $linker->widget('widgetA')->vars, {
    page_number => 24,
    page_size   => undef,
    sort_col    => undef,
    sort_dir    => undef,
  }, 'widgetA.vars';


  is(
    $linker->uri() => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat',
    '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetA => { page_number => 2 }
    }) => '/foo/bar/baz/?widgetA.page_number=2&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetA => {
        page_number => 2,
        page_size   => 20,
        sort_col    => 'name',
        sort_dir    => 'ASC'
      }
    }) => '/foo/bar/baz/?widgetA.page_number=2&widgetA.page_size=20&widgetA.sort_col=name&widgetA.sort_dir=ASC&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetA => {
        page_number => 2,
        page_size   => 20,
        sort_col    => 'name',
        sort_dir    => 'ASC'
      },
      widgetB => {
        page_size => 10
      }
    }) => '/foo/bar/baz/?widgetA.page_number=2&widgetA.page_size=20&widgetA.sort_col=name&widgetA.sort_dir=ASC&widgetB.page_size=10&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetB => {
        page_size => 10
      },
      widgetC => {
        color => 'red'
      },
      widgetD => {
        color => 'orange'
      }
    }) => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=10&widgetC.color=red&widgetD.color=orange&widgetD.type=hat'
  );

  is(
    $linker->uri({
      NO_EXISTO => { blah => 'blech' },
      widgetB => {
        page_size => 10
      },
      widgetC => {
        color => 'red'
      },
      widgetD => {
        color => 'orange'
      }
    }) => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=10&widgetC.color=red&widgetD.color=orange&widgetD.type=hat'
  );
  
  $linker->widget('widgetB')->set( page_size => 20 );
  is(
    $linker->uri() => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=20&widgetC.color=blue&widgetD.type=hat',
    '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=20&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetB => {
        page_size => 10
      },
      widgetC => {
        color => 'red'
      },
      widgetD => {
        color => 'orange'
      }
    }) => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=10&widgetC.color=red&widgetD.color=orange&widgetD.type=hat'
  );

  is(
    $linker->uri() => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat',
    '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );
  
  $linker->reset();
  is(
    $linker->uri() => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat',
    '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=100&widgetC.color=blue&widgetD.type=hat'
  );

  is(
    $linker->uri({
      widgetB => {
        page_size => 10
      },
      widgetC => {
        color => 'red@hot'
      },
      widgetD => {
        color => 'orange'
      }
    }) => '/foo/bar/baz/?widgetA.page_number=24&widgetB.page_size=10&widgetC.color=red%40hot&widgetD.color=orange&widgetD.type=hat'
  );
};


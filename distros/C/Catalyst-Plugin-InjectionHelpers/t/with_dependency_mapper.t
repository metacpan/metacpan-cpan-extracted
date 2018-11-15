use Scalar::Util qw/refaddr/;

BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
  eval "use Catalyst::Plugin::MapComponentDependencies; 1" || do {
    plan skip_all => "Need a Catalyst::Plugin::MapComponentDependencies => $@";
  };
  eval "use Catalyst::Plugin::MapComponentDependencies::Utils; 1" || do {
    plan skip_all => "Need a Catalyst::Plugin::MapComponentDependencies::Utils => $@";
  };
}

BEGIN {
  package MyApp::Role::Foo;
  $INC{'MyApp/Role/Foo.pm'} = __FILE__;

  use Moose::Role;

  sub foo { 'foo' }

  package MyApp::Singleton;
  $INC{'MyApp/Singleton.pm'} = __FILE__;

  use Moose;

  has aaa => (is=>'ro', required=>1);
  has bbb => (is=>'ro');

  package MyApp::PerRequest;
  $INC{'MyApp/Singleton.pm'} = __FILE__;

  use Moose;

  has ctx => (
    is=>'ro',
    required=>1,
    isa=>'Object',
    weak_ref=>1);
}

{
  package MyApp::Model::Normal;
  $INC{'MyApp/Model/Normal.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model';

  has ccc => (is=>'ro', required=>1);

  package MyApp::Controller::Example;
  $INC{'MyApp/Controller/Example.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub test :Local Args(0) {
    my ($self, $c) = @_;
    $c->res->body('test');
  }

  package MyApp;

  use Catalyst 'InjectionHelpers', 'MapComponentDependencies';
  use Catalyst::Plugin::MapComponentDependencies::Utils 'FromContext';


  MyApp->inject_components(
    'Model::FromCode' => { from_code => sub { my ($app, %args) = @_;  return bless {a=>1}, 'AAAA' } },
    'Model::SingletonA' => { from_class=>'MyApp::Singleton', adaptor=>'Application', roles=>['MyApp::Role::Foo'], method=>'new' },
    'Model::SingletonB' => {
      from_class => 'MyApp::Singleton', 
      adaptor => 'Application', 
      roles => ['MyApp::Role::Foo'], 
      method => sub {
        my ($from_class, $app, %args) = @_;
        return $from_class->new(aaa=>$args{arg});
      },
    },
    'Model::PerRequest2' => {
      from_class=>'MyApp::PerRequest',
      adaptor=>'PerRequest',
      roles=>['MyApp::Role::Foo'],
    },
    'Model::PerRequest' => { from_class=>'MyApp::Singleton', adaptor=>'PerRequest' },

  );

  MyApp->config(
    'Plugin::InjectionHelpers' => {
      dispatchers => {
        '-my' => sub {
          my ($app_ctx, $what) = @_;
          warn "asking for a -my $what";
          return 1;
        },
      },
    },
    'Model::SingletonA' => { aaa=>100 },
    'Model::SingletonB' => { arg=>300 },
    'Model::Factory' => {
      -inject => { from_class=>'MyApp::Singleton', adaptor=>'Factory' },
      aaa => 444,
      user => { -model => 'SingletonA' },
      ctx => { -core => '$ctx' }
    },
    'Model::Normal' => { ccc=>200 },
    'Model::PerRequest2' => {
      ctx => FromContext,
    },
    'Model::AllCode1' => {
      -name => 'one',
      -inject => { 
        from_code => sub {
          my ($ctx, %args) = @_;
          return bless {a=>111}, '111';

        },
        adaptor => 'Factory',
      },
    },
    'Model::AllCode2' => {
      -name => 'two',
      -inject => {
        adaptor => 'Factory',
        from_code => sub {
          my ($ctx, %args) = @_;
          return bless {a=>\%args}, '111';
        },
      },
      one => { -model => 'AllCode1' },
      two => { -code => sub { return shift } },
    },

  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request( '/example/test' );
  is $c->model('Normal')->ccc, 200;
  is $c->model('SingletonA')->aaa, 100;
  is $c->model('SingletonA')->foo, 'foo';
  is $c->model('SingletonB')->aaa, 300;
  is $c->model('SingletonB')->foo, 'foo';
  is refaddr($c->model('SingletonB')), refaddr($c->model('SingletonB'));
  is $c->model('FromCode')->{a}, 1;
  ok $c->model('PerRequest2')->ctx->isa('MyApp');

  {
    ok my $f = $c->model('Factory', bbb=>'bbb');
    is $f->aaa, 444;
    is $f->bbb, 'bbb';
    isnt refaddr($f), refaddr($c->model('Factory'));
    isnt refaddr($c->model('Factory')), refaddr($c->model('Factory'));
  }

  {
    ok my $p = $c->model('PerRequest', aaa=>1, bbb=>2);
    is $p->aaa, 1;
    is $p->bbb, 2;
    is refaddr($p), refaddr($c->model('PerRequest'));

    {
      my ($res, $c) = ctx_request( '/example/test' );
      ok my $p2 = $c->model('PerRequest', aaa=>3, bbb=>4);
      is $p2->aaa, 3;
      is $p2->bbb, 4;
      is refaddr($p2), refaddr($c->model('PerRequest'));
      isnt refaddr($p), refaddr($c->model('PerRequest'));
      isnt refaddr($p), refaddr($p2);
      ok $c->model('AllCode2');
    }
  }
}

done_testing;

package Catalyst::Plugin::InjectionHelpers;

use Moose::Role;
use Catalyst::Utils;
use Catalyst::Model::InjectionHelpers::Application;
use Catalyst::Model::InjectionHelpers::Factory;
use Catalyst::Model::InjectionHelpers::PerRequest;

requires 'setup_injected_component',
  'setup_injected_components',
  'config_for';

our $VERSION = '0.015';

my $adaptor_namespace = sub {
  my $app = shift;
  if(my $config = $app->config->{'Plugin::InjectionHelpers'}) {
    my $namespace = $config->{adaptor_namespace};
    return $namespace if $namespace;
  }
  return 'Catalyst::Model::InjectionHelpers';
};

my $default_adaptor = sub {
  my $app = shift;
  if(my $config = $app->config->{'Plugin::InjectionHelpers'}) {
    my $default_adaptor = $config->{default_adaptor};
    return $default_adaptor if $default_adaptor;
  }
  return 'Application';
};

my $normalize_adaptor = sub {
  my $app = shift;
  my $adaptor = shift || $app->$default_adaptor;
  return $adaptor=~m/::/ ? 
    $adaptor : "${\$app->$adaptor_namespace}::$adaptor";
};

my $debug = 1;
my $version = 2;
my %core_dispatch = (
  '$app' => sub {
      my $proto = shift; 
      my $maybe_app = ref $proto;
      return $maybe_app ? $maybe_app : $proto;
  },
  '$ctx' => sub { shift },
  '$req' => sub { shift->req },
  '$res' => sub { shift->res },
  '$log' => sub { shift->log },
  '$user' => sub { shift->user },
);

my %dispatch_table = (
  '-core' => sub {
    my ($app_ctx, $what) = @_;
    return $core_dispatch{$what}->($app_ctx);
  },
  '-code' => sub { 
    my ($app_ctx, $code) = @_;
    $app_ctx->log->debug("Executing code injection.") if $app_ctx->debug && $debug;
    do {
      $app_ctx->log->error("Provided value '$code' not a coderef.");
      return undef;
    } unless (ref($code) && ref($code) eq 'CODE');
    return $code->($app_ctx);
  },
  '-model' => sub {
    my ($app_ctx, $model) = @_;
    $app_ctx->log->debug("Providing model '$model' for injection.") if $app_ctx->debug && $debug;
    return $app_ctx->model($model);
  },
  '-view' => sub {
    my ($app_ctx, $view) = @_;
    $app_ctx->log->debug("Providing view '$view' for injection.") if $app_ctx->debug && $debug;
    return $app_ctx->view($view);
  },
  '-controller' => sub {
    my ($app_ctx, $controller) = @_;
    $app_ctx->log->debug("Providing controller '$controller' for injection.") if $app_ctx->debug && $debug;
    return $app_ctx->controller($controller);
  },
);

before 'setup_components', sub {
  my ($c) = @_;
  if (my $config = $c->config->{'Plugin::InjectionHelpers'}) {
    if(my $custom_dispatch = $config->{dispatchers}) {
      %dispatch_table = %{ Catalyst::Utils::merge_hashes(\%dispatch_table, $custom_dispatch) };
    }
    if(defined(my $has_debug_flag = $config->{debug})) {
      $debug = $has_debug_flag;
    }
    if(defined(my $has_version = $config->{version})) {
      $version = $has_version;
    }
  }
};

before 'setup_injected_components', sub {
  my ($class) = @_;
  my @injectables = grep {
    ($_ =~ m/^Model/) 
    || ($_ =~ m/^Controller/)
    || ($_ =~ m/^View/)
  } keys %{$class->config};
  foreach my $comp (@injectables) {
    next unless my $inject = delete $class->config->{$comp}->{'-inject'};
    $class->config->{inject_components}->{$comp} = $inject;
  }
};

after 'setup_injected_component', sub {
  my ($app, $injected_component_name, $config) = @_;
  if(exists($config->{from_class}) || exists($config->{from_code})) {
    my $from_class = $config->{from_class} || undef;
    my $adaptor = $app->$normalize_adaptor($config->{adaptor});
    my $method = $config->{method} || $config->{from_code} || 'new';
    my @roles = @{$config->{roles} ||[]};

    Catalyst::Utils::ensure_class_loaded($from_class) if $from_class;
    Catalyst::Utils::ensure_class_loaded($adaptor);

    my $from = $from_class || $config->{from_code};
    my $config_namespace = $app .'::'. $injected_component_name;

    $app->components->{$config_namespace} = sub { 
      my $new_component = $adaptor->new(
        _version=>$version,
        application=>$app,
        from=>$from,
        injected_component_name=>$injected_component_name,
        method=>$method,
        roles=>\@roles,
        injection_parameters=>$config,
        ( exists $config->{transform_args} ? (transform_args => $config->{transform_args}) : ()),
        get_config=> sub { shift->config_for($config_namespace) },
      );
      return $app->setup_component($new_component);
    };
  }
};

around 'config_for', sub {
  my ($orig, $app_or_ctx, $component_name, @args) = @_;
  my $config = ($app_or_ctx->$orig($component_name, @args) || +{});
  my $mapped_config = +{};
  foreach my $key (keys %{$config||+{}}) {
    if(ref(my $proto = $config->{$key}) eq 'HASH') {
      my ($type) = keys %{$proto};
      if(my $dispatchable = $dispatch_table{$type}) {
        my $dependency = $dispatchable->($app_or_ctx, $proto->{$type});
        if($dependency) {
          $mapped_config->{$key} = $dependency;
        } else {
          $app_or_ctx->log->debug("No dependency type '$type' of '$proto->{$type}' for '$component_name'")
            if $app_or_ctx->debug;
        }
      } else {
        $app_or_ctx->log->debug("Can't inject dependency '$type' for '$component_name'")
          if $app_or_ctx->debug;
      }
    }
  }
  return my $merged = Catalyst::Utils::merge_hashes($config, $mapped_config);
};

1;

=head1 NAME

Catalyst::Plugin::InjectionHelpers - Enhance Catalyst Component Injection

=head1 SYNOPSIS

Use the plugin in your application class:

    package MyApp;
    use Catalyst 'InjectionHelpers';

    MyApp->config(
      'Model::SingletonA' => {
        -inject => {
          from_class=>'MyApp::Singleton', 
          adaptor=>'Application', 
          roles=>['MyApp::Role::Foo'],
          method=>'new',
        },
        aaa => 100,
      },
      'Model::SingletonB' => {
        -inject => {
          from_class=>'MyApp::Singleton', 
          adaptor=>'Application', 
          method=>sub {
            my ($adaptor_instance, $from_class, $app, %args) = @_;
            return $from_class->new(aaa=>$args{arg});
        },
        arg => 300,
      },
    );

    MyApp->setup;

Alternatively you can use the 'inject_components' class method:

    package MyApp;
    use Catalyst 'InjectionHelpers';

    MyApp->inject_components(
      'Model::SingletonA' => {
        from_class=>'MyApp::Singleton', 
        adaptor=>'Application', 
        roles=>['MyApp::Role::Foo'],
        method=>'new',
      },
      'Model::SingletonB' => {
        from_class=>'MyApp::Singleton', 
        adaptor=>'Application', 
        method=>sub {
          my ($adaptor_instance, $from_class, $app, %args) = @_;
          return $class->new(aaa=>$args{arg});
        },
      },
    );

    MyApp->config(
      'Model::SingletonA' => { aaa=>100 },
      'Model::SingletonB' => { arg=>300 },
    );

    MyApp->setup;

The first method is a better choice if you need to alter how your injections work
based on configuration that is controlled per environment.

=head1 DESCRIPTION

B<NOTE> Starting with C<VERSION> 0.012 there is a breaking change in the number
of arguments that the C<method> and C<from_code> callbacks get.  If you need to
keep backwards compatibility you should set the version flag to 1:

    MyApp->config(
      'Plugin::InjectionHelpers' => { version => 1 },
      ## Additional configuration as needed
    );

This plugin enhances the build in component injection features of L<Catalyst>
(since v5.90090) to make it easy to bring non L<Catalyst::Component> classes
into your application.  You may consider using this for what you often used
L<Catalyst::Model::Adaptor> in the past for (although there is no reason to
stop using that if you are doing so, its not a 'broken' approach, but for the
very simple cases this might suffice and allow you to reduce the number of nearly
empty 'boilerplate' classes in your application.)

You should be familiar with how component injection works in newer versions of
L<Catalyst> (v5.90090+).

It also experimentally supports a mechanism for dependency injection (that is
the ability to set other componements as initialization arguments, similar to
how you might see this work with inversion of control frameworks such as
L<Bread::Board>.)  Author has no plan to move this past experimental status; he
is merely publishing code that he's used on jobs where the code worked for the
exact cases he was using it for the purposes of easing long term maintainance
on those projects.  If you like this feature and would like to see it stablized
it will be on you to help the author validate it; its not impossible more changes
and pontentially breaking changes will be needed to make that happen, and its
also not impossible that changes to core L<Catalyst> would be needed as well.
Reports from users in the wild greatly appreciated.

=head1 USAGE

    MyApp->config(
      $model_name => +{ 
        -inject => +{ %injection_args },
        \%configuration_args;
or

    MyApp->inject_components($model_name => \%injection_args);
    MyApp->config($model_name => \%configuration_args);


Where C<$model_name> is the name of the component as it is in your L<Catalyst>
application (ie 'Model::User', 'View::HTML', 'Controller::Static') and C<%injection_args>
are key /values as described below:

=head2 from_class

This is the full namespace of the class you are adapting to use as a L<Catalyst>
component.  Example 'MyApp::Class'.

=head2 from_code

This is a codereference that generates your component instance.  Used when you
don't have a class you wish to adapt (handy for prototyping or small components).

    MyApp->inject_components(
      'Model::Foo' => {
        from_code => sub {
          my ($app_ctx, %args) = @_;
          return $XX;
        },
        adaptor => 'Factory',
      },
    );

C<$app_ctx> is either the application class or L<Catalyst> context, depending on the
scope of your component.

If you use this you should not define the 'method' key or the 'roles' key (below).

=head2 roles

A list of L<Moose::Roles>s that will be composed into the 'from_class' prior
to creating an instance of that class.  Useful if you apply roles for debugging
or testing in certain environments.

=head2 method

Either a string or a coderef. If left empty this defaults to 'new'.

The name of the method used to create the adapted class instance.  Generally this
is 'new'.  If you have complex instantiation requirements you may instead use
a coderef. If so, your coderef will receive three arguments. The first is the name
of the from_class.  The second is either
the application or context, depending on the type adaptor.  The third is a hash
of arguments which merges the global configuration for the named component along
with any arguments passed in the request for the component (this only makes
sense for non application scoped models, btw).

Example:

    MyApp->inject_components(
      'Model::Foo' => {
        from_class => 'Foo',
        method => sub {
          my ($from_class, $app_or_ctx, %args) = @_;
        },
        adaptor => 'Factory',
      },
    );

Argument details:

=over 4

=item $from_class

The name of the class you set in the 'from_class' parameter.

=item $app_or_ctx

Either your application class or a reference to the current context, depending on how
the adaptore is scoped (PerRequest and Factory get $ctx).

=item %args

A Hash of the configuration parameters from your application configuration.  If the
adaptor is context/request scoped, also combines any arguments included in the call
for the component.  for example:

    package MyApp;

    use Catalyst;

    MyApp->inject_components( 'Model::Foo' => { from_class=>"Foo", adaptor=>'Factory' });
    MyApp->config( 'Model::Foo' => { aaa => 111 } )
    MyApp->setup;

If in an action you say:

    my $model = $c->model('Foo', bbb=>222);

Then C<%args> would be:

    (aaa=>111, bbb=>222);

B<NOTE> Please keep in mind supplying arguments in the ->model call (or ->view for
that matter) only makes sense for components that ACCEPT_CONTEXT (in this case
are Factory, PerRequest or PerSession adaptor types).

=back

=head2 transform_args

A coderef that you can use to transform configuration arguments into something
more suitable for your class.  For example, the configuration args is typically
a hash, but your object class may require some positional arguments.

    MyApp->inject_components(
      'Model::Foo' => {
        from_class = 'Foo',
        transform_args => sub {
          my (%args) = @_;
          my $path = delete $args{path},
          return ($path, %args);
        },
      },
    );

Should return the args as they as used by the initialization method of the
'from_class'.

Use 'transform_args' when you just need to tweak how your object uses arguments
and use 'from_code' or 'method' when you need more control on what kind of object
is returned (in other words choose the smallest hammer for the job).

=head2 adaptor

The adaptor used to bring your 'from_class' into L<Catalyst>.  Out of the box
there are three adaptors (described in detail below): Application, Factory and
PerRequest.  The default is Application.  You may create your own adaptors; if
you do so you should use the full namespace as the value (MyApp::Adaptors::MySpecialAdaptor).

=head1 ADAPTORS

Out of the box this plugin comes with the following three adaptors. All canonical
adaptors are under the namespace 'Catalyst::Model::InjectionHelpers'.

=head2 Application

Model is application scoped.  This means you get one instance shared for the entire
lifecycle of the application.

=head2 Factory

Model is scoped to the request. Each call to $c->model($model_name) returns a new
instance of the model.  You may pass additional parameters in the model call,
which are merged to the global parameters defined in configuration and used as
part of the object initialization.

=head2 PerRequest

Model is scoped to the request. The first time in a request that you call for the
model, a new model is created.  After that, all calls to the model return the original
instance, until the request is completed, after which the instance is destroyed when
the request goes out of scope.

The first time you call this model you may pass additional parameters, which get
merged with the global configuration and used to initialize the model.

=head2 PerSession.

Scoped to a session.  Requires the Session plugin.
See L<Catalyst::Model::InjectionHelpers::PerSession> for more.

=head2 Creating your own adaptor

Your new adaptor should consume the role L<Catalyst::ModelRole::InjectionHelpers>
and provide a method ACCEPT_CONTEXT which must return the component you wish to
inject.  Please review the existing adaptors and that role for insights.

=head1 DEPENDENCY INJECTION

Often when you are setting configuration options for your components, you might
desire to 'depend on' other existing components.  This design pattern is called
'Inversion of Control', and you might be familiar with it from prior art on CPAN
such as L<IOC>, L<Bread::Board> and L<Beam::Wire>.

The IOC features that are exposed via this plugin are basic and marked experimental
(please see preceding note).  The are however presented to the L<Catalyst> community
with the hope of provoking thought and discussion (or at the very least put an
end to the idea that this is something people actually care about).

To use this feature you simply tag configuration keys as 'dependent' using a
hashref for the key value.  For example, here we define an inline model that
is a L<DBI> C<$dbh> and a User model that depends on it:

    MyApp->config(
      'Model::DBH' => {
        -inject => {
          adaptor => 'Application',
          from_code => sub {
            my ($app, @args) = @_;
            return DBI->connect(@args);
          },
        },
        %DBI_Connection_Args,
      },
      'Model::User' => {
        -inject => {
          from_class => 'MyApp::User',
          adaptor => 'Factory',
        },
        dbh => { -model => 'DBH' },
      },
      # Additional configuration as needed
    );

Now in you code (say in a controller if you do:

    my $user = $c->model('User');

We automatically resolve the value for C<dbh> to be $c->model('DBH') and
supply it as an argument.

Currently we only support dependency substitutions on the first level of
arguments.

All injection syntax takes the form of "$argument_key => { $type => $parameter }"
where the following $types are supported

=over 4

=item -model => $model_name

=item -view => $view_name

=item -controller => $controller_name

Provide dependency in the form of $c->model($model_name) (or $c->view($view_name), 
$c->controller($controller_name)).

=item -code => $subref

Custom dependency that resolves from a subref.  Example:

    MyApp->config(
      'Model::User' => {
        current_time => {
          -code => sub {
            my $app_or_context = shift;
            return DateTime->now;
          },
        },
      },
      # Rest of configuration
    );

Please keep in mind that you must return an object.  C<$app_or_context> will be
either the application class or $c (context) depending on the type of model (if
it accepts context or not).

=item -core => $target

This exposes some core objects such as $app, $c etc.  Where $target is:

=over 8

=item $app

The name of the application class.

=item $ctx

The result of C<$c>.  Please note its probably bad form to pass the entire
context object as it leads to unnecessary tight coupling.

=item $req

The result of C<< $c->req >>

=item $res

The result of C<< $c->res >>

=item $log

The result of C<< $c->log >>

=item $user

The result of C<< $c->user >> (if it exists, you should either define it or
use the Authentication plugin).

=back

=back

=head1 CONFIGURATION

This plugin defines the following possible configuration.  As per L<Catalyst>
standards, these configuration keys fall under the 'Plugin::InjectionHelpers'
namespace in the configuration hash.

=head2 adaptor_namespace

Default namespace to look for adaptors.  Defaults to L<Catalyst::Model::InjectionHelpers>

=head2 default_adaptor

The default adaptor to use, should you not set one.  Defaults to 'Application'.

=head2 dispatchers

Allows you to add to the default dependency injection handers:

    MyApp->config(
      'Plugin::InjectionHelpers' => {
        dispatchers => {
          '-my' => sub {
            my ($app_ctx, $what) = @_;
            warn "asking for a -my $what";
            return ....;
          },
        },
      },
      # Rest of configuration
    );

=head2 version

Default is 2.  Set to 1 if you are need compatibility version 0.011 or older
style of arguments for 'method' and 'from_code'.

=head1 Catalyst::Plugin::ConfigLoader

When using this plugin with L<Catalyst::Plugin::ConfigLoader> you should add it to the
plugin list afterward, for example:

    package MyApp;

    use Catalyst 'ConfigLoader', 
      'InjectionHelpers';

Please keep in mind that due to the way Configloader merges the configuration files
you might have to set some things to C<undef> in order to get the correct behavior.  For
example you might define a model by default using from_code:

    package MyApp;

    use Catalyst 'ConfigLoader', 
      'InjectionHelpers';

    MyApp->config(
      'Model::Foo' => {
        -inject => {
          from_code => sub {
            my ($app, %args) = @_;
            return bless +{ %args, app=>$app }, 'Dummy1';
          },
        },
        bar => 'baz',
      },
    );

    MyApp->setup;

But then in youe configuration file overlay, you want to specify a class.  In that case you
will need to undefine the default keys:

    # File:myapp_local.pl
    return +{
      'Model::Foo' => {
        -inject => {
          from_class => 'MyApp::Dummy2',
          from_code => undef, # Need to blow away the existing...
        },
      },
    };

Its probably not ideal that the configuration overlay doesn't permit you to tag refs as 'replace'
rather than 'merge' but this is not a problem with this plugin.  If it bothers you that a
configuration overlay would require to have understanding of how 'lower' configurations are setup
you should be able to avoid it by using all the same keys.

=head1 PRIOR ART

You may wish to review other similar approach on CPAN:

L<Catalyst::Model::Adaptor>.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Model::InjectionHelpers::Application>,
L<Catalyst::Model::InjectionHelpers::Factory>, L<Catalyst::Model::InjectionHelpers::PerRequest>
L<Catalyst::ModelRole::InjectionHelpers>

=head1 COPYRIGHT & LICENSE
 
Copyright 2016, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut

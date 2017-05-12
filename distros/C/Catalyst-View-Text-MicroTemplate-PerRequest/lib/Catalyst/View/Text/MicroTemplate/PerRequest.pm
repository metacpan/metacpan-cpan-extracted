package Catalyst::View::Text::MicroTemplate::PerRequest;

use Moo;
use CatalystX::InjectComponent;
use Catalyst::View::Text::MicroTemplate::_PerRequest;

our $VERSION = 0.005;
our $DEFAULT_MT_CLASS = 'Text::MicroTemplate::Extended';
our $DEFAULT_VIEW_MODEL = 'Text::MicroTemplate::ViewData';

extends 'Catalyst::View';
with 'Catalyst::Component::InstancePerContext';

has merge_stash => (is=>'ro', required=>1, default=>sub { 0 });

has path_base => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_path_base');
 
  sub _build_path_base {
    my $self = shift;
    my $root = $self->app->config->{root};
    die "No directory '$root'" unless -e $root;
    return $root;
  }

has extension => (is=>'ro',default=>sub { '.mt' });
has content_type => (is=>'ro', required=>1, default=>sub { 'text/plain' });
has template_args => (is => 'ro', required=>1, default=>sub { +{} });
has macros => (is => 'ro', required=>1, default=>sub { +{} });

has mt => (
  is=>'ro',
  required=>1,
  lazy=>1,
  default=>sub {
    my $self = shift;
    eval "use ${\$self->mt_class}; 1" ||
      die "Can't use ${\$self->mt_class}, $@";

    return $self->mt_class->new(
      extension => $self->extension,
      include_path => [$self->path_base],
      template_args => $self->template_args,
      macros => $self->macros,
      %{$self->mt_init_args});
  });

sub HANDLE_PROCESS_ERROR {
  my ($view, $err) = @_;
  my $template = $view->template;
  $view->template('500');
  $view->detach_internal_server_error({ error => "$err", template => $template});
}

has handle_process_error => (
  is=>'ro',
  predicate=>'has_handle_process_error');

has default_view_model => (
  is=>'ro',
  required=>1,
  default=>sub {
    return $DEFAULT_VIEW_MODEL;
  });

has mt_class => (
  is=>'ro',
  required=>1,
  default=>sub {
    return $DEFAULT_MT_CLASS;
  });

has mt_init_args => (is=>'ro', required=>1, default=>sub { +{} });
has app => (is=>'ro');

has default_template_factory => (
  is=>'ro',
  required=>1,
  default=>sub {
    return sub {
      my ($view, $ctx) = @_;
      return $ctx->stash->{template}
        || "${\$ctx->action}";
    };
  });

sub COMPONENT {
  my ($class, $app, $args) = @_;
  $args = $class->merge_config_hashes($class->config, $args);
  $args->{app} = $app;
  $class->_inject_default_view_model_into($app);
  return $class->new($app, $args);
}

sub _inject_default_view_model_into {
  my ($class, $app) = @_;
  CatalystX::InjectComponent->inject(
    into => $app,
    component => 'Catalyst::Model::Text::MicroTemplate::ViewData',
    as => 'Model::Text::MicroTemplate::ViewData' );
}

sub _create_has_process_error_param {
  my $self = shift;
  return $self->has_handle_process_error ?
    (handle_process_error=>$self->handle_process_error) : ();
}

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return bless +{
    ctx=>$c,
    parent=>$self,
    mt=>$self->mt,
    ($self->_create_has_process_error_param),
  }, 'Catalyst::View::Text::MicroTemplate::_PerRequest';
}

1;

=head1 NAME

Catalyst::View::Text::MicroTemplate::PerRequest - JSON View that owns its data 

=head1 SYNOPSIS

    MyApp->inject_components(
      'View::HTML' => { from_component => 'Catalyst::View::Text::MicroTemplate::PerRequest' }
    );

    # In a controller...

    sub root :Chained(/) CaptureArgs(0) {
      my ($self, $c) = @_;
      $c->view('HTML')->data->set(z=>1);
    }

    sub midpoint :Chained(root) CaptureArgs(0) {
      my ($self, $c) = @_;
      $c->view('HTML')->data->set(y=>1);
    }

    sub endpoint :Chained(midpoint) Args(0) {
      my ($self, $c) = @_;
      $c->view('JSON')->created({
        a => 1,
        b => 2,
        c => 3,
      });
    }

    # template $HOME/root/endpoint.mt
    
    This is my template
    Here's some placeholders
    a => <?= $a ?>
    b => <?= $b ?>
    c => <?= $c ?>
    y => <?= $y ?>
    z => <?= $z ?>


=head1 DESCRIPTION

This is a L<Catalyst::View> that uses L<Text::MicroTemplate::Extended> which
is a pure Perl templating engine that uses Perl code instead of a dedicated
template domain specific language.  You may find this a bad idea for large
projects where you have a dedicated front end development team (or just a bad
idea in general).  However I find for smaller projects where the back end programmer
does double duty as a UI developer its useful to avoid having to remember yet
another DSL just to do output formating.  Its reasonable fast and if you control
yourself you won't make too much of a mess.  You should review L<Text::MicroTemplate::Extended>
and L<Text::MicroTemplate> for more on how the template engine works.

It differs from other L<Catalyst> views on CPAN (including L<Catayst::View::Text::MicroTemplate>)
In that it is a 'per request view' that lets you define a view owned data model
for passing information to the view.  You may find this a better solution than
using the stash although you may also use the stash if you like (there's a template
setting for this.)

It also generates some local response helpers.  You may or may not find this
approach leads to cleaner code.  Lastly we allow you to more easily override
how we generate a default template name.  In general I consider this view to be
a somewhat experimental approach to solve some common problems that have really irked
me about the commonly used approach to views in L<Catalyst>  However I do use this in
product so I commit to making this stable and safe (just this is not the official proscribed
way so you might find some learning curve).

A similar style view that produces JSON is L<Catalyst::View::JSON::PerRequest>.
In fact this was written so that I could have a view that did HTML with an identical
interface as that JSON view, to make it easier in situations where I want to choose
a view based on content negotiation (like when doing an API) but would like to keep
the rest of the code the same.

I consider this approach to be an interesting experiment in alternative ways to
use Catalyst views.

=head1 METHODS

This view defines the following methods

=head2 template

Used to override the default template, which is derived from the terminating
action.  You can set this to a particular template name, or an $action.

=head2 data (?$model)

Used to set the view data model, and/or to called methods on it (for example
to set attributes that will later be used in the  response.).

The default is an injected model based on L<Catalyst::Model::Text::MicroTemplate::ViewData>
which you should review for basic usage.  I recommend setting it to a custom
model that better encapsulates your view data.  You may use any model in your
L<Catalyst> application.  We recommend the model provide a method 'TO_HASH' 
to provide a read only view of the data suitable for use in a template, but
that is optional.

You may only set the view data model once.  If you don't set it and just call
methods on it, the default view model is automatically used.

=head2 extra_template_args

This is an optional method you may defined in your view class.  This is used to
add addtional template arguments at request time.  Example:

    sub extra_template_args {
      my ($self, $view, $c) = @_;
      return (
        user => $c->user,
      )
    }

=head2 res

=head2 response

    $view->response($status, @headers, \%data||$object);
    $view->response($status, \%data||$object);
    $view->response(\%data||$object);
    $view->response($status);
    $view->response($status, @headers);

Used to setup a response.  Calling this method will setup an http status, finalize
headers and set a body response.

=head2 Method '->response' Helpers

We map status codes from L<HTTP::Status> into methods to make sending common
request types more simple and more descriptive.  The following are the same:

    $c->view->response(200, @args);
    $c->view->ok(@args);

    do { $c->view->response(200, @args); $c->detach };
    $c->view->detach_ok(@args);

See L<HTTP::Status> for a full list of all the status code helpers.

=head2 render ($data)

Given a Perl data will return a string based on the current template.

    my $html = $c->view->render(@data);

=head2 process

used as a target for $c->forward.  This is mostly here for compatibility with some
existing methodology.  For example allows using this view with the Renderview action
class (common practice).   I'd consider it a depracated approach, personally.

=head1 template_factory

Inherits a default value from L</default_template_factory>.

This is a subroutine reference that is used to generate a template name when you don't
set one via the L</template> setter (this is the common case, to let the view make
the template choice for you).  The common way to do this is to choose a template name
base on the terminal action name, for example here is the default setting for this
attribute:

    return sub {
      my ($view, $ctx) = @_;
      return $ctx->stash->{template} 
        || "${\$ctx->action}";      
    };

The subroutine reference will be called with two arguments, the view instance object
and the current context object.  This should allow you to experiment with new ideas
in choosing a default.  For example I often find it valuable to distinguish templates
not just based on the action path, but also on the response status.  That way I can
set a default based on something like:

    return sub {
      my ($view, $ctx) = @_;
      return $ctx->response->status > 299 ?
        "${\$ctx->action}_${\$ctx->res->status}" :
          "${\$ctx->action}";
    };

That way if an action returns for various status, you can distinguish between OK and
error or exception responses.

BTW, this complication points out that it is possible that the idea of allowing a view
to set a default template via its internal logic is suspect.  The issue here is that
if you are seeking to write actions that can be used across different views (like an HTML
view that needs a template and a JSON view that doesn't) you really prefer to not have
code in your action that dictates a template choice.

=head1 ATTRIBUTES

This View defines the following attributes that can be set during configuration

=head2 merge_stash

Boolean, defaults to false.  If enabled merges anything in $c->stash to
the template arguments.  Useful if you love the stash or have a situation
where you want to start using this view in an existing application that makes
extensive use of stash.

=head2 path_base

Location of your templates.  Defaults to whatever $application->config->{root}
is.

=head2 extension

File extention that your templates use.  Defaults to ".mt".  Please note the '.'
is required.

=head2 content_type

The default content type of your view.  Used when providing a response and the
content type is currently undefined.  Defaults to 'text/plain'.

=head2 template_args

An option hashref of arguments that are always provided to your template.  See
L<https://metacpan.org/pod/Text::MicroTemplate::Extended#template_args1> for more.

Your template always gets an arg '$c' which is the current context. You may also
provide per context template args by providing a method 'extra_template_args'.  The
advantage of that approach is that method will get the context and other objects
as arguments which makes it easier to provide context sensitive values.

=head2 default_template_factory

Default value for L</template_factory>.  Useful if you want a global override for
this.

=head2 macros

See L<https://metacpan.org/pod/Text::MicroTemplate::Extended#Macro>

=head2 mt

This is the L<Text::MicroTemplate::Extended> object.  You probably want to leave this
alone but you can set it as you wish as long as you provide a compatible interface.
You may find this useful for things like mocking objects during testing.

=head2 default_view_model

The L<Catalyst> model that is the default model for holding information to
pass to the view.  The default is L<Catalyst::Model::Text::MicroTemplate::ViewData>
which exposes a stash like interface based on L<Data::Perl::Role::Collection::Hash>
which is good as a basic interface but you may prefer to try a define a more
strict view model interface.

If you create your own view model, it should define a method, 'TO_HASH' to
provide a hash suitable to pass as arguments to the template.   This allows you
to separate the view model from the data passed.  If you don't define such a
method your view model object will be passed to the template as the first
argument in '@_';

=head2 mt_class

The class used to create the L</mt> object.  Defaults to L<Text::MicroTemplate::Extended>
You can set this to whatever you wish but it should be a compatible interface.

=head2 mt_init_args

Arguments used to initialize the L</mt_class> in L</mt>.  Should be a hashref.
See L<Text::MicroTemplate::Extended> for available options

=head2 handle_process_error

A reference to a subroutine that is called when there is a failure to render
the data given.  This can be used globally as an attribute
on the defined configuration for the view, and you can set it or overide the
global settings on a context basis.

Setting this optional attribute will capture and handle error conditions.  We
will NOT bubble the error up to the global L<Catalyst> error handling (we don't
set $c->error for example).  If you want that you need to set it yourself in
a custom handler, or don't define one.

The subroutine receives two arguments: the view object and the exception. You
must setup a new, valid response.  For example:

    package MyApp::View::HTML;

    use Moo;
    extends 'Catalyst::View::Text::MicroTemplate::PerRequest';

    package MyApp;

    use Catalyst;

    MyApp->config(
      default_view =>'HTML',
      'View::HTML' => {
        handle_process_error => sub {
          my ($view, $err) = @_;
          $view->template('500bad_request'); # You need to create this template...
          $view->detach_bad_request({ err => "$err"});
        },
      },
    );

    MyApp->setup;

Or setup/override per context.  Useful when you want to control the error
message carefully based on URL.

    sub error :Local Args(0) {
      my ($self, $c) = @_;

      $c->view->handle_process_error(sub {
          my ($view, $err) = @_;
          $view->template('500bad_request');
          $view->detach_bad_request({ err => "$err"});
        });

      $c->view->ok( $bad_data );
    }

B<NOTE> If you mess up the return value (you return something that can't be
encoded) a second exception will occur which will NOT be handled and will then
bubble up to the main application.

B<NOTE> The view package contains a global function to a usable default
error handler, should you wish to use something consistent and reasonably
valid.  Example:

    MyApp->config(
      default_view =>'HTML',
      'View::HtML' => {
        handle_encode_error => \&Catalyst::View::Text::MicroTemplate::HANDLE_PROCESS_ERROR,
      },
    );

The example handler is defined like this:

  sub HANDLE_PROCESS_ERROR {
    my ($view, $err) = @_;
    $view->template('500'); # you need to create a '500.mt' in your template root directory
    $view->detach_internal_server_error({ error => "$err"});
  }

=head1 UTF-8 NOTES

Generally a view should not do any encoding since the core L<Catalyst>
framework handles all this for you.  L<Text::MicroTemplate> opens your
files with the utf-8 IO layer so you should be able to include wide character
literals in your templates and everything should 'just work' with any recent
L<Catalyst>.  As a result this template offers no method to do character
encoding.  Please raise an issue in the bug tracker if you have special unmet
needs.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<Catalyst::View::Text::MicroTemplate>,
L<CatalystX::InjectComponent>, L<Catalyst::Component::InstancePerContext>,
L<Text::MicroTemplate::Extended>

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2016, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

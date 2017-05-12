package Catalyst::View::JSON::PerRequest;

use Moo;
use CatalystX::InjectComponent;
use Catalyst::View::JSON::_PerRequest;

our $VERSION = 0.009;
our $DEFAULT_JSON_CLASS = 'JSON::MaybeXS';
our $DEFAULT_VIEW_MODEL = 'JSON::ViewData';
our %JSON_INIT_ARGS = (
  utf8 => 1,
  convert_blessed => 1);

extends 'Catalyst::View';
with 'Catalyst::Component::InstancePerContext';

has json => (
  is=>'ro',
  required=>1,
  init_arg=>undef,
  lazy=>1,
  default=>sub {
    my $self = shift;
    eval "use ${\$self->json_class}; 1" ||
      die "Can't use ${\$self->json_class}, $@";

    return $self->json_class->new(
      $self->json_init_args);
  });

sub HANDLE_ENCODE_ERROR {
  my ($view, $err) = @_;
  $view->detach_internal_server_error({ error => "$err"});
}

has handle_encode_error => (
  is=>'ro',
  predicate=>'has_handle_encode_error');

has default_view_model => (
  is=>'ro',
  required=>1,
  default=>sub {
    return $DEFAULT_VIEW_MODEL;
  });

has json_class => (
  is=>'ro',
  require=>1,
  default=>sub {
    return $DEFAULT_JSON_CLASS;
  });

has json_init_args => (
  is=>'ro',
  required=>1,
  lazy=>1,
  default=>sub {
    my $self = shift;
    my %init = (%JSON_INIT_ARGS, $self->has_json_extra_init_args ?
      %{$self->json_extra_init_args} : ());

    return \%init;
  });

has json_extra_init_args => (
  is=>'ro',
  predicate=>'has_json_extra_init_args');

has callback_param => ( is=>'ro', predicate=>'has_callback_param');

sub COMPONENT {
  my ($class, $app, $args) = @_;
  $args = $class->merge_config_hashes($class->config, $args);
  $class->_inject_default_view_model_into($app);
  return $class->new($app, $args);
}

sub _inject_default_view_model_into {
  my ($class, $app) = @_;
  CatalystX::InjectComponent->inject(
    into => $app,
    component => 'Catalyst::Model::JSON::ViewData',
    as => 'Model::JSON::ViewData' );
}

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  return bless +{
    ctx=>$c,
    parent=>$self,
    json=>$self->json,
    ($self->has_handle_encode_error ? (handle_encode_error=>$self->handle_encode_error) :()),
    ($self->has_callback_param ? (callback_param=>$self->callback_param) :())
  }, 'Catalyst::View::JSON::_PerRequest';
}

1;

=head1 NAME

Catalyst::View::JSON::PerRequest - JSON View that owns its data 

=head1 SYNOPSIS

    MyApp->inject_components(
      'View::JSON' => { from_component => 'Catalyst::View::JSON::PerRequest' }
    );

    # In a controller...

    sub root :Chained(/) CaptureArgs(0) {
      my ($self, $c) = @_;
      $c->view('JSON')->data->set(z=>1);
    }

    sub midpoint :Chained(root) CaptureArgs(0) {
      my ($self, $c) = @_;
      $c->view('JSON')->data->set(y=>1);
    }

    sub endpoint :Chained(midpoint) Args(0) {
      my ($self, $c) = @_;
      $c->view('JSON')->created({
        a => 1,
        b => 2,
        c => 3,
      });
    }

=head1 DESCRIPTION

This is a L<Catalyst::View> that produces JSON response from a given model.
It differs from some of the more classic JSON producing views (such as
L<Catalyst::View::JSON> in that is is a per request view (one view for each
request) and it defines a 'data' method to hold information to use to produce
a view.

It also generates some local response helpers.  You may or may not find this
approach leads to cleaner code.

=head1 METHODS

This view defines the following methods

=head2 data (?$model)

Used to set the view data model, and/or to called methods on it (for example
to set attributes that will later be used in the JSON response.).

The default is an injected model based on L<Catalyst::Model::JSON::ViewData>
which you should review for basic usage.  I recommend setting it to a custom
model that better encapsulates your view data.  You may use any model in your
L<Catalyst> application as long as it does the method "TO_JSON".

You may only set the view data model once.  If you don't set it and just call
methods on it, the default view model is automatically used.

B<NOTE> In order to help prevent namespace collision, your custom view model is
allowed to defined a method 'set' which is used to set attribute values on your
model.  Set should take two arguments, a key and a value.

=head2 res

=head2 response

    $view->response($status, @headers, \%data||$object);
    $view->response($status, \%data||$object);
    $view->response(\%data||$object);
    $view->response($status);
    $view->response($status, @headers);

Used to setup a response.  Calling this method will setup an http status, finalize
headers and set a body response for the JSON.  Content type will be set to
'application/json' automatically (you don't need to set this in a header).

=head2 Method '->response' Helpers

We map status codes from L<HTTP::Status> into methods to make sending common
request types more simple and more descriptive.  The following are the same:

    $c->view->response(200, @args);
    $c->view->ok(@args);

    do { $c->view->response(200, @args); $c->detach };
    $c->view->detach_ok(@args);

See L<HTTP::Status> for a full list of all the status code helpers.

=head2 render ($data)

Given a Perl data will return the JSON encoded version.

    my $json = $c->view->render(\%data);

Should be a reference or object that does 'TO_JSON'

=head2 process

used as a target for $c->forward.  This is mostly here for compatibility with some
existing methodology.  For example allows using this view with the Renderview action
class (common practice).   I'd consider it a depracated approach, personally.

=head1 ATTRIBUTES

This View defines the following attributes that can be set during configuration

=head2 callback_param

Optional.  If set, we use this to get a method name for JSONP from the query parameters.

For example if 'callback_param' is 'callback' and the request is:

    localhost/foo/bar?callback=mymethod

Then the JSON response will be wrapped in a function call similar to:

    mymethod({
      'foo': 'bar',
      'baz': 'bin});

Which is a common technique for overcoming some cross-domain restrictions of
XMLHttpRequest.

There are some restrictions to the value of the callback method, for security.
For more see: L<http://ajaxian.com/archives/jsonp-json-with-padding>

=head2 default_view_model

The L<Catalyst> model that is the default model for your JSON return.  The
default is set to a local instance of L<Catalyst::Model::JSON::ViewData>

=head2 json_class

The class used to perform JSON encoding.  Default is L<JSON::MaybeXS>

=head2 json_init_args

Arguments used to initialize the L</json_class>.  Defaults to:

    our %JSON_INIT_ARGS = (
      utf8 => 1,
      convert_blessed => 1);

=head2 json_extra_init_args

Allows you to 'tack on' some arguments to the JSON initialization without
messing with the defaults.  Unless you really need to override the defaults
this is the method you should use.

=head2 handle_encode_error

A reference to a subroutine that is called when there is a failure to encode
the data given into a JSON format.  This can be used globally as an attribute
on the defined configuration for the view, and you can set it or overide the
global settings on a context basis.

Setting this optional attribute will capture and handle error conditions.  We
will NOT bubble the error up to the global L<Catalyst> error handling (we don't
set $c->error for example).  If you want that you need to set it yourself in
a custom handler, or don't define one.

The subroutine receives two arguments: the view object and the exception. You
must setup a new, valid response.  For example:

    package MyApp::View::JSON;

    use Moo;
    extends 'Catalyst::View::JSON::PerRequest';

    package MyApp;

    use Catalyst;

    MyApp->config(
      default_view =>'JSON',
      'View::JSON' => {
        handle_encode_error => sub {
          my ($view, $err) = @_;
          $view->detach_bad_request({ err => "$err"});
        },
      },
    );

    MyApp->setup;

Or setup/override per context:

    sub error :Local Args(0) {
      my ($self, $c) = @_;

      $c->view->handle_encode_error(sub {
          my ($view, $err) = @_;
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
      default_view =>'JSON',
      'View::JSON' => {
        handle_encode_error => \&Catalyst::View::JSON::PerRequest::HANDLE_ENCODE_ERROR,
      },
    );

The example handler is defined like this:

  sub HANDLE_ENCODE_ERROR {
    my ($view, $err) = @_;
    $view->detach_internal_server_error({ error => "$err"});
  }

=head1 UTF-8 NOTES

Generally a view should not do any encoding since the core L<Catalyst>
framework handles all this for you.  However, historically the popular
Catalyst JSON views and related ecosystem (such as L<Catalyst::Action::REST>)
have done UTF8 encoding and as a result for compatibility core Catalyst code
will assume a response content type of 'application/json' is already UTF8 
encoded.  So even though this is a new module, we will continue to maintain this
historical situation for compatibility reasons.  As a result the UTF8 encoding
flags will be enabled and expect the contents of $c->res->body to be encoded
as expected.  If you set your own JSON class for encoding, or set your own
initialization arguments, please keep in mind this expectation.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<Catalyst::View::JSON>,
L<CatalystX::InjectComponent>, L<Catalyst::Component::InstancePerContext>,
L<JSON::MaybeXS>

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

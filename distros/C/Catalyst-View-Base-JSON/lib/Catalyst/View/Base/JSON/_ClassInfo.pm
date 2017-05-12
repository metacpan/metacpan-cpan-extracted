package Catalyst::View::Base::JSON::_ClassInfo;

use Moo;
use Scalar::Util;
use Catalyst::Utils;

our $DEFAULT_JSON_CLASS = 'JSON::MaybeXS';
our $DEFAULT_CONTENT_TYPE = 'application/json';
our %JSON_INIT_ARGS = (
  utf8 => 1,
  convert_blessed => 1);

has [qw/_original_args _instance_class _fields/] => (is=>'ro', required=>1);

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

has content_type => (
  is=>'ro',
  required=>1,
  default=>$DEFAULT_CONTENT_TYPE);

has returns_status => (
  is=>'ro',
  predicate=>'has_returns_status');

sub HANDLE_ENCODE_ERROR {
  my ($self, $view, $unencodable_ref, $err) = @_;
  if($self->has_handle_encode_error) {
    $self->has_handle_encode_error->($view, $unencodable_ref, $err);
  } else {
    return $view->ctx->debug ?
      $view->response(400, { error => "$err", original=>$unencodable_ref})->detach :
        $view->response(400, { error => "$err"})->detach;
  }
}

has handle_encode_error => (
  is=>'ro',
  predicate=>'has_handle_encode_error');

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

my $get_stash_key = sub {
  my $self = shift;
  my $key = Scalar::Util::blessed($self) ?
    Scalar::Util::refaddr($self) :
      $self;
  return "__Pure_${key}";
};

my $prepare_args = sub {
  my ($self, @args) = @_;
  my %args = ();
  if(scalar(@args) % 2) { # odd args means first one is an object.
    my $proto = shift @args;
    foreach my $field (@{$self->_fields||[]}) {
      if(my $cb = $proto->can($field)) { # match object methods to available fields
        $args{$field} = $proto->$field;
      }
    }
  }
  %args = (%args, @args);
  return Catalyst::Utils::merge_hashes($self->_original_args, \%args);
};

sub ACCEPT_CONTEXT {
  my ($self, $c, @args) = @_;
  die "View ${\$self->_instance_class->catalyst_component_name} can only be called with a context"
    unless Scalar::Util::blessed($c);

  my $stash_key = $self->$get_stash_key;
  $c->stash->{$stash_key} ||= do {
    my $args = $self->$prepare_args(@args);
    my $new = $self->_instance_class->new(
      %{$args},
      %{$c->stash},
    );
    $new->{__class_info} = $self;
    $new->{__ctx} = $c;
    $new;
  };
  return $c->stash->{$stash_key};    
}

1;

=head1 NAME

Catalyst::View::Base::JSON::_ClassInfo - Application Level Info for your View 

=head1 SYNOPSIS

    NA - Internal use only.

=head1 DESCRIPTION

This is used by the main class L<Catalyst::View::JSON::PerRequest> to hold
application level information, mostly configuration and a few computations you
would rather do once.

No real public reusably bits here, just for your inspection.

=head1 ATTRIBUTES

This View defines the following attributes that can be set during configuration

=head2 content_type

Sets the response content type.  Defaults to 'application/json'.

=head2 returns_status

An optional arrayref of L<HTTP::Status> codes that the view is allowed to generate.
Setting this will injection helper methods into your view:

    $view->http_ok;
    $view->202;

Both 'friendly' names and numeric codes are generated (I recommend you stick with one
style or the other in a project to avoid confusion.  Helper methods return the view
object to make common chained calls easier:

    $view->http_bad_request->detach;

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

The subroutine receives three arguments: the view object, the original reference
that failed to encode and the exception. You must setup a new, valid response.
For example:

    package MyApp::View::JSON;

    use Moo;
    extends 'Catalyst::View::Base::JSON';

    package MyApp;

    use Catalyst;

    MyApp->config(
      default_view =>'JSON',
      'View::JSON' => {
        handle_encode_error => sub {
          my ($view, $original_bad_ref, $err) = @_;
          $view->response(400, { error => "$err"})->detach;
        },
      },
    );

    MyApp->setup;


B<NOTE> If you mess up the return value (you return something that can't be
encoded) a second exception will occur which will NOT be handled and will then
bubble up to the main application.

B<NOTE> We define a rational default for this to get you started:

    sub HANDLE_ENCODE_ERROR {
      my ($view, $orginal_bad_ref, $err) = @_;
      $view->response(400, { error => "$err"})->detach;
    }

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<Catalyst::View::JSON>,
L<JSON::MaybeXS>

=head1 AUTHOR
 
See L<Catalyst::View::Base::JSON>

=head1 COPYRIGHT & LICENSE
 
See L<Catalyst::View::Base::JSON>

=cut

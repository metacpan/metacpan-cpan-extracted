use strict;
use warnings;

package Catalyst::View::Base::JSON;

use base 'Catalyst::View';
use HTTP::Status;
use Scalar::Util;

our $VERSION = 0.003;
our $CLASS_INFO = 'Catalyst::View::Base::JSON::_ClassInfo';

my $inject_http_status_helpers = sub {
  my ($class, $args) = @_;
  return unless $args->{returns_status};
  foreach my $helper( grep { $_=~/^http/i} @HTTP::Status::EXPORT_OK) {
    my $subname = lc $helper;
    my $code = HTTP::Status->$helper;
    my $codename = "http_".$code;
    if(grep { $code == $_ } @{ $args->{returns_status}||[]}) {
       eval "sub ${\$class}::${\$subname} { return shift->response(HTTP::Status::$helper,\@_) }";
       eval "sub ${\$class}::${\$codename} { return shift->response(HTTP::Status::$helper,\@_) }";
    }
  }
};

my $find_fields = sub {
  my $class = shift;
  my @fields = ();
  for ($class->meta->get_all_attributes) {
    next unless $_->has_init_arg;
    push @fields, $_->init_arg;
  }
  return @fields;
};

sub _build_class_info {
  my ($class, $args) = @_;
  Catalyst::Utils::ensure_class_loaded($CLASS_INFO);
  return $CLASS_INFO->new($args);
}

sub COMPONENT {
  my ($class, $app, $args) = @_;
  $args = $class->merge_config_hashes($class->config, $args);
  $args->{_instance_class} = $class;
  $args->{_original_args} = $args;
  $args->{_fields} = [$class->$find_fields];
  $class->$inject_http_status_helpers($args);

  return $class->_build_class_info($args);
}

sub ctx { return $_[0]->{__ctx} }
sub process { return shift->response(200, @_) }
sub detach { shift->ctx->detach(@_) }

my $class_info = sub { return $_[0]->{__class_info} };

sub response {
  my ($self, @proto) = @_;
  
  my $status = 200; 
  if( (ref \$proto[0] eq 'SCALAR') and
    Scalar::Util::looks_like_number($proto[0])
  ){
    $status = shift @proto;
  }

  my $possible_override_data = '';
  if(
    @proto &&
    (
      ((ref($proto[-1])||'') eq 'HASH') ||
      Scalar::Util::blessed($proto[-1])
    )
  ) {
    $possible_override_data = pop(@proto);
  }
 
  my @headers = ();
  if(@proto) {
    @headers = @proto;
  }

  for($self->ctx->response) {
    $_->headers->push_header(@headers) if @headers;
    $_->status($status) unless $_->status != 200; # Catalyst default is 200...
    $_->content_type($self->$class_info->content_type)
      unless $_->content_type;

    $self->amend_headers($_->headers)
      if $self->can('amend_headers');

    unless($_->has_body) {
      my $json = $self->render($possible_override_data);
      if(my $param = $self->$class_info->callback_param) {
        my $cb = $_->query_parameter($self->$class_info->callback_param);
        $cb =~ /^[a-zA-Z0-9\.\_\[\]]+$/ || die "Invalid callback parameter $cb";
        $json = "$cb($json)";
      }
      $_->body($json);
    }
  }
}

sub render {
  my ($self, $possible_override_data) = @_;
  my $to_json_encode = $possible_override_data ? $possible_override_data : $self;
  my $json = eval {
    $self->$class_info->json->encode($to_json_encode);
  } || do {
    $self->$class_info->HANDLE_ENCODE_ERROR($self, $to_json_encode, $@);
    return;
  };
  return $json;
}

sub uri {
  my ($self, $action_proto, @args) = @_;

  # Is an action object
  return $self->ctx->uri_for($action_proto, @args)
  if Scalar::Util::blessed($action_proto);

  # Is an absolute or relative (to the current controller) action private name.
  my $action = $action_proto=~m/^\// ?
    $self->ctx->dispatcher->get_action_by_path($action_proto) :
      $self->ctx->controller->action_for($action_proto);
      
  return $self->ctx->uri_for($action, @args);
}

sub TO_JSON { die "View ${\$_[0]->catalyst_component_name} must define a 'TO_JSON' method!" }

1;

=head1 NAME

Catalyst::View::Base::JSON - a 'base' JSON View 

=for html
<a href="https://badge.fury.io/pl/Catalyst-View-Base-JSON"><img src="https://badge.fury.io/pl/Catalyst-View-Base-JSON.svg" alt="CPAN version" height="18"></a>
<a href="https://travis-ci.org/jjn1056/Catalyst-View-Base-JSON/"><img src="https://api.travis-ci.org/jjn1056/Catalyst-View-Base-JSON.png" alt="https://api.travis-ci.org/jjn1056/Catalyst-View-Base-JSON.png"></a>
<a href="http://cpants.cpanauthors.org/dist/Catalyst-View-Base-JSON"><img src="http://cpants.cpanauthors.org/dist/Catalyst-View-Base-JSON.png" alt='Kwalitee Score' /></a>

=head1 SYNOPSIS

    package MyApp::View::Person;

    use Moo;
    use Types::Standard;
    use MyApp::Types qw/Version/;

    extends 'Catalyst::View::Base::JSON';

    has name => (
     is=>'ro',
     isa=>Str,
     required=>1);

    has age => (
     is=>'ro',
     isa=>Int,
     required=>1);

    has api_version => (
     is=>'ro',
     isa=>Version,
     required=>1);

    sub amend_headers {
      my ($self, $headers) = @_;
      $headers->push_header(Accept => 'application/json');
    }

    sub TO_JSON {
      my $self = shift;
      return +{
        name => $self->name,
        age => $self->age,
        api => $self->api_version,
      };
    }

    package MyApp::Controller::Root;
    use base 'Catalyst::Controller';

    sub example :Local Args(0) {
      my ($self, $c) = @_;
      $c->stash(age=>32);
      $c->view('Person', name=>'John')->http_ok;
    }

    package MyApp;
    
    use Catalyst;

    MyApp->config(
      'Controller::Root' => { namespace => '' },
      'View::Person' => {
        returns_status => [200, 404],
        api_version => '1.1',
      },
    );

    MyApp->setup;


=head1 DESCRIPTION

This is a Catalyst view that lets you create one view per reponse type of JSON
you are generating.  Because you are creating one view per reponse type that means
you can define an interface for that view which is strongly typed.  Also, since
the view is per request, it has access to the context, as well as some helpers
for creating URLs.  You may find that this helps make your controllers more
simple and promote reuse of view code.

I consider this work partly a thought experiment.  Documentation and test coverage
are currently light and I might change parts of the way exceptions are handled.  If
you are producing JSON with L<Catalyst> and new to the framework you might want to
consider 'tried and true' approaches such as L<Catalyst::View:::JSON> or
L<Catalyst::Action::REST>.  My intention here is to get people to start thinking
about views with stronger interfaces.

=head1 METHODS

This view defines the following methods

=head2 response

    $view->response($status);
    $view->response($status, @headers);
    $view->response(@headers);


Used to setup a response.  Calling this method will setup an http status, finalize
headers and set a body response for the JSON.  Content type will be set based on
your 'content_type' configuration value (or 'application/json' by default).

=head2 Method '->response' Helpers

We map status codes from L<HTTP::Status> into methods to make sending common
request types more simple and more descriptive.  The following are the same:

    $c->view->response(200, @args);
    $c->view->http_ok(@args);

    do { $c->view->response(200, @args); $c->detach };
    $c->view->http_ok(@args)->detach;

See L<HTTP::Status> for a full list of all the status code helpers.

=head2 ctx

Returns the current context associated with the request creating this view.

=head2 uri ($action|$action_name|$relative_action_name)

Helper used to create links.  Example:

    sub TO_JSON {
      my $self = shift;
      return +{
        name => $self->name,
        age => $self->age,
        friends => $self->uri('friends', $self->id),
      };
    }

The arguments are basically the same as $c->uri_for except that the first argument
may be a full or relative action path.

=head2 render

Returns a string which is the JSON represenation of the current View.  Usually you
won't need to call this directly.

=head2 process

used as a target for $c->forward.  This is mostly here for compatibility with some
existing methodology.  For example allows using this View with the RenderView action
class (or L<Catalyst::Action::RenderView>).

=head1 ATTRIBUTES

See L<Catalyst::View::Base::JSON::_ClassInfo> for application level configuration.
You may also defined custom attributes in your base class and assign values via
configuration.

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
L<JSON::MaybeXS>

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2016, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

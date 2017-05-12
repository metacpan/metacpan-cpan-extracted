package Catalyst::Plugin::ResponseFrom;

use URI ();
use Moose::Role;
use HTTP::Message::PSGI ();
use MIME::Base64 ();
use HTTP::Request ();
use Scalar::Util ();

our $VERSION = '0.003';

requires 'psgi_app', 'res', 'detach';

## Block of code gratuitously stolen from Web::Simple::Application
my $_request_spec_to_http_request = sub {
  my ($self, $method, $path, @rest) = @_;

  # if the first arg is a catalyst action, build a URL
  if(Scalar::Util::blessed $method and $method->isa('Catalyst::Action')) {
    $path = $self->uri_for($method, @_[2..$#_]);
    $method = 'GET';
    @rest = ();
  }

  # if it's a reference, assume a request object
  return $method if(Scalar::Util::blessed $method and $method->isa('HTTP::Request'));
 
  if ($path =~ s/^(.*?)\@//) {
    my $basic = $1;
    unshift @rest, 'Authorization:', 'Basic '.MIME::Base64::encode($basic);
  }
 
  my $request = HTTP::Request->new($method => $path);
 
  my @params;
 
  while (my ($header, $value) = splice(@rest, 0, 2)) {
    unless ($header =~ s/:$//) {
      push @params, $header, $value;
    }
    $header =~ s/_/-/g;
    if ($header eq 'Content') {
      $request->content($value);
    } else {
      $request->headers->push_header($header, $value);
    }
  }
 
  if (($method eq 'POST' or $method eq 'PUT') and @params) {
    my $content = do {
      my $url = URI->new('http:');
      $url->query_form(@params);
      $url->query;
    };
    $request->header('Content-Type' => 'application/x-www-form-urlencoded');
    $request->header('Content-Length' => length($content));
    $request->content($content);
  }
 
  return $request;
};

sub psgi_response_from {
  my $self = shift;
  my $http_request = $self->$_request_spec_to_http_request(@_);
  my $psgi_env = HTTP::Message::PSGI::req_to_psgi($http_request);
  return my $psgi_response = $self->psgi_app->($psgi_env);
}

*response_from = \&http_response_from;
sub http_response_from {
  my $self = shift;
  my $psgi_response = $self->psgi_response_from(@_);
  return my $http_response = HTTP::Message::PSGI::res_from_psgi($psgi_response);
}

sub redispatch_to {
  my $self = shift;
  my $psgi_response = $self->psgi_response_from(@_);
  $self->res->from_psgi_response($psgi_response);
  $self->detach;
}

1;

=head1 NAME

Catalyst::Plugin::ResponseFrom - Use the response of a public endpoint.

=head1 SYNOPSIS

    package MyApp;
    use Catalyst 'ResponseFrom';

    MyApp->setup;

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;
    use HTTP::Request::Common;

    extends 'Catalyst::Controller';

    sub as_http_request :Local {
      my ($self, $c) = @_;
      $c->redispatch_to(GET $c->uri_for($self->action_for('target')));
      # For simple GETs you can just use $c->uri_for style params like:
      $c->redispatch_to($self->action_for('target'));
    }

    sub as_spec :Local {
      my ($self, $c) = @_;
      $c->redispatch_to('GET' => $c->uri_for($self->action_for('target')));
    }

    sub collect_response :Local {
      my ($self, $c) = @_;
      my $http_response = $c->http_response_from(GET => $c->uri_for($self->action_for('target')));
    }

    sub target :Local {
      my ($self, $c) = @_;
      $c->response->content_type('text/plain');
      $c->response->body("This is the target action");
    }

=head1 DESCRIPTION

L<Catalyst> allows you to forward to a private named actions, but there is no
built in method to 'forward' to a public URL.  You might want to do this rather
than (for example) issue a redirect.

Additionally there is no 'subrequest' like feature (and L<Catalyst::Plugin::Subrequest>
uses internal hacks to function).  There maye be cases, such as in testing, where
it would be great to be able to issue a public URL request and collect the response.

This plugin is an attempt to give you these features in a clean manner that does not
rely on internal L<Catalyst> details that are subject to change.  However you must be
using a more modern version of L<Catalyst> (the current requirement is 5.90060).

=head1 METHODS

This plugin adds the following methods to your L<Catalyst> application.  All methods
share the same function signature (this approach and following documentation 'borrowed'
from L<Web::Simple>):

    my $psgi_response = $app->http_response_from(GET => '/' => %headers);
    my $http_response = $app->http_response_from(POST => '/' => %headers_or_form);
    $c->redispatch_to($http_request);

Accept three style of arguments:

=over4

=item  An L<HTTP::Request> object

Runs this against the application as if running from a client such as a browser

=item Parameters ($method, $path) 

A single domain specific language used to construct an L<HTTP::Request> object.

If the HTTP method is POST or PUT, then a series of pairs can be passed after
this to create a form style message body. If you need to test an upload, then
create an L<HTTP::Request> object by hand or use the C<POST> subroutine
provided by L<HTTP::Request::Common>.
 
If you prefix the URL with 'user:pass@' this will be converted into
an Authorization header for HTTP basic auth:
 
    my $res = $app->http_response_from(
                GET => 'bob:secret@/protected/resource'
              );
   
If pairs are passed where the key ends in :, it is instead treated as a
headers, so:
 
    my $res = $app->http_response_from(
                POST => '/',
               'Accept:' => 'text/html',
                some_form_key => 'value'
              );
 
will do what you expect. You can also pass a special key of Content: to
set the request body:
 
    my $res = $app->http_response_from(
                POST => '/',
                'Content-Type:' => 'text/json',
                'Content:' => '{ "json": "here" }',
              );

=item a L<Catalyst::Action> instance + optional parameters

If the arguments are identical to $c->uri_for, we create a request for that
action and assume the method is 'GET'.

=back
 
=head2 psgi_response_from

Given a request constructed as described above, return the L<PSGI> response.
This can be an Arrayref or Coderef.

This is probably not that useful since you likely need to do additional work
to get data out of it, but was the result of refactoring, and I can imagine
a use case or two.

=head2 http_response_from

=head2 response_from

Returns the L<HTTP::Response> object returned by the request. 

=head2 redispatch_to

Uses the response giveing to the request and uses that to complete your
response.  This also detaches so that calling this method effectively
ends processing.  Basically use this when you decide you want the response
to be that of a totally different URL on your application.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>

=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut

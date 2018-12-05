package Amazon::API;

# Generic interface to Amazon APIs

=pod

=head1 NAME

C<Amazon::API>

=head1 SYNOPSIS

 package Amazon::CloudWatchEvents;

 use parent qw/Amazon::API/;

 @API_METHODS = qw/
		  DeleteRule
		  DescribeEventBus
		  DescribeRule
		  DisableRule
		  EnableRule
		  ListRuleNamesByTarget
		  ListRules
		  ListTargetsByRule
		  PutEvents
		  PutPermission
		  PutRule
		  PutTargets
		  RemovePermission
		  RemoveTargets
		  TestEventPattern/;

 sub new {
   my $class = shift;
   my $options = shift || {};
 
   $class->SUPER::new({
 		      %$options,
 		      service_url_base => 'events',
 		      version          => undef,
 		      api              => 'AWSEvents',
 		      api_methods      => \@API_METHODS,
 		      content_type     => 'application/x-amz-json-1.1'
 		     });
 }

 1;

=head1 DESCRIPTION

Class to use for constructing AWS API interfaces.  Typically used as
the parent class, but can be used directly.  See
C<Amazon::CloudWatchEvents> for an example or sub-classing.  See
L</IMPLEMENTATION NOTES> for using C<Amazon::API> directly to call AWS services.

=head1 ERRORS

Errors encountered are returned as an C<Amazon::API::Error> exception object.  See L<Amazon::API::Error>/

=cut

use strict;
use warnings;

use parent qw/Class::Accessor Exporter/;

use Amazon::API::Error;
use Amazon::Credentials;

use AWS::Signature4;
use Data::Dumper;
use HTTP::Request;
use JSON qw/to_json from_json/;
use LWP::UserAgent;
use Scalar::Util qw/reftype/;
use XML::Simple;

__PACKAGE__->follow_best_practice;

__PACKAGE__->mk_accessors(qw/action api api_methods version content_type
			     http_method credentials response protocol
			     region url service_url_base 
			     signer target user_agent debug last_action
			     aws_access_key_id aws_secret_access_key token
			    /);

use vars qw/@EXPORT $VERSION/;

@EXPORT=qw/$VERSION/;

$VERSION = '1.1.3-5'; $VERSION=~s/\-.*$//;

=pod

=head1 METHODS

=head2 new

 new( options )

=over 5

=item credentials

C<Amazon::Credentials> object or at least an object that
C<->can(get_aws_access_key_id)> and
C<->can(get_aws_secret_access_key)> and C<->can(get_token)>

=item user_agent

Your own user agent object or by default C<LWP::UserAgent>.  Using
C<Furl>, if you have it avaiable may result in faster response.

=item api

The name of the AWS service.  Example: AWSEvents

=item url

The service url.  Example: https://events.us-east-1.amazonaws.com

=item debug

0/1 - will dump request/response if set to true.

=item action

The API method. Example: PutEvents

=item content_type

Default content for references passed to the C<invoke_api()> method.  The default is C<application/x-amz-json-1.1>.

=item protocol

One of 'http' or 'https'.  Some Amazon services do not support https (yet).

=back

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  unless ($self->get_user_agent) {
    $self->set_user_agent(new LWP::UserAgent);
  }

  # some APIs are GET only (I'm talkin' to you IAM!)
  $self->set_http_method('POST')
    unless defined $self->get_http_method;
  
  # note some APIs are global, hence an API may send '' to indicate global
  $self->set_region('us-east-1')
    unless defined $self->get_region;
  
  unless ( $self->get_credentials ) {
    $self->set_credentials( new Amazon::Credentials( { aws_secret_access_key => $self->get_aws_secret_access_key,
						       aws_access_key_id     => $self->get_aws_access_key_id,
						       token                 => $self->get_token
						     })
			  );
  }

  $self->set_protocol('https') unless $self->get_protocol();
  
  unless ( $self->get_url ) {
    if ( $self->get_service_url_base() ) {
      if ( $self->get_region ) {
	$self->set_url(sprintf("%s://%s.%s.amazonaws.com", $self->get_protocol, $self->get_service_url_base, $self->get_region));
      }
      else {
	$self->set_url(sprintf("%s://%s.amazonaws.com", $self->get_protocol, $self->get_service_url_base));
      }
    }
    else {
      die "ERROR: no url or service_url defined.\n"
    }
  }
  
  $self->set_signer(AWS::Signature4->new(-access_key => $self->get_credentials->get_aws_access_key_id,
					 -secret_key => $self->get_credentials->get_aws_secret_access_key)
		   );
 
  
  if ( $self->get_api_methods ) {
    no strict 'refs';
    no warnings 'redefine';
    
    foreach my $api (@{$self->get_api_methods}) {
      my $method = lcfirst $api;
      
      $method =~s/([a-z])([A-Z])/$1_$2/g;
      $method = lc $method;
      
      # snake case rules the day
      *{"Amazon::API::" . $method} = sub { shift->invoke_api("$api", @_) };
      # but some prefer camels
      *{"Amazon::API::" . $api} = sub { shift->$method(@_) }; # pass on to the snake
    }
  }
  
  $self->set_content_type('application/x-amz-json-1.1') unless
    $self->get_content_type;
  
  $self;
}

sub get_api_name {
  my $self = shift;
  
  return join("", map { ucfirst } split /_/, shift);
}

=pod

=head2 invoke_api

 invoke_api(action, [parameters, [content-type]]);

=over 5

=item action

=item parameters

Parameters to send to the API. Can be a scalar, a hash reference or an
array reference.

=item content-type

If you send the C<content-type>, it is assumed that the parameters are
the payload to be sent in the request.  Otherwise, the C<parameters>
will be converted to a JSON string if the C<parameters> value is a
hash reference or a query string if the C<parameters> value is an
array reference.

Hence, to send a query string, you should send an array key/value
pairs, or an array of scalars of the form Name=Value.

 [ { Action => 'DescribeInstances' } ]
 [ "Action=DescribeInstances" ]

...are both equivalent ways to force the method to send a query string.

=back

=cut

sub invoke_api {
  my $self = shift;
  my ($action, $parameters, $content_type) = @_;
  
  $self->set_action($action);
  $self->set_last_action($action);

  my $content;
  
  unless ( $content_type ) {
    if ( ref($parameters) && reftype($parameters) eq 'HASH' ) {
      $content_type =  $self->get_content_type;
      $content = to_json($parameters || {});
    }
    elsif ( ref($parameters) && reftype($parameters) eq 'ARRAY') {
      $content_type = 'application/x-www-form-url-encoded'
	unless $self->get_http_method eq 'GET';
      
      my @query_string;
      foreach (@{$parameters}) {
	push @query_string, ref($_) ? sprintf("%s=%s", %$_) : $_;
      }
      $content = join('&', @query_string);
    }
    else {
      $content_type = 'application/x-www-form-url-encoded'
	unless $self->get_http_method eq 'GET';
      $content = $parameters;
    }
  }
  else {
    $content = $parameters;
  }
   
  my $rsp = $self->submit(content => $content, content_type => $content_type);
  
  if ( $self->get_debug ) {
    print STDERR Dumper [$rsp];
  }
    
  # probably want to decode content when there is an error, but this
  # will do for now
  unless ($rsp->is_success) {
    die new Amazon::API::Error({error        => $rsp->code,
				message_raw  => $rsp->content,
				content_type => $rsp->content_type,
				api          => $self
			       });
    
  }
  
  $self->set_response($rsp);
  
  return $rsp->content;
}


=pod

=head2 decode_response

Attempts to decode the response from the API based on the Content-Type
returned in the response header.  If there is no Content-Type, then
the raw content is returned.


=cut

sub decode_response {
  my $self = shift;
  my $rsp = $self->get_response;
  
  return undef unless $rsp;

  my $result = eval {
    if ( $rsp->content_type =~/xml/i) {
      XMLin($rsp->content);
    }
    elsif ( $rsp->content_type =~/json/i ) {
      from_json($rsp->content);
    }
    else {
      $rsp->content;
    }
  };

  if ( $@ ) {
    $result = $rsp->content;
  }

  $result;
}


=pod

=head2 submit

 submit( options )

C<options> is hash of options:

=over 5

=item content

Payload to send.

=item content_type

Content types we have seen used to send values to AWS APIs:

 application/json
 application/x-amz-json-1.0
 application/x-amz-json-1.1
 application/x-www-form-urlencoded

=back

=cut

sub submit {
  my $self = shift;
  my %options = @_;

  my $request = HTTP::Request->new($self->get_http_method || 'POST', $self->get_url);

  # 1. set the header
  # 2. set the content
  # 3. sign the request
  # 4. send the request & return result
  
  # see IMPLEMENTATION NOTES for an explanation
  if ( $self->get_api ) {
    if ( $self->get_version) {
      $self->set_target(sprintf("%s_%s.%s", $self->get_api, $self->get_version, $self->get_action));
    }
    else {
      $self->set_target(sprintf("%s.%s", $self->get_api, $self->get_action));
    }

    $request->header('X-Amz-Target', $self->get_target());
  }
  
  unless ($self->get_http_method eq 'GET') {
    $options{content_type} = $options{content_type} || 'application/x-amz-json-1.1';
    $request->content_type($options{content_type});
    
    if ( $options{content_type} eq 'application/x-www-form-url-encoded') {
      $options{content} = $self->_finalize_content($options{content});
    }
    $request->content($options{content});
  }
  else {
    $request->uri(sprintf("%s?%s", $request->uri(), $self->_finalize_content($options{content})));
  }
  
  $request->header('X-Amz-Security-Token', $self->get_credentials->get_token)
    if $self->get_credentials->get_token;
		 
  # sign the request
  $self->get_signer->sign($request);

  # make the request, return response object
  if ( $self->get_debug ) {
    print STDERR Dumper([$request]);
  }
  
  $self->get_user_agent->request($request);
}

sub _finalize_content {
  my $self = shift;
  my $content = shift;
  
  my @args = $content if $content;
  
  if ( $content && $content !~/Action=/ || ! $content ) {
    push @args, "Action=" . $self->get_action;
  }
  
  if ( $self->get_version) {
    push @args, "Version=" . $self->get_version
  }
  
  return @args ? join('&', @args) : '';
}

=pod

=head1 IMPLEMENTATION NOTES

=head2 X-Amz-Target

Most of the newer AWS APIs accept a header (X-Amz-Target) in lieu of
the CGI parameter Action. Some APIs also want the version in the
target, some don't. Sparse documentation about some of the nuances of
using the REST interface directly to call AWS APIs.

We use the C<api> value as a trigger to indicate we need to set the
Action in the X-Amz-Target header.  We also check to see if the
version needs to be attached to the Action value as required by some
APIs.

  if ( $self->get_api ) {
    if ( $self->get_version) {
      $self->set_target(sprintf("%s_%s.%s", $self->get_api, $self->get_version, $self->get_action));
    }
    else {
      $self->set_target(sprintf("%s.%s", $self->get_api, $self->get_action));
    }

    $request->header('X-Amz-Target', $self->get_target());
  }


DynamoDB & KMS seems to be able to use this in lieu of query variables
Action & Version, although again, there seems to be a lot of
inconsisitency in the APIs.  DynamoDB uses DynamoDB_YYYYMMDD.Action
while KMS will not take the version that way and prefers
TrentService.Action (with no version).  There is no explanation in any
of the documentations I have been able to find as to what
"TrentService" might actually mean.

In general, the AWS API ecosystem is very organic. Each service seems
to have its own rules and protocol regarding what the content of the
headers should be. This generic API interface tries to make it
possible to use a central class (Amazon::API) as a sort of gateway to
the APIs. The most generic interface is simply sending query variables
and not much else in the header.  APIs like EC2 conform to the that
school, so as indicated above we use C<action> to determine whether to
send the API action in the header or to assume that it is being sent
as one of the query variables.

=head2 Rolling a new API 

The class will stub out methods for the API if you pass an array of
API method names.  The stub is equivalent to:


 sub some_api {
   my $self = shift;

   $self ->invoke_api('SomeApi', @_);
 }

Some will also be happy to know that the class will create an
equivalent CamelCase version of the method.  If you choose to override
the method, you should override the snake case version of the method.

As an example, here is a possible implementation of
C<Amazon::CloudWatchEvents> that implements one of the API calls.

 package Amazon::CloudWatchEvents;

 use parent qw/Amazon::API/;
 
 sub new {
   my $class = shift;
   my $options = shift || {};

   $options->{api} 'AWSEvents';
   $options->{url} 'https://events.us-east-1.amazonaws.com';
   $options->{api_methods} => [ 'ListRules' ];

   return $class->SUPER::new($options);
 }

 1;

Then...

  my $cwe = new Amazon::CloudWatchEvents();
  $cwe->ListRules({});

Of course, creating a class for the service is optional. It may be
desirable however to create higher level and more convenient methods
that aid the developer in utilizing a particular API.

 my $api = new Amazon::API({ credentials => new Amazon::Credentials, api => 'AWSEvents', url => 'https://events.us-east-1.amazonaws.com' });
 $api->invoke_api('ListRules', {});

=head2 Content-Type

Yet another piece of evidence that suggests the I<organic> nature of
the Amazon API ecosystem is their use of multiple forms of input to
their methods indicated by the required Content-Type for different
services.  Some of the variations include:

 application/json
 application/x-amz-json-1.0
 application/x-amz-json-1.1
 application/x-www-form-urlencoded

Accordingly, the C<invoke_api()> can be passed the Content-Type or
will try to make "best guess" based on the input parameter you passed.
It guesses using the following decision tree:

=over 5

=item * If the Content-Type parameter is passed as the third argument, that is used.  Full stop.

=item * If the C<parameters> value to C<invoke_api()> is a reference, then the Content-Type is either the value of C<get_content_type> or C<application/x-amzn-json-1.1>.

=item * If the C<parameters> value to C<invoke_api()> is a scalar, then the Content-Type is C<application/x-www-form-urlencoded>.

=back

You can set the default Content-Type used for the calling service when
a reference is passed to the C<invoke_api()> method by passing the
C<content_type> option to the constructor.

 $class->SUPER::new({%@_, content_type => 'application/x-amz-json-1.1', api => 'AWSEvents', 
                     url => 'https://events.us-east-1.amazonaws.com'});

=head1 SEE OTHER

C<Amazon::Credentials>, C<Amazon::API::Error>

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut

1;

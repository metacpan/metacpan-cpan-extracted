package Amazon::SQS::Credentials;

use strict;
use warnings;

# faux Credentials class - just provides getters

__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_accessors(qw(aws_access_key_id aws_secret_access_key token loglevel));

use parent qw(Class::Accessor::Fast);

our $VERSION = '2.0.7';

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $client_options;

  if ( @args > 2 ) {
    if ( ref $args[2] ) {
      $client_options = $args[2];
    }
    else {
      $client_options = $args[3] // {};
      $client_options->{SecurityToken} = $args[2];
    }
  }

  return $class->SUPER::new(
    { aws_access_key_id     => $args[0],
      aws_secret_access_key => $args[1],
      $client_options->{SecurityToken} ? ( token    => $client_options->{SecurityToken} ) : (),
      $client_options->{loglevel}      ? ( loglevel => $client_options->{loglevel} )      : (),
    }
  );
}

################################################################################
#  Copyright 2008 Amazon Technologies, Inc.
#  Licensed under the Apache License, Version 2.0 (the "License");
#
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at: http://aws.amazon.com/apache2.0
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#  CONDITIONS OF ANY KIND, either express or implied. See the License for the
#  specific language governing permissions and limitations under the License.
#
#  Copyright 2024 Robert C. Lauer
#
#  Note: The software contained in this distribution has been modified from the
#  original. You may freely use and distribute this software under the
#  terms of the original license.

package Amazon::SQS::Client;

use strict;
use warnings;

use Amazon::Credentials;
use Amazon::SQS::Constants qw(:all);
use Amazon::SQS::Exception;
use Carp qw(croak);
use Data::Dumper;
use Digest::SHA qw (hmac_sha1_base64 hmac_sha256_base64);
use English qw(-no_match_vars);
use LWP::UserAgent;
use Scalar::Util qw(reftype);
use Time::HiRes qw(usleep);
use URI::Escape;
use URI;
use XML::Simple;

__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_accessors(
  qw(
    ServiceURL
    UserAgent
    SignatureVersion
    SignatureMethod
    MaxErrorRetry
    ServiceVersion
    SecurityToken
    Region
    v4_signer
    credentials
    last_request
    last_response
  )
);

use parent qw(Class::Accessor::Fast);

our $VERSION = '@PACKAGE_VERSION';

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options;

  if ( ref $args[0] ) {
    $options = $args[0];
  }
  elsif ( $args[0] && $args[1] ) {
    my $credentials = Amazon::SQS::Credentials->new(@args);

    $options = { credentials => $credentials };

    if ( ref $args[2] ) {
      $options = { %{$options}, %{ $args[2] } };
    }
  }
  else {
    $options = ref $args[2] ? $args[2] : {};
    $options->{credentials} //= Amazon::Credentials->new();
  }

  set_defaults($options);

  my $self = $class->SUPER::new($options);

  $self->init_v4_signer;

  return $self;
}

########################################################################
sub set_defaults {
########################################################################
  my ($options) = @_;

  $options->{SignatureVersion} //= 2;
  $options->{SignatureMethod}  //= 'HmacSHA256';
  $options->{MaxErrorRetry}    //= 3;
  $options->{ServiceVersion}   //= '2012-11-05';

  if ( $options->{Region} && !$options->{ServiceURL} ) {
    $options->{ServiceURL} = sprintf 'https://sqs.%s.amazonaws.com', $options->{Region};
  }
  elsif ( !$options->{ServiceURL} ) {
    $options->{ServiceURL} = 'https://queue.amazonaws.com';
  }

  if ( !$options->{UserAgent} ) {
    require LWP::UserAgent;
    $options->{UserAgent} = LWP::UserAgent->new;
  }

  return $options;
}

########################################################################
sub init_v4_signer {
########################################################################
  my ($self) = @_;

  return
    if $self->get_SignatureVersion ne '4';

  my $credentials = $self->get_credentials;

  my $aws_access_key_id     = $credentials->get_aws_access_key_id;
  my $aws_secret_access_key = $credentials->get_aws_secret_access_key;
  my $token                 = $credentials->get_token;

  require AWS::Signature4;

  $self->set_v4_signer(
    AWS::Signature4->new(
      '-access_key' => $aws_access_key_id,
      '-secret_key' => $aws_secret_access_key,
      $token
      ? ( '-security_token' => $token )
      : ()

    )
  );

  return;
}

# setter/getters for resetting credentials
########################################################################
sub aws_access_key_id {
########################################################################
  my ( $self, @args ) = @_;

  if (@args) {
    $self->get_credentials->set_aws_access_key_id( $args[0] );
  }

  return $self->get_credentials->get_aws_access_key_id();
}

########################################################################
sub aws_secret_access_key {
########################################################################
  my ( $self, @args ) = @_;

  if (@args) {
    $self->get_credentials->set_aws_secret_access_key( $args[0] );
  }

  return $self->get_credentials->get_aws_secret_access_key();
}

########################################################################
sub token {
########################################################################
  my ( $self, @args ) = @_;

  if (@args) {
    $self->get_credentials->set_token( $args[0] );
  }

  return $self->get_credentials->get_token();
}

########################################################################
sub createQueue {
########################################################################
  my ( $self, $request ) = @_;

  if ( ref $request ne 'Amazon::SQS::Model::CreateQueueRequest' ) {
    require Amazon::SQS::Model::CreateQueueRequest;
    $request = Amazon::SQS::Model::CreateQueueRequest->new($request);
  }

  require Amazon::SQS::Model::CreateQueueResponse;

  return Amazon::SQS::Model::CreateQueueResponse->fromXML(
    $self->_invoke( $self->_convertCreateQueue($request) ) );
}

########################################################################
sub listQueues {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::ListQueuesRequest' ) {
    require Amazon::SQS::Model::ListQueuesRequest;
    $request = Amazon::SQS::Model::ListQueuesRequest->new($request);
  }

  require Amazon::SQS::Model::ListQueuesResponse;

  return Amazon::SQS::Model::ListQueuesResponse->fromXML(
    $self->_invoke( $self->_convertListQueues($request) ) );
}

########################################################################
sub listDeadLetterSourceQueues {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::ListDeadLetterSourceQueuesRequest' ) {
    require Amazon::SQS::Model::ListDeadLetterSourceQueuesRequest;
    $request = Amazon::SQS::Model::ListDeadLetterSourceQueuesRequest->new($request);
  }

  require Amazon::SQS::Model::ListDeadLetterSourceQueuesResponse;

  return Amazon::SQS::Model::ListDeadLetterSourceQueuesResponse->fromXML(
    $self->_invoke( $self->_convertListDeadLetterSourceQueues($request) ) );
}

########################################################################
sub addPermission {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::AddPermissionRequest' ) {
    require Amazon::SQS::Model::AddPermissionRequest;
    $request = Amazon::SQS::Model::AddPermissionRequest->new($request);
  }
  require Amazon::SQS::Model::AddPermissionResponse;
  return Amazon::SQS::Model::AddPermissionResponse->fromXML(
    $self->_invoke( $self->_convertAddPermission($request) ) );
}

########################################################################
sub changeMessageVisibility {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::ChangeMessageVisibilityRequest' ) {
    require Amazon::SQS::Model::ChangeMessageVisibilityRequest;
    $request = Amazon::SQS::Model::ChangeMessageVisibilityRequest->new($request);
  }

  require Amazon::SQS::Model::ChangeMessageVisibilityResponse;

  return Amazon::SQS::Model::ChangeMessageVisibilityResponse->fromXML(
    $self->_invoke( $self->_convertChangeMessageVisibility($request) ) );
}

########################################################################
sub changeMessageVisibilityBatch {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::ChangeMessageVisibilityBatchRequest' ) {
    require Amazon::SQS::Model::ChangeMessageVisibilityBatchRequest;
    $request = Amazon::SQS::Model::ChangeMessageVisibilityBatchRequest->new($request);
  }

  require Amazon::SQS::Model::ChangeMessageVisibilityBatchResponse;

  return Amazon::SQS::Model::ChangeMessageVisibilityBatchResponse->fromXML(
    $self->_invoke( $self->_convertChangeMessageVisibilityBatch($request) ) );
}

########################################################################
sub deleteMessage {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::DeleteMessageRequest' ) {
    require Amazon::SQS::Model::DeleteMessageRequest;
    $request = Amazon::SQS::Model::DeleteMessageRequest->new($request);
  }

  require Amazon::SQS::Model::DeleteMessageResponse;

  return Amazon::SQS::Model::DeleteMessageResponse->fromXML(
    $self->_invoke( $self->_convertDeleteMessage($request) ) );
}

########################################################################
sub deleteMessageBatch {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::DeleteMessageBatchRequest' ) {
    require Amazon::SQS::Model::DeleteMessageBatchRequest;
    $request = Amazon::SQS::Model::DeleteMessageBatchRequest->new($request);
  }

  require Amazon::SQS::Model::DeleteMessageBatchResponse;

  return Amazon::SQS::Model::DeleteMessageBatchResponse->fromXML(
    $self->_invoke( $self->_convertDeleteMessageBatch($request) ) );
}

########################################################################
sub deleteQueue {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::DeleteQueueRequest' ) {
    require Amazon::SQS::Model::DeleteQueueRequest;
    $request = Amazon::SQS::Model::DeleteQueueRequest->new($request);
  }

  require Amazon::SQS::Model::DeleteQueueResponse;

  return Amazon::SQS::Model::DeleteQueueResponse->fromXML(
    $self->_invoke( $self->_convertDeleteQueue($request) ) );
}

########################################################################
sub getQueueAttributes {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::GetQueueAttributesRequest' ) {
    require Amazon::SQS::Model::GetQueueAttributesRequest;

    $request = Amazon::SQS::Model::GetQueueAttributesRequest->new($request);
  }

  require Amazon::SQS::Model::GetQueueAttributesResponse;

  return Amazon::SQS::Model::GetQueueAttributesResponse->fromXML(
    $self->_invoke( $self->_convertGetQueueAttributes($request) ) );
}

########################################################################
sub removePermission {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::RemovePermissionRequest' ) {
    require Amazon::SQS::Model::RemovePermissionRequest;
    $request = Amazon::SQS::Model::RemovePermissionRequest->new($request);
  }

  require Amazon::SQS::Model::RemovePermissionResponse;

  return Amazon::SQS::Model::RemovePermissionResponse->fromXML(
    $self->_invoke( $self->_convertRemovePermission($request) ) );
}

########################################################################
sub receiveMessage {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::ReceiveMessageRequest' ) {
    require Amazon::SQS::Model::ReceiveMessageRequest;
    $request = Amazon::SQS::Model::ReceiveMessageRequest->new($request);
  }

  require Amazon::SQS::Model::ReceiveMessageResponse;

  return Amazon::SQS::Model::ReceiveMessageResponse->fromXML(
    $self->_invoke( $self->_convertReceiveMessage($request) ) );
}

########################################################################
sub sendMessage {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::SendMessageRequest' ) {
    require Amazon::SQS::Model::SendMessageRequest;
    $request = Amazon::SQS::Model::SendMessageRequest->new($request);
  }

  require Amazon::SQS::Model::SendMessageResponse;

  return Amazon::SQS::Model::SendMessageResponse->fromXML(
    $self->_invoke( $self->_convertSendMessage($request) ) );
}

########################################################################
sub setQueueAttributes {
########################################################################
  my ( $self, $request ) = @_;

  if ( not ref $request eq 'Amazon::SQS::Model::SetQueueAttributesRequest' ) {
    require Amazon::SQS::Model::SetQueueAttributesRequest;
    $request = Amazon::SQS::Model::SetQueueAttributesRequest->new($request);
  }

  require Amazon::SQS::Model::SetQueueAttributesResponse;
  return Amazon::SQS::Model::SetQueueAttributesResponse->fromXML(
    $self->_invoke( $self->_convertSetQueueAttributes($request) ) );
}

#
# Invoke request and return response
#
########################################################################
sub _invoke {
########################################################################
  my ( $self, $parameters ) = @_;

  my $actionName = $parameters->{Action};

  my $statusCode = $HTTP_OK;

  my $queueUrl = defined $parameters->{QueueUrl} ? $parameters->{QueueUrl} : $self->get_ServiceURL;

  if ( defined $parameters->{QueueUrl} ) {
    delete $parameters->{QueueUrl};
  }

  # Add required request parameters #
  $parameters = $self->_addRequiredParameters( $parameters, $queueUrl );
  my $retries     = 0;
  my $shouldRetry = $TRUE;

  my $response;

  eval {
    do {
      # Submit the request and read response body #
      eval {
        $response = $self->_httpPost( $queueUrl, $parameters );

        if ( $response->is_success ) {
          $shouldRetry = $FALSE;
        }
        else {
          if ( $response->code == $HTTP_INTERNAL_SERVER_ERROR || $response->code == $HTTP_GATEWAY_TIMEOUT ) {
            $shouldRetry = $TRUE;
            $self->_pauseOnRetry( ++$retries, $response->code, $response->content );
          }
          else {
            my $ex = $self->_reportAnyErrors( $response->content, $response->code );

            if ($ex) {
              Carp::croak($ex);
            }
          }
        }
      };

      my $e = $EVAL_ERROR;

      if ($e) {
        if ( ref $e eq 'Amazon::SQS::Exception' ) {
          Carp::croak $e;
        }
        else {
          Carp::croak( Amazon::SQS::Exception->new( { Message => $e } ) );
        }
      }
    } while ($shouldRetry);  ## no critic
  };

  my $e = $EVAL_ERROR;

  if ($e) {
    if ( ref $e eq 'Amazon::SQS::Exception' ) {
      Carp::croak $e;
    }
    else {
      Carp::croak( Amazon::SQS::Exception->new( { Message => $e } ) );
    }
  }

  return $response->content;
}

#
# Exponential sleep on failed request
# Retries - current retry
# throws Amazon::SQS::Exception if maximum number of retries has been reached
#
########################################################################
sub _pauseOnRetry {
########################################################################
  my ( $self, $retries, $status, $error ) = @_;

  if ( $retries <= $self->get_MaxErrorRetry ) {
    my $delay = ( 4**$retries ) * 100_000;
    usleep($delay);
  }
  else {

    die Amazon::SQS::Exception->new(
      { Message    => 'Maximum number of retry attempts reached :  ' . ( $retries - 1 ),
        StatusCode => $status,
        HTTPError  => $error,
        ErrorCode  => $status,
      }
    );
  }

  return;
}

#
# Look for additional error strings in the response and return formatted exception
#
########################################################################
sub _reportAnyErrors {
########################################################################
  my ( $self, $responseBody, $status, $e ) = @_;

  my $ex = eval {
    my $error = XML::Simple::XMLin($responseBody);

    return $responseBody
      if !ref $error || !$error->{Error};

    #<ErrorResponse xmlns="http://queue.amazonaws.com/doc/2012-11-05/">
    #  <Error>
    #    <Code>AWS.SimpleQueueService.NonExistentQueue</Code>
    #    <Message>The specified queue does not exist for this wsdl version.</Message>
    #    <Type>Sender</Type>
    #  </Error>
    # <RequestId>1bae4a91-7804-45a5-94b0-c884ddc2f140</RequestId>
    #</ErrorResponse>

    if ( $error->{Error} ) {

      my $requestId = $error->{RequestId};
      my $code      = $error->{Error}->{Code};
      my $message   = $error->{Error}->{Message};

      return Amazon::SQS::Exception->new(
        { Message    => $message,
          StatusCode => $status,
          ErrorCode  => $code,
          ErrorType  => $error->{Error}->{Type} // 'Unknown',
          RequestId  => $requestId,
          XML        => $responseBody
        }
      );
    }
  };

  return $ex
    if ref $ex;

  return Amazon::SQS::Exception->new(
    { Message      => 'Internal Error',
      StatusCode   => $status,
      ResponseBody => $responseBody,
    }
  );
}

#
# perform http post
#
########################################################################
sub _httpPost {
########################################################################
  my ( $self, $queueUrl, $parameters ) = @_;

  my $url = $queueUrl;

  my $ua = $self->get_UserAgent;

  my $request = HTTP::Request->new( POST => $url );
  $request->content_type('application/x-www-form-urlencoded; charset=utf-8');

  my $data = $EMPTY;

  foreach my $parameterName ( keys %{$parameters} ) {
    no warnings 'uninitialized';  ## no critic

    $data .= $parameterName . $EQUALS . $self->_urlencode( $parameters->{$parameterName}, 0 );
    $data .= $AMPERSAND;
  }

  chop $data;

  $request->content($data);

  # sign request here if v4 else, it is done in _addRequiredParameters()
  if ( defined $self->get_v4_signer ) {
    $self->get_v4_signer->sign($request);
  }

  $self->set_last_request($request);

  my $response = $ua->request($request);

  $self->set_last_response($response);

  return $response;
}

#
# Add authentication related and version parameters
#
sub _addRequiredParameters {
  my ( $self, $parameters, $queueUrl ) = @_;

  my $credentials           = $self->get_credentials;
  my $token                 = $credentials->get_token;
  my $aws_access_key_id     = $credentials->get_aws_access_key_id;
  my $aws_secret_access_key = $credentials->get_aws_secret_access_key;

  $parameters->{AWSAccessKeyId} = $aws_access_key_id;
  $parameters->{Timestamp}      = $self->_getFormattedTimestamp();
  $parameters->{Version}        = $self->get_ServiceVersion;

  # v2 signing
  if ( !defined $self->{_v4_signer} ) {
    if ($token) {
      $parameters->{SecurityToken} = $token;
    }

    $parameters->{SignatureVersion} = $self->get_SignatureVersion || '1';
    $parameters->{Signature}        = $self->_signParameters( $parameters, $queueUrl, $aws_secret_access_key );
  }

  return $parameters;
}

#
# Computes RFC 2104-compliant HMAC signature for request parameters
# Implements AWS Signature, as per following spec:
#
# If Signature Version is 0, it signs concatenated Action and Timestamp
#
# If Signature Version is 1, it performs the following:
#
# Sorts all  parameters (including SignatureVersion and excluding Signature,
# the value of which is being created), ignoring case.
#
# Iterate over the sorted list and append the parameter name (in original case)
# and then its value. It will not URL-encode the parameter values before
# constructing this string. There are no separators.
#
sub _signParameters {
  my ( $self, $parameters, $queueUrl, $key ) = @_;

  my $algorithm = 'HmacSHA1';
  my $data      = $EMPTY;

  my $signatureVersion = $parameters->{SignatureVersion};

  if ( '0' eq $signatureVersion ) {
    $data = $self->_calculateStringToSignV0($parameters);
  }
  elsif ( '1' eq $signatureVersion ) {
    $data = $self->_calculateStringToSignV1($parameters);
  }
  elsif ( '2' eq $signatureVersion ) {
    $algorithm                     = $self->get_SignatureMethod;
    $parameters->{SignatureMethod} = $algorithm;
    $data                          = $self->_calculateStringToSignV2( $parameters, $queueUrl );
  }
  else {
    Carp::croak('Invalid Signature Version specified');
  }

  return $self->_sign( $data, $key, $algorithm );
}

sub _calculateStringToSignV0 {
  my ( $self, $parameters ) = @_;
  return $parameters->{Action} . $parameters->{Timestamp};
}

sub _calculateStringToSignV1 {
  my ( $self, $parameters ) = @_;
  my $data = $EMPTY;

  foreach my $parameterName ( sort { lc($a) cmp lc $b } keys %{$parameters} ) {
    no warnings 'uninitialized';  ## no critic

    $data .= $parameterName . $parameters->{$parameterName};
  }

  return $data;
}

sub _calculateStringToSignV2 {
  my ( $self, $parameters, $queueUrl ) = @_;

  my $endpoint = URI->new($queueUrl);
  my $data     = 'POST';
  $data .= "\n";
  $data .= $endpoint->host;
  $data .= "\n";

  my $path = $endpoint->path || $SLASH;
  $data .= $self->_urlencode( $path, 1 );
  $data .= "\n";

  my @parameterKeys = keys %{$parameters};

  foreach my $parameterName ( sort { $a cmp $b } @parameterKeys ) {
    no warnings 'uninitialized';  ## no critic
    $data .= $parameterName . $EQUALS . $self->_urlencode( $parameters->{$parameterName} );
    $data .= $AMPERSAND;
  }

  chop $data;

  return $data;
}

########################################################################
sub _urlencode {
########################################################################
  my ( $self, $value, $path ) = @_;

  use URI::Escape qw(uri_escape_utf8);

  my $escapepattern = '^A-Za-z0-9\-_.~';

  if ($path) {
    $escapepattern = $escapepattern . $SLASH;
  }

  return uri_escape_utf8( $value, $escapepattern );
}

#
# Computes RFC 2104-compliant HMAC signature.
#
sub _sign {
  my ( $self, $data, $key, $algorithm ) = @_;

  my $output = $EMPTY;

  if ( 'HmacSHA1' eq $algorithm ) {
    $output = hmac_sha1_base64( $data, $key );
  }
  elsif ( 'HmacSHA256' eq $algorithm ) {
    $output = hmac_sha256_base64( $data, $key );
  }
  else {
    Carp::croak('Non-supported signing method specified');
  }

  return $output . $EQUALS;
}

#
# Formats date as ISO 8601 timestamp
#
sub _getFormattedTimestamp {
  return sprintf '%04d-%02d-%02dT%02d:%02d:%02d.000Z', sub {
    ( $_[5] + 1900, $_[4] + 1, $_[3], $_[2], $_[1], $_[0] )
    }
    ->( gmtime time );
}

#
# Convert CreateQueueRequest to name value pairs
#
sub _convertCreateQueue() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'CreateQueue';

  if ( $request->isSetQueueName() ) {
    $parameters->{'QueueName'} = $request->getQueueName();
  }

  if ( $request->isSetDefaultVisibilityTimeout() ) {
    $parameters->{'DefaultVisibilityTimeout'} = $request->getDefaultVisibilityTimeout();
  }

  my $attributecreateQueueRequestList = $request->getAttribute();

  for my $attributecreateQueueRequestIndex ( 0 .. $#{$attributecreateQueueRequestList} ) {
    my $attributecreateQueueRequest = $attributecreateQueueRequestList->[$attributecreateQueueRequestIndex];
    if ( $attributecreateQueueRequest->isSetName() ) {
      $parameters->{ 'Attribute.' . ( $attributecreateQueueRequestIndex + 1 ) . '.Name' }
        = $attributecreateQueueRequest->getName();
    }

    if ( $attributecreateQueueRequest->isSetValue() ) {
      $parameters->{ 'Attribute.' . ( $attributecreateQueueRequestIndex + 1 ) . '.Value' }
        = $attributecreateQueueRequest->getValue();
    }
  }

  return $parameters;
}

#
# Convert ListQueuesRequest to name value pairs
#
sub _convertListQueues() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'ListQueues';

  if ( $request->isSetQueueNamePrefix() ) {
    $parameters->{'QueueNamePrefix'} = $request->getQueueNamePrefix();
  }
  my $attributelistQueuesRequestList = $request->getAttribute();

  for my $attributelistQueuesRequestIndex ( 0 .. $#{$attributelistQueuesRequestList} ) {
    my $attributelistQueuesRequest = $attributelistQueuesRequestList->[$attributelistQueuesRequestIndex];

    if ( $attributelistQueuesRequest->isSetName() ) {
      $parameters->{ 'Attribute.' . ( $attributelistQueuesRequestIndex + 1 ) . '.Name' }
        = $attributelistQueuesRequest->getName();
    }
    if ( $attributelistQueuesRequest->isSetValue() ) {
      $parameters->{ 'Attribute.' . ( $attributelistQueuesRequestIndex + 1 ) . '.Value' }
        = $attributelistQueuesRequest->getValue();
    }

  }

  return $parameters;
}

#
# Convert ListDeadLetterSourceQueues to name value pairs
#
sub _convertListDeadLetterSourceQueues() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'ListDeadLetterSourceQueues';

  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }

  return $parameters;
}

#
# Convert ChangeMessageVisibilityRequest to name value pairs
#
sub _convertChangeMessageVisibility() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'ChangeMessageVisibility';

  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }

  if ( $request->isSetReceiptHandle() ) {
    $parameters->{'ReceiptHandle'} = $request->getReceiptHandle();
  }

  if ( $request->isSetVisibilityTimeout() ) {
    $parameters->{'VisibilityTimeout'} = $request->getVisibilityTimeout();
  }

  my $attributechangeMessageVisibilityRequestList = $request->getAttribute();

  for
    my $attributechangeMessageVisibilityRequestIndex ( 0 .. $#{$attributechangeMessageVisibilityRequestList} ) {
    my $attributechangeMessageVisibilityRequest
      = $attributechangeMessageVisibilityRequestList->[$attributechangeMessageVisibilityRequestIndex];

    if ( $attributechangeMessageVisibilityRequest->isSetName() ) {
      $parameters->{ 'Attribute.' . ( $attributechangeMessageVisibilityRequestIndex + 1 ) . '.Name' }
        = $attributechangeMessageVisibilityRequest->getName();
    }

    if ( $attributechangeMessageVisibilityRequest->isSetValue() ) {
      $parameters->{ 'Attribute.' . ( $attributechangeMessageVisibilityRequestIndex + 1 ) . '.Value' }
        = $attributechangeMessageVisibilityRequest->getValue();
    }
  }

  return $parameters;
}

sub _convertChangeMessageVisibilityBatch() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'ChangeMessageVisibilityBatch';

  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }

  if ( $request->isSetBatchRequest() ) {
    my $batchrequestchangeMessageVisibilityRequestList = $request->getBatchRequest();

    foreach my $batchrequestEntryIndex ( 0 .. $#{$batchrequestchangeMessageVisibilityRequestList} ) {
      my $batchrequestEntry = $batchrequestchangeMessageVisibilityRequestList->[$batchrequestEntryIndex];

      if ( $batchrequestEntry->isSetId() ) {
        $parameters->{ 'ChangeMessageVisibilityBatchRequestEntry.' . ( $batchrequestEntryIndex + 1 ) . '.Id' }
          = $batchrequestEntry->getId();
      }

      if ( $batchrequestEntry->isSetReceiptHandle() ) {
        $parameters->{ 'ChangeMessageVisibilityBatchRequestEntry.'
            . ( $batchrequestEntryIndex + 1 )
            . '.ReceiptHandle' } = $batchrequestEntry->getReceiptHandle();
      }

      if ( $batchrequestEntry->isSetVisibilityTimeout() ) {
        $parameters->{ 'ChangeMessageVisibilityBatchRequestEntry.'
            . ( $batchrequestEntryIndex + 1 )
            . '.VisibilityTimeout' } = $batchrequestEntry->getVisibilityTimeout();
      }
    }
  }

  return $parameters;
}

#
# Convert DeleteMessageRequest to name value pairs
#
sub _convertDeleteMessage() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'DeleteMessage';
  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }
  if ( $request->isSetReceiptHandle() ) {
    $parameters->{ReceiptHandle} = $request->getReceiptHandle();
  }
  my $attributedeleteMessageRequestList = $request->getAttribute();
  for my $attributedeleteMessageRequestIndex ( 0 .. $#{$attributedeleteMessageRequestList} ) {
    my $attributedeleteMessageRequest
      = $attributedeleteMessageRequestList->[$attributedeleteMessageRequestIndex];
    if ( $attributedeleteMessageRequest->isSetName() ) {
      $parameters->{ 'Attribute.' . ( $attributedeleteMessageRequestIndex + 1 ) . '.Name' }
        = $attributedeleteMessageRequest->getName();
    }

    if ( $attributedeleteMessageRequest->isSetValue() ) {
      $parameters->{ 'Attribute.' . ( $attributedeleteMessageRequestIndex + 1 ) . '.Value' }
        = $attributedeleteMessageRequest->getValue();
    }

  }

  return $parameters;
}

sub _convertDeleteMessageBatch() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'DeleteMessageBatch';
  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }

  if ( $request->isSetDeleteMessageBatchRequestEntry() ) {
    my $batchrequestList = $request->getDeleteMessageBatchRequestEntry();

    foreach my $batchrequestEntryIndex ( 0 .. $#{$batchrequestList} ) {
      my $batchrequestEntry = $batchrequestList->[$batchrequestEntryIndex];

      if ( $batchrequestEntry->isSetId() ) {
        $parameters->{ 'DeleteMessageBatchRequestEntry.' . ( $batchrequestEntryIndex + 1 ) . '.Id' }
          = $batchrequestEntry->getId();
      }

      if ( $batchrequestEntry->isSetReceiptHandle() ) {
        $parameters->{ 'DeleteMessageBatchRequestEntry.' . ( $batchrequestEntryIndex + 1 ) . '.ReceiptHandle' }
          = $batchrequestEntry->getReceiptHandle();
      }
    }
  }

  return $parameters;
}

#
# Convert DeleteQueueRequest to name value pairs
#
sub _convertDeleteQueue() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'DeleteQueue';

  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }
  my $attributedeleteQueueRequestList = $request->getAttribute();
  for my $attributedeleteQueueRequestIndex ( 0 .. $#{$attributedeleteQueueRequestList} ) {
    my $attributedeleteQueueRequest = $attributedeleteQueueRequestList->[$attributedeleteQueueRequestIndex];
    if ( $attributedeleteQueueRequest->isSetName() ) {
      $parameters->{ 'Attribute.' . ( $attributedeleteQueueRequestIndex + 1 ) . '.Name' }
        = $attributedeleteQueueRequest->getName();
    }
    if ( $attributedeleteQueueRequest->isSetValue() ) {
      $parameters->{ 'Attribute.' . ( $attributedeleteQueueRequestIndex + 1 ) . '.Value' }
        = $attributedeleteQueueRequest->getValue();
    }

  }

  return $parameters;
}

#
# Convert GetQueueAttributesRequest to name value pairs
#
sub _convertGetQueueAttributes() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'GetQueueAttributes';
  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }
  my $attributeNamegetQueueAttributesRequestList = $request->getAttributeName();
  for my $attributeNamegetQueueAttributesRequestIndex ( 0 .. $#{$attributeNamegetQueueAttributesRequestList} ) {
    my $attributeNamegetQueueAttributesRequest
      = $attributeNamegetQueueAttributesRequestList->[$attributeNamegetQueueAttributesRequestIndex];
    $parameters->{ 'AttributeName.' . ( $attributeNamegetQueueAttributesRequestIndex + 1 ) }
      = $attributeNamegetQueueAttributesRequest;
  }

  return $parameters;
}

#
# Convert ReceiveMessageRequest to name value pairs
#
sub _convertReceiveMessage() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'ReceiveMessage';
  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }
  if ( $request->isSetMaxNumberOfMessages() ) {
    $parameters->{MaxNumberOfMessages} = $request->getMaxNumberOfMessages();
  }
  if ( $request->isSetVisibilityTimeout() ) {
    $parameters->{VisibilityTimeout} = $request->getVisibilityTimeout();
  }

  if ( $request->isSetWaitTimeSeconds() ) {
    $parameters->{WaitTimeSeconds} = $request->getWaitTimeSeconds();
  }

  my $attributeNamereceiveMessageRequestList = $request->getAttributeName();
  for my $attributeNamereceiveMessageRequestIndex ( 0 .. $#{$attributeNamereceiveMessageRequestList} ) {
    my $attributeNamereceiveMessageRequest
      = $attributeNamereceiveMessageRequestList->[$attributeNamereceiveMessageRequestIndex];
    $parameters->{ 'AttributeName.' . ( $attributeNamereceiveMessageRequestIndex + 1 ) }
      = $attributeNamereceiveMessageRequest;
  }

  my $messageAttributeNamereceiveMessageRequestList = $request->getMessageAttributeName();
  for my $messageAttributeNamereceiveMessageRequestIndex (
    0 .. $#{$messageAttributeNamereceiveMessageRequestList} ) {
    my $messageAttributeNamereceiveMessageRequest
      = $messageAttributeNamereceiveMessageRequestList->[$messageAttributeNamereceiveMessageRequestIndex];
    $parameters->{ 'MessageAttributeName.' . ( $messageAttributeNamereceiveMessageRequestIndex + 1 ) }
      = $messageAttributeNamereceiveMessageRequest;
  }

  return $parameters;
}

#
# Convert SendMessageRequest to name value pairs
#
sub _convertSendMessage() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'SendMessage';
  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }

  if ( $request->isSetMessageBody() ) {
    $parameters->{MessageBody} = $request->getMessageBody();
  }

  if ( $request->isSetMessageDuplicationId() ) {
    $parameters->{MessageDuplicationId} = $request->getMessageDuplicationId();
  }

  if ( $request->isSetMessageGroupId() ) {
    $parameters->{MessageGroupId} = $request->getMessageGroupId();
  }

  if ( $request->isSetDelaySeconds() ) {
    $parameters->{DelaySeconds} = $request->getDelaySeconds();
  }

  my $attributesendMessageRequestList = $request->getMessageAttribute();
  for my $attributesendMessageRequestIndex ( 0 .. $#{$attributesendMessageRequestList} ) {
    my $attributesendMessageRequest = $attributesendMessageRequestList->[$attributesendMessageRequestIndex];

    if ( $attributesendMessageRequest->isSetName() ) {
      $parameters->{ 'MessageAttribute.' . ( $attributesendMessageRequestIndex + 1 ) . '.Name' }
        = $attributesendMessageRequest->getName();
    }

    my $value = $attributesendMessageRequest->getValue();

    if ( $value->isSetDataType() ) {
      $parameters->{ 'MessageAttribute.' . ( $attributesendMessageRequestIndex + 1 ) . '.Value.DataType' }
        = $value->getDataType();
    }

    if ( $value->isSetStringValue() ) {
      $parameters->{ 'MessageAttribute.' . ( $attributesendMessageRequestIndex + 1 ) . '.Value.StringValue' }
        = $value->getStringValue();
    }

    if ( $value->isSetBinaryValue() ) {
      $parameters->{ 'MessageAttribute.' . ( $attributesendMessageRequestIndex + 1 ) . '.Value.BinaryValue' }
        = $value->getBinaryValue();
    }
  }

  return $parameters;
}

#
# Convert SetQueueAttributesRequest to name value pairs
#
sub _convertSetQueueAttributes() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'SetQueueAttributes';
  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }
  my $attributesetQueueAttributesRequestList = $request->getAttribute();
  for my $attributesetQueueAttributesRequestIndex ( 0 .. $#{$attributesetQueueAttributesRequestList} ) {
    my $attributesetQueueAttributesRequest
      = $attributesetQueueAttributesRequestList->[$attributesetQueueAttributesRequestIndex];
    if ( $attributesetQueueAttributesRequest->isSetName() ) {
      $parameters->{ 'Attribute.' . ( $attributesetQueueAttributesRequestIndex + 1 ) . '.Name' }
        = $attributesetQueueAttributesRequest->getName();
    }
    if ( $attributesetQueueAttributesRequest->isSetValue() ) {
      $parameters->{ 'Attribute.' . ( $attributesetQueueAttributesRequestIndex + 1 ) . '.Value' }
        = $attributesetQueueAttributesRequest->getValue();
    }

  }

  return $parameters;
}

#
# Convert AddPermissionRequest to name value pairs
#
sub _convertAddPermission() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'AddPermission';

  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }

  if ( $request->isSetLabel() ) {
    $parameters->{Label} = $request->getLabel();
  }

  my $AWSAccountIdaddPermissionRequestList = $request->getAWSAccountId();

  for my $AWSAccountIdaddPermissionRequestIndex ( 0 .. $#{$AWSAccountIdaddPermissionRequestList} ) {
    my $AWSAccountIdaddPermissionRequest
      = $AWSAccountIdaddPermissionRequestList->[$AWSAccountIdaddPermissionRequestIndex];
    $parameters->{ 'AWSAccountId.' . ( $AWSAccountIdaddPermissionRequestIndex + 1 ) }
      = $AWSAccountIdaddPermissionRequest;
  }

  my $actionNameaddPermissionRequestList = $request->getActionName();

  for my $actionNameaddPermissionRequestIndex ( 0 .. $#{$actionNameaddPermissionRequestList} ) {
    my $actionNameaddPermissionRequest
      = $actionNameaddPermissionRequestList->[$actionNameaddPermissionRequestIndex];
    $parameters->{ 'ActionName.' . ( $actionNameaddPermissionRequestIndex + 1 ) }
      = $actionNameaddPermissionRequest;
  }

  return $parameters;
}

#
# Convert RemovePermissionRequest to name value pairs
#
sub _convertRemovePermission() {
  my ( $self, $request ) = @_;

  my $parameters = {};
  $parameters->{Action} = 'RemovePermission';
  if ( $request->isSetQueueUrl() ) {
    $parameters->{QueueUrl} = $request->getQueueUrl();
  }
  if ( $request->isSetLabel() ) {
    $parameters->{Label} = $request->getLabel();
  }

  return $parameters;
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

Amazon::SQS::Client - client interface to Amazon Simple Queue Service

=head1 SYNOPSIS

 # create an HTTP client
 my $client = Amazon::SQS::Client->new( $AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY );

 # send a message
 my $response = $client->sendMessage(
   { QueueUrl    => $AWS_QUEUE_URL,
     MessageBody => $message
   }
 );

=head1 DESCRIPTION

L<Amazon::SQS::Client> is the implementation of a service API to
AmazonE<039>s Simple Queue Service.

I<NOTE: The classes that implement the SQS Perl framework were
originally provided by AWS back in the day when Perl was an important
part of the AWS development stack. Fast forward to 2024 and Perl is no
longer a supported language in the AWS SDK ecosystem. These modules
"work" and provide a fairly simple toolset for working with SQS. There
are more popular and perhaps more supported packages available for
interacting with SQS. See L</SEE ALSO> for recommended alternatives.
You may however find this implementation lighter in weight than other
implementations.>

=head1 DETAILS

Amazon Simple Queue Service (Amazon SQS) offers a reliable, highly
scalable hosted queue for storing messages as they travel between
computers.

By using Amazon SQS, developers can simply move data between
distributed application components performing different tasks, without
losing messages or requiring each component to be always available.
Amazon SQS works by exposing Amazon's web-scale messaging
infrastructure as a web service. Any computer on the Internet can add
or read messages without any installed software or special firewall
configurations. Components of applications using Amazon SQS can run
independently, and do not need to be on the same network, developed
with the same technologies, or running at the same time.

=head1 METHODS AND SUBROUTINES

=head2 new 

 new( aws-access-key-id, aws-secret-access-key, [token], [options] )

=over 5

=item aws-access-key-id

The AWS I<access key> your were given when you signed up for AWS services.

You can create a new account by visiting L</http://aws.amazon.com/>.

=item aws-secret-access-key

The AWS I<secret access key> you were given when you signed up for AWS services.

=item token

Pass the session token as the third argument on as SecurityToken in
the options hash described below.

=item options

C<options> is an optional hash reference containing the options listed
below.

=over 5

=item * ServiceURL

default: C<https://queue.amazonaws.com>

Set the ServiceUrl when you want to use a mocking service like
L<LocalStack|https://www.localstack.cloud>.

=item * UserAgent

default: LWP::UserAgent

=item * SignatureVersion

default: 2

I<Note: Signature Version 4 is supported by AWS::Signature4. If you
use the Signature 4 signing facility, make sure your ServiceURL
includes the region endpoint.  Ex:
https://sqs.us-east-1.amazonaws.com.>

=item * SecurityToken

For temporary credentials, add the security token returned from the
AWS Security Token Service.

=item * ServiceVersion

default: 2012-11-05

=item * MaxErrorRetry

default: 3

=item * credentials

An instance of a class (e.g. Amazon::Credentials) which supports the getters:

 get_aws_access_key_id
 get_aws_secret_access_key
 get_token

You are encouraged to use this option rather than sending the
credentials in the constructor.

=back

=back

=head2 createQueue

 createQueue( request )

The C<CreateQueue> action creates a new queue, or returns the URL of an
existing one.  When you request C<CreateQueue>, you provide a name for
the queue. To successfully create a new queue, you must provide a name
that is unique within the scope of your own queues. If you provide the
name of an existing queue, a new queue isnE<039>t created and an error
isnE<039>t returned. Instead, the request succeeds and the queue URL for
the existing queue is returned.

I<Exception: if you provide a value for C<DefaultVisibilityTimeout> that is
different from the value for the existing queue, you receive an error.>

See
L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QueryCreateQueue.html>.

Returns an C<Amazon::SQS::Model::CreateQueueResponse> object.

Throws an C<Amazon::SQS::Exception>. Use eval to catch it.

=over 5

=item request

C<request> is either a hash reference of parameters for
a C<Amazon::SQS::Model::CreateQueueRequest> object or
a C<Amazon::SQS::Model::CreateQueueRequest> object itself.

See C<Amazon::SQS::Model::CreateQueueRequest> for valid arguments.

=back

=head2 listQueues

 listQueues( request )

The ListQueues action returns a list of your queues.

Returns an C<Amazon::SQS::Model::ListQueuesResponse> object.

Throws an C<Amazon::SQS::Exception>. Use eval to catch it

See L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QueryListQueues.html>

=over 5

=item request

Argument either hash reference of parameters for
C<Amazon::SQS::Model::ListQueuesRequest> request or
C<Amazon::SQS::Model::ListQueuesRequest> object itself.

See C<Amazon::SQS::Model::ListQueuesRequest> for valid arguments.

=back


=head2 addPermission

 addPermission( )

Adds the specified permission(s) to a queue for the specified
principal(s). This allows for sharing access to the queue.

See L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QueryAddPermission.html>

Returns an C<Amazon::SQS::Model::AddPermissionResponse>.

Throws C<Amazon::SQS::Exception. Use eval to catch> it.

=over 5

=item request

C<request> is either a hash reference of parameters for
C<Amazon::SQS::Model::AddPermissionRequest> request or
C<Amazon::SQS::Model::AddPermissionRequest> object itself.

See C<Amazon::SQS::Model::AddPermissionRequest for valid> arguments

=back

=head2 changeMessageVisibility

changeMessageVisibility( request )

The C<ChangeMessageVisibility> action extends the read lock timeout of
the specified message from the specified queue to the specified value.

Returns an C<Amazon::SQS::Model::ChangeMessageVisibilityResponse>

Throws an C<Amazon::SQS::Exception>. Use eval to catch it

See
L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QueryChangeMessageVisibility.html>

=over 5

=item request

<request> is either a hash reference of parameters for
C<Amazon::SQS::Model::ChangeMessageVisibilityRequest> request or
C<Amazon::SQS::Model::ChangeMessageVisibilityRequest> object itself.

See C<Amazon::SQS::Model::ChangeMessageVisibilityRequest> for valid arguments.

=back

=head2 deleteMessage

 deleteMessage( request ) 

The C<DeleteMessage> action unconditionally removes the specified message
from the specified queue. Even if the message is locked by another
reader due to the visibility timeout setting, it is still deleted from
the queue.

Returns an C<Amazon::SQS::Model::DeleteMessageResponse> object.

Throws an C<Amazon::SQS::Exception>. Use eval to catch it.

See L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QueryDeleteMessage.html>

=over 5

=item request

c<request> is either a hash reference of parameters for
C<Amazon::SQS::Model::DeleteMessageRequest> request or
C<Amazon::SQS::Model::DeleteMessageRequest> object itself.

See C<Amazon::SQS::Model::DeleteMessageRequest> for valid arguments

=back

=head2 deleteQueue

 deleteQueue( request )

This action unconditionally deletes the queue specified by the queue
URL. Use this operation WITH CARE!  The queue is deleted even if it is
NOT empty.

Returns an C<Amazon::SQS::Model::DeleteQueueResponse>

Throws an C<Amazon::SQS::Exception>. Use eval to catch it

See L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QueryDeleteQueue.html>

=over 5

=item request

C<request> can either be a hash reference of parameters for
C<Amazon::SQS::Model::DeleteQueueRequest> request or
C<Amazon::SQS::Model::DeleteQueueRequest> object itself.

See C<Amazon::SQS::Model::DeleteQueueRequest> for valid arguments.

=back

=head2 getQueueAttributes

 getQueueAttributes( request )

Gets one or all attributes of a queue. Queues currently have two
attributes you can get: <ApproximateNumberOfMessages> and
C<VisibilityTimeout>.

Returns an C<Amazon::SQS::Model::GetQueueAttributesResponse> object.

Throws an C<Amazon::SQS::Exception>. Use eval to catch it.

See
L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QueryGetQueueAttributes.html>

=over 5

=item request

C<request> can be either a hash reference of parameters for
C<Amazon::SQS::Model::GetQueueAttributesRequest> request or
C<Amazon::SQS::Model::GetQueueAttributesRequest> object itself.

See C<Amazon::SQS::Model::GetQueueAttributesRequest> for valid arguments.

=back


=head2 removePermissions

 removePermissions( request ) 

Removes the permission with the specified statement id from the queue.

See L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QueryRemovePermission.html>

Returns an C<Amazon::SQS::Model::RemovePermissionResponse> object.

Throws an C<Amazon::SQS::Exception>. Use eval to catch it.

=over 5

=item request

C<request> can be either a hash reference of parameters for
C<Amazon::SQS::Model::RemovePermissionRequest> request or
C<Amazon::SQS::Model::RemovePermissionRequest object> itself.

See C<Amazon::SQS::Model::RemovePermissionRequest> for valid arguments.

=back


=head2 receiveMessage

 receiveMessage( )

Retrieves one or more messages from the specified queue.  For each
message returned, the response includes the message body; MD5 digest
of the message body; receipt handle, which is the identifier you must
provide when deleting the message; and message ID of each message.

Messages returned by this action stay in the queue until you
delete them. However, once a message is returned to a C<ReceiveMessage>
request, it is not returned on subsequent C<ReceiveMessage> requests for
the duration of the C<VisibilityTimeout>. If you do not specify a
C<VisibilityTimeout> in the request, the overall visibility timeout for
the queue is used for the returned messages.

Returns an C<Amazon::SQS::Model::ReceiveMessageResponse> object.

Throws an C<Amazon::SQS::Exception>. Use eval to catch it.

See
L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QueryReceiveMessage.html>

=over 5

=item request

C<request> can be either a hash reference of parameters for
C<Amazon::SQS::Model::ReceiveMessageRequest> request or
C<Amazon::SQS::Model::ReceiveMessageRequest> object itself.

See C<Amazon::SQS::Model::ReceiveMessageRequest> for valid arguments.

=back


=head2 sendMessage

 sendMessage( )

The C<SendMessage> action delivers a message to the specified queue.

See
L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QuerySendMessage.html>

Returns an C<Amazon::SQS::Model::SendMessageResponse>

Throws an C<Amazon::SQS::Exception. Use eval to catch> it.

=over 5

=item request

C<request> can be either hash a reference of parameters for
C<Amazon::SQS::Model::SendMessageRequest> request or
C<Amazon::SQS::Model::SendMessageRequest> object itself.

See C<Amazon::SQS::Model::SendMessageRequest> for valid arguments.

=back


=head2 setQueueAttributes

 setQueueAttributes( )

Sets an attribute of a queue. Currently, you can set only the
C<VisibilityTimeout> attribute for a queue.

Returns an C<Amazon::SQS::Model::SetQueueAttributesResponse> object.

Throws an C<Amazon::SQS::Exception>. Use eval to catch it.

See
L</http://docs.amazonwebservices.com/AWSSimpleQueueService/2009-02-01/SQSDeveloperGuide/Query_QuerySetQueueAttributes.html>

=over 5

=item request

C<request> is hash reference of parameters for
C<Amazon::SQS::Model::SetQueueAttributesRequest> request or an
C<Amazon::SQS::Model::SetQueueAttributesRequest> object itself.

See C<Amazon::SQS::Model::SetQueueAttributesRequest> for valid
arguments.

=back

=head1 SEE OTHER

L<Amazon::SQS::Simple>, L<Amazon::API>, L<Paws>

=head1 AUTHOR

Elena@AWS

Rob Lauer - <bigfoot@cpan.org>

=cut

################################################################################
#  Copyright 2008 Amazon Technologies, Inc.
#  Licensed under the Apache License, Version 2.0 (the "License");
#
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at: http://aws.amazon.com/apache2.0
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#  CONDITIONS OF ANY KIND, either express or implied. See the License for the
#  specific language governing permissions and limitations under the License.
################################################################################
#    __  _    _  ___
#   (  )( \/\/ )/ __)
#   /__\ \    / \__ \
#  (_)(_) \/\/  (___/
#
#  Amazon SQS Perl Library
#  API Version: 2009-02-01
#  Generated: Thu Apr 09 01:13:11 PDT 2009
#

#
# SQS  Exception provides details of errors
# returned by SQS  service
#
package Amazon::SQS::Exception;

use strict;
use warnings;

#
# Constructs Amazon::SQS::Exception
# Accepts annonymous hash to construct the exception
#
# Keys are:
#
# Message - (string) text message for an exception
# StatusCode - (int) HTTP status code at the time of exception
# ErrorCode - (string) specific error code returned by the service
# ErrorType - (string) Possible types:  Sender, Receiver or Unknown
# RequestId - (string) request id returned by the service
# XML - (string) compete xml response at the time of exception
# Exception - (Exception) inner exception if any
#
#
#
sub new {
  my ( $class, $errorInfo ) = @_;

  my $self = {};

  if ( exists( $errorInfo->{Exception} ) ) {
    my $exception = $errorInfo->{Exception};

    if ( ref $exception eq "Amazon::SQS::Exception" ) {
      $self->{_message}    = $exception->getMessage();
      $self->{_statusCode} = $exception->getStatusCode();
      $self->{_errorCode}  = $exception->getErrorCode();
      $self->{_errorType}  = $exception->getErrorType();
      $self->{_requestId}  = $exception->getRequestId();
      $self->{_xml}        = $exception->getXML();
      $self->{_httpError}  = $exception->getHTTPError();
    }
  }
  else {
    $self->{_message}    = $errorInfo->{Message}    // q{};
    $self->{_statusCode} = $errorInfo->{StatusCode} // q{};
    $self->{_errorCode}  = $errorInfo->{ErrorCode}  // q{};
    $self->{_errorType}  = $errorInfo->{ErrorType}  // q{};
    $self->{_requestId}  = $errorInfo->{RequestId}  // q{};
    $self->{_xml}        = $errorInfo->{XML}        // q{};
    $self->{_httpError}  = $errorInfo->{HTTPError}  // q{};
  }

  return bless $self, $class;
}

#
# Gets error type returned by the service if available.
#
sub getErrorCode {
  return shift->{_errorCode};
}

#
# Gets error type returned by the service.
#
# Possible types:  Sender, Receiver or Unknown
#
sub getErrorType {
  return shift->{_errorType};
}

#
# Gets error message
#
sub getMessage {
  return shift->{_message};
}

#
# Gets status code returned by the service if available. If status
# code is set to -1, it means that status code was unavailable at the
# time exception was thrown
#
sub getStatusCode {
  return shift->{_statusCode};
}

#
# Gets XML returned by the service if available.
#
sub getXML {
  return shift->{_xml};
}

#
# Gets Request ID returned by the service if available.
#
sub getRequestId {
  return shift->{_requestId};
}

#
# Gets the HTTP error response
#
sub getHTTPError {
  return shift->{_httpError};
}

1;

__END__

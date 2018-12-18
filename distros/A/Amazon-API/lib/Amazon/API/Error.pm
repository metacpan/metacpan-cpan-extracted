package Amazon::API::Error;

use parent qw/Class::Accessor/;

use JSON qw/from_json/;
use Scalar::Util qw/reftype/;
use XML::Simple;

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw/error api message_raw response content_type/);

our $VERSION = '1.1.4-1'; $VERSION=~s/\-.*$//;

=pod

=head1 NAME

C<Amazon::API::Error>

=head1 SYNOPIS

 my $result = eval {
   from_json($cwe->PutPermission({ Action => "PutEvents", Principal => "123454657889012", StatementId => "12345"});
 };
 
 print Dumper([ $@->get_response, $@->get_error ])
   if $@ && ref($@) =~/API::Error/;

=head1 DESCRIPTION

Error object that contains that status code and the error message
contained in the body of the response to the API call.

=head1 METHODS

=head2 get_error

Returns the HTTP status code returned by the API call.

=head2 get_response

Returns a decode response. Usuall a hash.

=head2 get_message_raw

Returns the content of the body of the error response.

=head2 get_content_type

Returns the Content-Type of the response.

=head2 get_aws_api

Returns the API that was called that generated the error.

=head1 NOTES

An example response:

<?xml version="1.0" encoding="UTF-8"?>
  <Response><Errors><Error><Code>UnauthorizedOperation</Code><Message>You are not authorized to perform this operation.</Message></Error></Errors><RequestID>599b0f86-4668-4adb-b493-552d6039fcd1</RequestID></Response>

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  
  my $message = $self->get_message_raw;
  
  if ( $message ) {
   
    if ( $self->get_content_type =~/xml/ ) {
      $message = eval {
	XMLin($message);
      };
    }
    elsif ( $self->get_content_type =~/json/ ) {
	$message = eval {
	  from_json($message);
	};
      }
    else {
      # try a little harder...
      my $m = eval {
	from_json($message);
      };
      
      if ( $@ ) {
	$m = eval {
	  XMLin($message);
	};
      }
      else {
	$m = $message;
      }
      
      $message = $m;
    }
    
    $self->set_response($message);
  }
  
  $self;
}

sub get_aws_api {
  my $self = shift;
  my $api;
  
  {
    local $@;
    
    $api = eval {
      $self->get_api->get_api || ref($self->get_api);
    };
  }
  
  return $api;
}

1;

=pod

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=head1 SEE OTHER

C<Amazon::API>

=cut

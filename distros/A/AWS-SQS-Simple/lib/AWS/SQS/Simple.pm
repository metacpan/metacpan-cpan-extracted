package AWS::SQS::Simple;

use warnings                                       ;
use strict                                         ; 

use Carp                                           ;

use utf8                                           ;

use LWP::UserAgent                                 ;
use HTTP::Headers                                  ;

use URI::Escape                                    ;

use Encode qw( encode )                            ;

use Digest::SHA qw(hmac_sha256 hmac_sha256_base64) ;
use Digest::HMAC_SHA1                              ;

use MIME::Base64 qw(encode_base64)                 ;



=head1 NAME

AWS::SQS::Simple - This module is used to access amazon simple queue services.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module is used to access amazon simple queue services.


use AWS::SQS::Simple ;

my $ob = AWS::SQS::Simple->new(
             ACCESS_KEY        => '..'  , 
             SECRET_ACCESS_KEY => '..'  , 

             AWS_ACCOUNT_ID    => '..'  , 

             END_POINT         => '..'  , 

         );



my %params_hash = (

      QUEUE_NAME              => QUEUE Name        ,

      'AttributeName.1.Name'  => Attribute Name    , 
      'AttributeName.1.Value' => Attribute Value   , [ Required if there is a corresponding Name Attribute.n.name parameter ]

      'AttributeName.2.Name'  => Attribute Name    , 
      'AttributeName.2.Value' => Attribute Value   , [ Required if there is a corresponding Name Attribute.n.name parameter ]

    .....

     );

$ob->create_queue( \%params_hash    ) ;

my %params_hash = (

      QUEUE_NAME              => QUEUE Name        ,

      'MessageBody'           => Message to send   , 
      'DelaySeconds'          => The number of seconds to delay a specific message , [ OPTIONAL ]

     );

$ob->send_message( \%params_hash    ) ;


my %params_hash = (

      QUEUE_NAME            => QUEUE Name        ,

    'AttributeName.n'       => The attribute you want to get. Valid values: All | SenderId | SentTimestamp | ApproximateReceiveCount | ApproximateFirstReceiveTimestamp   ,  [ OPTIONAL ]
      'MaxNumberOfMessages' => Maximum number of messages to return. Default - 1 , [ OPTIONAL ]
      'VisibilityTimeout'   => The duration in seconds that the received messages are hidden from subsequent retrieve requests after being retrieved by a ReceiveMessage request. Default - The visibility timeout for the queue , [ OPTIONAL ]
      'WaitTimeSeconds'     => Long poll support (integer from 1 to 20 , [ OPTIONAL ]

     );

$ob->receive_message->( \%params_hash )


=head1 CONSTRUCTOR 

=head2 new

Constructs a new AWS::SQS::Simple object

Following are the parametes taken by the constructor

    my $ob = AWS::SQS::Simple->new(
                ACCESS_KEY        => '..'  , 
                SECRET_ACCESS_KEY => '..'  , 

                AWS_ACCOUNT_ID    => '..'  , 

                END_POINT         => '..'  , 

              );

=cut

sub new {
    
    my $class = shift;
    
    my %parameter_hash;

    my $count = @_;

    my $usage_howto = "

Usage:

    my \$ob = AWS::SQS::Simple->new(
                ACCESS_KEY        => '..'  , 
                SECRET_ACCESS_KEY => '..'  , 

                AWS_ACCOUNT_ID    => '..'  , 

                END_POINT         => '..'  , 

              );

";

    %parameter_hash = @_;

    croak $usage_howto							                unless( $parameter_hash{ AWS_ACCOUNT_ID    } ) ;

    croak $usage_howto						                        unless( $parameter_hash{ ACCESS_KEY        } ) ;
    croak $usage_howto									unless( $parameter_hash{ SECRET_ACCESS_KEY } ) ;

    croak $usage_howto									unless( $parameter_hash{ END_POINT         } ) ;

    my $self = {

	ACCESS_KEY        => $parameter_hash{ ACCESS_KEY        } ,
	SECRET_ACCESS_KEY => $parameter_hash{ SECRET_ACCESS_KEY } ,

	AWS_ACCOUNT_ID    => $parameter_hash{ AWS_ACCOUNT_ID    } ,

	END_POINT         => $parameter_hash{ END_POINT         } ,

    };

    ## Private and class data here. 

    bless( $self, $class );

    return $self;

}


=head1 FUNCTIONS

No functions are exported by default.

Following functions are all available through the AWS::SQS::Simple Object.

=head2 create_queue
	
This function creates a new queue.

Usage :

 my %params_hash = (

      QUEUE_NAME              => QUEUE Name        ,

      'AttributeName.1.Name'  => Attribute Name    , 
      'AttributeName.1.Value' => Attribute Value   , [ Required if there is a corresponding Name Attribute.n.name parameter ]

      'AttributeName.2.Name'  => Attribute Name    , 
      'AttributeName.2.Value' => Attribute Value   , [ Required if there is a corresponding Name Attribute.n.name parameter ]

    .....

     );

$ob->create_queue->( \%params_hash )


=cut

sub create_queue {

    my $self   = shift ;
    my $params = shift ;

    my $params_to_pass = {
        'Action'                => 'CreateQueue'              ,
	'QueueName'             => $params->{ QUEUE_NAME }    ,
        'AWSAccessKeyId'        => $self->{ ACCESS_KEY }      ,
        'Timestamp'             => _generate_timestamp()      ,
        'SignatureVersion'      => 2                          ,
        'Version'               => '2011-10-01'               ,
        'SignatureMethod'       => 'HmacSHA256'               ,

	%{ $params }
    };

    my $url      = $self->_get_url( $params_to_pass ) ;
    my $response = $self->_make_request( $url )       ;
    
    return $response                                  ;

}

=head2 send_message
	
This function sends a message to the queue.

Usage :

 my %params_hash = (

      QUEUE_NAME              => QUEUE Name        ,

      'MessageBody'           => Message to send   , 
      'DelaySeconds'          => The number of seconds to delay a specific message , [ OPTIONAL ]

     );

$ob->send_message->( \%params_hash )


=cut

sub send_message {

    my $self   = shift ;
    my $params = shift ;

    my $message_body = $params->{ MessageBody } ;

    unless( defined $message_body ){
	print STDERR  "Error : Message Body not defined" ;
	return 0                                 ;
    }

    my $params_to_pass = {
        'Action'                => 'SendMessage'              ,
        'AWSAccessKeyId'        => $self->{ ACCESS_KEY }      ,
        'Timestamp'             => _generate_timestamp()      ,
        'SignatureVersion'      => 2                          ,
        'Version'               => '2009-02-01'               ,
        'SignatureMethod'       => 'HmacSHA256'               ,

	%{ $params }
    };


    my $url      = $self->_get_url( $params_to_pass ) ;

    my $response = $self->_make_request( $url )       ;
    
    return $response                                  ;
}


=head2 receive_message
	
This function returns mesaages already in the queue specified.

Usage :

 my %params_hash = (

      QUEUE_NAME            => QUEUE Name        ,

    'AttributeName.n'       => The attribute you want to get. Valid values: All | SenderId | SentTimestamp | ApproximateReceiveCount | ApproximateFirstReceiveTimestamp   ,  [ OPTIONAL ]
      'MaxNumberOfMessages' => Maximum number of messages to return. Default - 1 , [ OPTIONAL ]
      'VisibilityTimeout'   => The duration in seconds that the received messages are hidden from subsequent retrieve requests after being retrieved by a ReceiveMessage request. Default - The visibility timeout for the queue , [ OPTIONAL ]
      'WaitTimeSeconds'     => Long poll support (integer from 1 to 20 , [ OPTIONAL ]

     );

$ob->receive_message->( \%params_hash )

=cut

sub receive_message {

    my $self   = shift ;
    my $params = shift ;

    my $params_to_pass = {
        'Action'                => 'ReceiveMessage'           ,
        'AWSAccessKeyId'        => $self->{ ACCESS_KEY }      ,
        'Timestamp'             => _generate_timestamp()      ,
        'SignatureVersion'      => 2                          ,
        'Version'               => '2009-02-01'               ,
        'SignatureMethod'       => 'HmacSHA256'               ,

	%{ $params }
    };
    
    my $url      = $self->_get_url( $params_to_pass ) ;
    my $response = $self->_make_request( $url )       ;
    
    return $response                                  ;
}

=head2 delete_message
	
This function deletes a message from the queue.

Usage :

 my %params_hash = (

      QUEUE_NAME            => QUEUE Name        ,

     'ReceiptHandle'       => The receipt handle associated with the message you want to delete ,
     );

$ob->delete_message->( \%params_hash )


=cut

sub delete_message {

    my $self   = shift ;
    my $params = shift ;

    my $receipt_handle = $params->{ ReceiptHandle } ;

    unless( defined $receipt_handle ){
	print STDERR  "Error : Receipt Handle not defined" ;
	return 0                                           ;
    }

    my $params_to_pass = {
        'Action'                => 'DeleteMessage'            ,
        'AWSAccessKeyId'        => $self->{ ACCESS_KEY }      ,
        'Timestamp'             => _generate_timestamp()      ,
        'SignatureVersion'      => 2                          ,
        'Version'               => '2009-02-01'               ,
        'SignatureMethod'       => 'HmacSHA256'               ,

	%{ $params }
    };

    my $url      = $self->_get_url( $params_to_pass ) ;
    my $response = $self->_make_request( $url )       ;
    
    return $response                                  ;
}

=head2 get_queue_attributes
	
This function returns queue attributes.

Usage :

 my %params_hash = (

      QUEUE_NAME            => QUEUE Name                    ,

     'AttributeName.n'      => The attribute you want to get ,
     );

$ob->get_queue_attributes->( \%params_hash )


=cut

sub get_queue_attributes {

    my $self   = shift ;
    my $params = shift ;

    my $params_to_pass = {
        'Action'                => 'GetQueueAttributes'       ,
        'AWSAccessKeyId'        => $self->{ ACCESS_KEY }      ,
        'Timestamp'             => _generate_timestamp()      ,
        'SignatureVersion'      => 2                          ,
        'Version'               => '2012-11-05'               ,
        'SignatureMethod'       => 'HmacSHA256'               ,

	%{ $params }
    };


    my $url      = $self->_get_url( $params_to_pass ) ;
    my $response = $self->_make_request( $url )       ;
    
    return $response                                  ;
}


=head1 INTERNAL SUBROUTINES/METHODS

Following methods are used only by the modules.

=head2 _get_url
	
This function creates and returns url as per the parameters passed.

=cut

sub _get_url {
    
    my $self        = shift ;
    my $params      = shift ;

    my $url_additional_str = $self->{ AWS_ACCOUNT_ID } . '/' . delete( $params->{ QUEUE_NAME } ) ;

    my $sign_query = _get_signed_query( $params ) ;
    
    my $to_escape = qr{^(?:Signature|MessageBody|ReceiptHandle)|\.\d+\.(?:MessageBody|ReceiptHandle)$} ;
    foreach my $key( keys %$params ) {

        next unless $key =~ m/$to_escape/    ;
        next unless exists $params->{ $key } ;

        my $octets        = encode( 'utf-8-strict', $params->{ $key } ) ;
        $params->{ $key } = escape( $octets )                           ;

    }

    my $uri_str   = join('&', map { $_ . '=' . $params->{$_} } keys %$params )             ;

    my $sign_str  = "GET\n".$self->{ END_POINT }."\n/"                                     ; 
       $sign_str .= $url_additional_str . "/" if( $params->{ Action } ne "CreateQueue"  )  ;
       $sign_str .= "\n" . $sign_query                                                     ;


    my $signature = $self->_generate_signatue( $sign_str ) ;
    
    $uri_str .= '&Signature=' . escape( $signature )       ;

    my $url   =  "http://".$self->{ END_POINT }                                               ;
       $url  .=  '/' . $url_additional_str . '/' if( $params->{ Action } ne "CreateQueue"  )  ;
       $url  .=  '?' . $uri_str                                                               ;

    return $url ;

}

=head2 _generate_signatue
	
This function generate signature using HMACSHA256 method and version 2.

=cut

sub _generate_signatue {

    my $self   = shift ;
    my $query  = shift ;
    
    my $secret_access_key = $self->{ SECRET_ACCESS_KEY } ;

    my $digest = encode_base64( hmac_sha256($query, $secret_access_key ),'' ) ;

    return $digest ;
}

=head2 _get_signed_query
	
This function utf8 encodes and uri escapes the parameters passed to generate the signed string.

=cut

sub _get_signed_query {

    my $params = shift ;

    my $to_sign ;
    for my $key( sort keys %$params ) {

        $to_sign .= '&' if $to_sign ;

        my $key_octets   = encode('utf-8-strict', $key              ) ;
        my $value_octets = encode('utf-8-strict', $params->{ $key } ) ;

        $to_sign .= escape( $key_octets ) . '=' . escape( $value_octets ) ;

    }
    
    return $to_sign ;
}


=head2 escape 

    URI escape only the characters that should be escaped, according to RFC 3986

=cut

sub escape {

    my ($str) = @_;

    return uri_escape_utf8( $str,'^A-Za-z0-9\-_.~' ) ;
}

=head2 _generate_timestamp 

 Calculate current TimeStamp 

=cut 

sub _generate_timestamp {

    return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.000Z",
                   sub { ($_[5]+1900,
                          $_[4]+1,
                          $_[3],
                          $_[2],
                          $_[1],
                          $_[0])
                   }->(gmtime(time)));
}

=head2 _make_request 

=cut

sub _make_request {

    my $self          = shift ;
    my $url_to_access = shift ;

    my $contents                             ;
    my $attempts = 0                         ;
    my $got_data = 0                         ;
    
    my $this_profile_location                ;
    
    my $response;
    
    until( $got_data or $attempts > 5 ) { 
	
	my $request = HTTP::Request->new(
	    GET => $url_to_access
	    );
	
	my $ua = LWP::UserAgent->new             ;
	$ua->timeout(60)                         ;
	$ua->env_proxy                           ;
	$ua->agent( 'AWIS-INFO_GET/'.$VERSION ) ;
	
	$response = $ua->request( $request )  ;

	if( $response->is_success() ) {
	    
	    $contents = $response->content;
	    $got_data = 1;
	    
	} else  {

	    $contents = $response->content          ;
	    
	    print STDERR "ERROR : $contents"        ;  

	    $attempts++             ;
	    sleep( $attempts * 10 ) ;
	    
	}
	
	$contents = $response->content          ;
	
	$attempts++                             ;
	
    }
    

    my $response_content = $response->content     ;

    return $response_content                      ;

}


=head1 AUTHOR

Ankita, C<< <sankita.11 at gmail.com> >>


=head1 COPYRIGHT & LICENSE

Copyright 2014 Ankita Singhal, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of AWS::SQS::Simple


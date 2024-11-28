use strict;
use warnings;

package Amazon::SQS::QueueHandler;

use Data::Dumper;
use English qw(-no_match_vars);

use Amazon::Credentials;
use Amazon::SQS::Model::DeleteMessageRequest;
use Amazon::SQS::Model::ReceiveMessageRequest;
use Amazon::SQS::Client;
use CGI::Simple;
use JSON;
use List::Util qw(none max);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    config
    create_queue
    credentials
    endpoint_url
    logger
    max_error_retry
    message
    message_id
    message_type
    message_body
    raw_message
    receipt_handle
    request
    region
    service
    signature_version
    queue_list
    name
    max_messages
    url
    visibility_timeout
    wait_time
  )
);

use parent qw(Class::Accessor::Fast);

our @VALID_MESSAGE_TYPES = qw(
  text/plain
  application/json
  application/x-www-form-urlencoded
);

our $DEFAULT_ENDPOINT_URL = 'https://queue.amazonaws.com';
our $MAX_MESSAGES         = 1;

our $TRUE  = 1;
our $FALSE = 0;

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  $options->{credentials} //= Amazon::Credentials->new;
  my $self = $class->SUPER::new($options);

  $self->init_defaults();

  $self->create_service();

  if ( $self->get_name && !$self->get_url ) {
    my %queue_list = reverse $self->list_queues();

    if ( $self->get_create_queue ) {
      $self->create_queue( $self->get_name );
    }
    else {
      my $queue_url = $queue_list{ $self->get_name };

      die sprintf "no such queue [%s]\n", $self->get_name
        if !$queue_url;

      $self->set_url($queue_url);
    }
  }

  die "no queue url set\n"
    if !$self->get_url;

  $self->create_request;

  return $self;
}

########################################################################
sub init_defaults {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  # init options from config...
  if ($config) {
    foreach (
      qw(
      handler_message_type
      aws_endpoint_url
      queue_max_error_retry
      queue_max_messages
      queue_url
      queue_name
      queue_create_queue
      queue_visibility_timeout
      queue_wait_time
      )
    ) {
      my $getter = "get_$_";

      if ( $config->can($getter) ) {

        my @local_name = split /_/xsm, $_;
        shift @local_name;

        my $var = join q{_}, @local_name;

        next
          if defined $self->get($var);

        $self->set( $var, $config->$getter() );
      }
    }
  }

  my $message_type = $self->get_message_type // 'text/plain';

  die "invalid message type\n"
    if none { $message_type eq $_ } @VALID_MESSAGE_TYPES;

  $self->set_message_type($message_type);

  my $endpoint_url //= $self->get_endpoint_url;
  $endpoint_url //= $ENV{AWS_ENDPOINT_URL} // $DEFAULT_ENDPOINT_URL;

  $self->set_endpoint_url($endpoint_url);

  my $max_messages = $self->get_max_messages() || 1;

  $self->set_max_messages( max( $MAX_MESSAGES, $max_messages ) );

  return;
}

########################################################################
sub create_queue {
########################################################################
  my ( $self, $queue_name ) = @_;

  my $queue_list = $self->get_queue_list // {};

  my $queue_url = eval {
    return $queue_list->{$queue_name}
      if $queue_list->{$queue_name};

    my $service = $self->get_service;

    my $rsp = $service->createQueue( { QueueName => $queue_name } );

    my $result = $rsp->getCreateQueueResult();

    return $result->getQueueUrl;
  };

  die "could not create queue $queue_name\n$EVAL_ERROR"
    if !$queue_url || $EVAL_ERROR;

  $self->set_url($queue_url);

  return $queue_url;
}

########################################################################
sub list_queues {
########################################################################
  my ($self) = @_;

  my $service = $self->get_service();

  my $rsp = $service->listQueues();

  my $result = $rsp->getListQueuesResult();

  my $queueUrls = $result->getQueueUrl();

  my %queue_list;

  foreach ( @{$queueUrls} ) {
    if (/\/([^\/]+)$/xsm) {
      $queue_list{$_} = $1;
    }
  }

  $self->set_queue_list( \%queue_list );

  return %queue_list;
}

########################################################################
sub create_service {
########################################################################
  my ($self) = @_;

  my %options = (
    ServiceURL    => $self->get_endpoint_url,
    MaxErrorRetry => $self->get_max_error_retry,
    credentials   => $self->get_credentials,
  );

  my $service = eval { return Amazon::SQS::Client->new( undef, undef, \%options ); };

  die "could not create service\n$EVAL_ERROR"
    if !$service || $EVAL_ERROR;

  $self->set_service($service);

  return $service;
}

########################################################################
sub decode_message {
########################################################################
  my ( $self, $message_type, $message_body ) = @_;

  $message_type //= $self->get_message_type;
  $message_body //= $self->get_message_body;

  $self->get_logger->trace(
    Dumper(
      [ type => $message_type,
        body => $message_body,
      ]
    )
  );

  my $decoded_message = eval {
    return $message_body
      if $message_type eq 'text/plain';

    return JSON->new->decode($message_body)
      if $message_type eq 'application/json';

    if ( $message_type eq 'application/x-www-form-encoded' ) {
      my %vars = CGI::Simple->new($message_body)->Vars();

      # create array refs from multi-value params
      foreach ( keys %vars ) {
        next if $vars{$_} !~ /\0/;
        $vars{$_} = [ split /\0/xsm, $vars{$_} ];
      }

      return \%vars;
    }
  };

  die "unable to decode message\n$EVAL_ERROR"
    if !defined $decoded_message || $EVAL_ERROR;

  $self->set_message($decoded_message);

  return $decoded_message;
}

########################################################################
sub handler {
########################################################################
  my ( $self, $message ) = @_;

  $self->get_logger->info( Dumper( [ message => $message ] ) );

  return $TRUE;
}

########################################################################
sub get_next_message {
########################################################################
  my ($self) = @_;

  $self->set_message(undef);

  my $service = $self->get_service;
  my $request = $self->get_request;

  my $response = $service->receiveMessage($request);

  return
    if !$response || !$response->isSetReceiveMessageResult();

  my $receiveMessageResult = $response->getReceiveMessageResult();

  my $messageList = $receiveMessageResult->getMessage();

  my ($message) = @{ $messageList // [] };

  return
    if !ref $message || !$message->isSetMessageId();

  $self->set_raw_message($message);

  $self->set_receipt_handle( $message->getReceiptHandle );

  $self->set_message_body( $message->getBody() );

  $self->set_message_id( $message->getMessageId() );

  my $decoded_message = $self->decode_message();

  $self->set_message($decoded_message);

  return $decoded_message;
}

########################################################################
sub create_request {
########################################################################
  my ($self) = @_;

  return $self->get_request
    if $self->get_request;

  my $max_messages       = max( 1, $self->get_max_messages );  # max of 1 currently
  my $wait_time          = $self->get_wait_time // 0;
  my $visibility_timeout = $self->get_visibility_timeout;

  my $request = Amazon::SQS::Model::ReceiveMessageRequest->new(
    { QueueUrl            => $self->get_url,
      MaxNumberOfMessages => $max_messages,
      VisibilityTimeout   => $visibility_timeout,
      WaitTimeSeconds     => $wait_time,
    }
  );

  $self->set_request($request);

  return;
}

########################################################################
sub change_message_visibility {
########################################################################
  my ( $self, $timeout ) = @_;

  my $service = $self->get_service;

  $service->changeMessageVisibility(
    QueueUrl          => $self->get_url,
    ReceiptHandle     => $self->get_receipt_handle,
    VisibilityTimeout => $timeout,
  );

  return;
}

########################################################################
sub delete_message {
########################################################################
  my ( $self, $handle ) = @_;

  $handle //= $self->get_receipt_handle;

  my $logger = $self->get_logger;

  my $rsp = eval {
    $self->get_service->deleteMessage(
      Amazon::SQS::Model::DeleteMessageRequest->new(
        { QueueUrl      => $self->get_url,
          ReceiptHandle => $handle
        }
      )
    );
  };

  my $err = $EVAL_ERROR;

  return
    if $rsp && !$EVAL_ERROR;

  die $err
    if !ref $err || ref $err ne 'Amazon::SQS::Exception';

  my $err_message = <<'END_OF_ERROR';
Exception: %s
Response Status Code: %s
Error Code: %s
Error Type: %s
Request ID: %s
END_OF_ERROR

  die sprintf $err_message,
    $err->getMessage,
    $err->getStatusCode,
    $err->getErrorCode,
    $err->getErrorType,
    $err->getRequestId;

  return;
}

1;

__END__

=pod

=head1 NAME

Amazon::SQS::QueueHandler - base class for creating SQS message queue handlers

=head1 SYNOPSIS

 package MyHandler;

 use parent qw(Amazon::SQS::QueueHandler);

 sub handler {
   my ($self, $message) = @_;
  
   return 1; # delete the message
 }

 1;

=head1 DESCRIPTION

Base class for creating queue handlers that work with the
F<QueueDaemon.pl> script.  You provide a handler class that processes
SQS messages. The F<QueueDaemon.pl> script handles the plumbing.

=head1 METHODS AND SUBROUTINES

=head2 handler

 handler(message)

You provide your own handler message that receives a message to
process. The message is the decoded body of the message placed on the
SQS queue by some other process. Messages can be sent as plain text,
JSON strings or x-www-form-encoded strings.

Generally speaking, by default your handler should return a true value
if you want the message deleted and a non-zero value if you want the
message to be returned to the queue. There are various options
available with the F<QueueDaemon.pl> script that control this behavior
however.

=head2 change_message_visibility

 change_message_visibility(timeout)

Changes the message visibility timeout. You may find that in some
circumstances you would like to either extend the time the message
remains invisible or you want to shorten the time it becomes
available.  Use this method when your handler receives the message to
alter the visibility of the message to other workers.

=head1 NOTES

As a subclass of L<Amazon::SQS::QueueHandler>, your class has access to
the methods of its parent. Most notably you might want to use the
logger which is an instance of a L<Log::Log4perl> logger.

 sub handler {
   my ($self, $message) = @_;

   $self->get_logger->info('...got a message!');
   ...
 }

The logging level was set either in your configuration file or on the
command line when you invoked the F<QueueDaemon.pl> script.

=head1 SEE ALSO

L<Amazon::SQS::Config>

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut

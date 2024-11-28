#!/usr/bin/env perl

# script to create a queue w/an associated dead letter queue
# perl create-queue.pl -h

use strict;
use warnings;

use Amazon::SQS::Client;

use Data::Dumper;
use English qw(-no_match_vars);

use Getopt::Long qw(:config no_ignore_case);
use JSON;
use Pod::Usage;

use Readonly;

Readonly::Scalar our $DEFAULT_MAX_RECEIVE_COUNT                 => 10;
Readonly::Scalar our $DEFAULT_MAXIMUM_MESSAGE_SIZE              => 256 * 1024;
Readonly::Scalar our $DEFAULT_VISIBILITY_TIMEOUT                => 30;
Readonly::Scalar our $DEFAULT_MESSAGE_RETENTION_PERIOD          => 4 * 24 * 60 * 60;
Readonly::Scalar our $DEFAULT_DELAY_SECONDS                     => 0;
Readonly::Scalar our $DEFAULT_RECEIVE_MESSAGE_WAIT_TIME_SECONDS => 0;
Readonly::Scalar our $DEFAULT_ENDPOINT_URL                      => 'https://queue.amazonaws.com';

########################################################################
sub list_queues {
########################################################################
  my ($client) = @_;

  my $queues = $client->listQueues()->getListQueuesResult->getQueueUrl;

  return $queues;
}

########################################################################
sub get_queue_names {
########################################################################
  my ( $client, $options ) = @_;

  my $queue_list = list_queues($client);

  return map { /([^\/]+)$/xsm ? ( "$1" => $_ ) : () } @{$queue_list};
}

########################################################################
sub get_queue_url {
########################################################################
  my ( $client, $options ) = @_;

  my %queue_names = get_queue_names( $client, $options );

  return $queue_names{ $options->{queue} };
}

########################################################################
sub get_queue_attributes {
########################################################################
  my ( $client, $queue_url ) = @_;

  my $rslt = $client->getQueueAttributes(
    { QueueUrl      => $queue_url,
      AttributeName => ['All'],
    }
  );

  my $attributesResult = $rslt->getGetQueueAttributesResult;

  return $attributesResult->getAttribute;
}

########################################################################
sub get_queue_arn {
########################################################################
  my ( $client, $queue_url ) = @_;

  my $attributes = get_queue_attributes( $client, $queue_url );

  my ($arn) = grep {/arn/xsmi} map { $_->getValue } @{$attributes};

  die "could not find queue ($queue_url) arn\n"
    if !$arn;

  return $arn;
}

########################################################################
sub create_dlq {
########################################################################
  my ( $client, $options ) = @_;

  my $name = $options->{queue};

  my $dlq = $name . 'DLQ';

  my $redriveAllowPolicy = { redrivePermission => 'allowAll' };

  my @attributes = (
    { Name  => 'RedriveAllowPolicy',
      Value => JSON->new->encode($redriveAllowPolicy)
    },
    { Name  => 'VisibilityTimeout',
      Value => $options->{'visibility-timeout'},
    },
  );

  local $options->{queue} = $dlq;

  return create_queue( $client, $options, @attributes );
}

########################################################################
sub create_test_queue {
########################################################################
  my ( $client, %options ) = @_;

  my $dlq_url = $options{dlq_url};

  if ($dlq_url) {

    $options{'redrive-policy'} = JSON->new->encode(
      { deadLetterTargetArn => get_queue_arn( $client, $dlq_url ),
        maxReceiveCount     => $options{'max-receive-count'},
      }
    );
  }

  my @attribute_names = qw(
    delay-seconds
    maximum-message-size
    message-retention-period
    redrive-policy
    visibility-timeout
    receive-message-wait-time-seconds
  );

  my @attributes = map { { Name => toCamelCase($_), Value => $options{$_} } } @attribute_names;

  return create_queue( $client, \%options, @attributes );
}

########################################################################
sub toCamelCase {
########################################################################
  my ($var) = @_;

  return join q{}, map { ucfirst $_ } split /[\-]/xsm, $var;
}

########################################################################
sub create_test_queues {
########################################################################
  my ( $client, $options ) = @_;

  my $dlq_url;

  if ( $options->{dlq} ) {
    $dlq_url = create_dlq( $client, $options );
  }

  my $url = create_test_queue( $client, dlq_url => $dlq_url, %{$options} );

  return [ $url, $dlq_url ];
}

########################################################################
sub create_queue {
########################################################################
  my ( $client, $options, @attributes ) = @_;

  my $rslt = $client->createQueue(
    { QueueName => $options->{queue},
      @attributes ? ( Attribute => \@attributes ) : (),
    }
  );

  return $rslt->getCreateQueueResult->getQueueUrl;
}

########################################################################
sub delete_test_queues {
########################################################################
  my ( $client, $options ) = @_;

  my $name = $options->{queue};
  my $dlq  = $name . 'DLQ';

  my %queue_names = get_queue_names( $client, $options );

  foreach my $queue ( $name, $dlq ) {
    next
      if !$queue_names{$queue};

    $client->deleteQueue( { QueueUrl => $queue_names{$queue} } );
  }

  return 0;
}

########################################################################
sub command_send_message {
########################################################################
  my ( $client, $options ) = @_;

  die "--queue is a required argument\n"
    if !$options->{queue};

  my $message = shift @ARGV;
  $message //= 'Hello World!';

  my $queue_url = get_queue_url( $client, $options );

  my $response = $client->sendMessage(
    { MessageBody => $message,
      QueueUrl    => $queue_url
    }
  );

  print {*STDOUT} JSON->new->pretty->encode( { MessageId => $response->getSendMessageResult->getMessageId() } );

  return 0;
}

########################################################################
sub command_receive_message {
########################################################################
  my ( $client, $options ) = @_;

  die "--queue is a required argument\n"
    if !$options->{queue};

  my $queue_url    = get_queue_url( $client, $options );
  my $max_messages = shift @ARGV;

  my $response = $client->receiveMessage(
    { QueueUrl           => $queue_url,
      MaxNumberOfMessage => $max_messages // 1,
    }
  );

  my $result = $response->getReceiveMessageResult();

  my @messages = @{ $result->getMessage };

  my @message_list;

  foreach (@messages) {
    push @message_list,
      {
      ReceiptHandle => $_->getReceiptHandle,
      MessageBody   => $_->getBody
      };
  }

  print {*STDOUT} JSON->new->pretty->encode( \@message_list );

  return 0;
}

########################################################################
sub command_create {
########################################################################
  my ( $client, $options ) = @_;

  die "--queue is a required argument\n"
    if !$options->{queue};

  delete_test_queues( $client, $options );

  eval { create_test_queues( $client, $options ); };

  if ($EVAL_ERROR) {
    print {*STDERR} Dumper( [ error => $EVAL_ERROR ] );
  }

  return command_list( $client, $options );
}

########################################################################
sub command_delete {
########################################################################
  my ( $client, $options ) = @_;

  die "--queue is a required argument\n"
    if !$options->{queue};

  delete_test_queues( $client, $options );

  return command_list( $client, $options );

  return 0;
}

########################################################################
sub command_delete_message {
########################################################################
  my ( $client, $options ) = @_;

  die "--queue is a required argument\n"
    if !$options->{queue};

  my $queue_url = get_queue_url( $client, $options );

  my $receipt_handle = shift @ARGV;

  die "no receipt handle\n"
    if !$receipt_handle;

  $client->deleteMessage(
    { QueueUrl      => $queue_url,
      ReceiptHandle => $receipt_handle,
    }
  );

  return 0;
}

########################################################################
sub command_list {
########################################################################
  my ( $client, $options ) = @_;

  my $queues = list_queues( $client, $options );

  print {*STDOUT} JSON->new->pretty->encode($queues);

  return 0;
}

########################################################################
sub command_attributes {
########################################################################
  my ( $client, $options ) = @_;

  die "--queue is a required argument\n"
    if !$options->{queue};

  my $queue_url  = get_queue_url( $client, $options );
  my $attributes = get_queue_attributes( $client, $queue_url );

  print {*STDOUT} JSON->new->pretty->encode( { map { $_->getName, $_->getValue } @{$attributes} } );

  return 0;
}

########################################################################
sub init_client {
########################################################################
  my ($options) = @_;

  my $client_options = {
    ServiceURL => $options->{'endpoint-url'},
    $options->{debug} ? ( loglevel => 'debug' ) : ( loglevel => 'info' ),
  };

  my @credentials = ( $ENV{AWS_ACCESS_KEY_ID}, $ENV{AWS_SECRET_ACCESS_KEY} );

  return Amazon::SQS::Client->new( @credentials, $client_options );
}

########################################################################
sub main {
########################################################################
  my @option_specs = qw(
    debug|d
    dlq!
    delay-seconds|D=i
    endpoint-url|e=s
    help|h
    max-receive-count|c=i
    maximum-message-size|S=i
    message-retention-period|p=i
    queue|q=s
    receive-message-wait-time-seconds|w=i
    visibility-timeout|v=i
  );

  my %options = (
    dlq                                 => 1,
    'delay-seconds'                     => $DEFAULT_DELAY_SECONDS,
    'endpoint-url'                      => $DEFAULT_ENDPOINT_URL,
    'max-receive-count'                 => $DEFAULT_MAX_RECEIVE_COUNT,
    'endpoint-url'                      => $DEFAULT_ENDPOINT_URL,
    'maximum-message-size'              => $DEFAULT_MAXIMUM_MESSAGE_SIZE,
    'message-retention-period'          => $DEFAULT_MESSAGE_RETENTION_PERIOD,
    'receive-message-wait-time-seconds' => $DEFAULT_RECEIVE_MESSAGE_WAIT_TIME_SECONDS,
  );

  my %dispatch = (
    attributes        => \&command_attributes,
    create            => \&command_create,
    'send-message'    => \&command_send_message,
    'receive-message' => \&command_receive_message,
    delete            => \&command_delete,
    'delete-message'  => \&command_delete_message,
    list              => \&command_list,
  );

  my $retval = GetOptions( \%options, @option_specs );

  if ( !$retval || $options{help} ) {
    pod2usage(1);
  }

  my $client = init_client( \%options );

  my $command = shift @ARGV;
  $command //= q{};

  if ( !$command || !$dispatch{$command} ) {
    warn "invalid command [$command]\n"
      if $command;

    pod2usage(1);
  }

  return $dispatch{$command}->( $client, \%options );
}

exit main();

1;

## no critic

__END__

=pod

=head1 USAGE

 create-queue.pl options command

Use this script to perform various SQS API commands. You can use this
script to create queues, list queues, send and receive messages and more.

By default if you use the C<create>, the script will create
two queues; a primary queue and an associated dead letter queue. The
dead letter queue will be created with the name as the primary queue
with a 'DLQ' suffix.

Pass the C<--no-dlq> option if you don't want a dead letter queue.

=head2 Command

=over 5

=item list - list queues

=item create - create the primary and dead letter queue

You can control the attributes of the new queue by setting the various
queue options (e.g. C<--visibility-timeout>, etc)

Use the C<--no-dlq> to prevent the dead letter queue from being created.

=item delete - delete the primary and dead letter queue (if it exists)

=item attributes - display the queue attributes

=item send-message - send a message

 send-message message

=item receive-message - receive one or more messages

 receive-message n

=item delete-message - delete a message

 delete-message receipt-handle

=back

=head1 OPTIONS

 --help, -h

 --queue, -q 

 Queue name. The dead letter queue will be the same name with a DLQ suffix

 --endpoint-url, -e  

 Endpoint URL Default: https://queue.amazonaws.com

 --delay-seconds, -D

 Length of time, in seconds, for which the delivery of all messages in
 the queue is delayed. Valid values: An integer from 0 to 900 seconds
 (15 minutes). Default: 0.

 --maximum-message-size, -M 

 The limit of how many bytes a message can contain before Amazon SQS
 rejects it. Valid values: An integer from 1,024 bytes (1 KiB) to
 262,144 bytes (256 KiB). Default: 262,144 (256 KiB).

 --max-receive-count, -c

 The number of times a message is delivered to the source queue before
 being moved to the dead-letter queue. Default: 10. When the
 ReceiveCount for a message exceeds the maxReceiveCount for a queue,
 Amazon SQS moves the message to the dead-letter-queue.

 --message-retention-period, -p

 The length of time, in seconds, for which Amazon SQS retains a
 message.  Valid values: An integer from 60 seconds (1 minute) to
 1,209,600 seconds (14 days). Default: 345,600 (4 days). When you
 change a queue's attributes, the change can take up to 60 seconds for
 most of the attributes to propagate throughout the Amazon SQS
 system. Changes made to the MessageRetentionPeriod attribute can take
 up to 15 minutes and will impact existing messages in the queue
 potentially causing them to be expired and deleted if the
 MessageRetentionPeriod is reduced below the age of existing messages.

 --receive-message-wait-time_seconds, -w

 The length of time, in seconds, for which a ReceiveMessage action
 waits for a message to arrive. Valid values: An integer from 0 to 20
 (seconds). Default: 0.

 --visibility-timeout, -v

 The visibility timeout for the queue, in seconds. Valid values: An
 integer from 0 to 43,200 (12 hours). Default: 30. For more
 information about the visibility timeout, see Visibility Timeout in
 the Amazon SQS Developer Guide.

=head2 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut

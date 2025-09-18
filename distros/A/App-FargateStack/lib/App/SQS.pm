package App::SQS;

# A simple SQS utility class that can check for the existence of a queue and create one if needed

use strict;
use warnings;

use App::FargateStack::Constants;
use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(pairs);
use JSON;

use Role::Tiny::With;

with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->mk_accessors(
  qw(
    name
    region
    profile
    visibility_timeout
    message_retention_period
    receive_message_wait_time_seconds
    max_receive_count
    delay_seconds
    arn
    url
  )
);

########################################################################
sub set_attributes {
########################################################################
  my ( $self, $queue_url, $attributes ) = @_;

  if ( ref $attributes ) {
    my %queue_attributes = %{$attributes};

    if ( $queue_attributes{RedrivePolicy} ) {
      $queue_attributes{RedrivePolicy} = encode_json( $queue_attributes{RedrivePolicy} );
    }

    $attributes = encode_json( \%queue_attributes );
  }

  return $self->command(
    'set-queue-attributes',
    [ '--queue-url'  => $queue_url,
      '--attributes' => $attributes,
    ]
  );
}

########################################################################
sub get_queue_arn {
########################################################################
  my ( $self, $queue_url ) = @_;

  my $arn = $self->get_queue_attributes(
    queue_url       => $queue_url,
    attribute_names => ['QueueArn'],
    query           => 'Attributes.QueueArn'
  );

  croak sprintf "ERROR: could not get queue attributes for queue: [%s]\n%s", $queue_url, $self->get_get_error
    if !$arn;

  return $arn;
}

########################################################################
sub get_queue_attributes {
########################################################################
  my ( $self, %args ) = @_;

  my ( $queue_url, $attribute_names, $query ) = @args{qw(queue_url attribute_names query)};

  $queue_url //= $self->get_queue_url;

  my $attributes = join q{ }, @{ $attribute_names || [] };
  $attributes //= 'All';

  return $self->command(
    'get-queue-attributes' => [
      '--queue-url'       => $queue_url,
      '--attribute-names' => $attributes,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub queue_exists { goto &get_queue_url; }
########################################################################

########################################################################
sub get_queue_url {
########################################################################
  my ( $self, $queue_name ) = @_;

  $queue_name //= $self->get_name;

  my $queue_url = $self->command(
    'get-queue-url' => [
      '--queue-name' => $queue_name,
      '--query'      => 'QueueUrl',
      '--output'     => 'text',
    ]
  );

  chomp $queue_url;

  return $queue_url;
}

########################################################################
sub create_queue {
########################################################################
  my ( $self, $attributes ) = @_;

  $self->get_logger->trace( sub { return Dumper( [ attributes => $attributes ] ) } );

  my $queue_name = $self->get_name;
  $queue_name //= $attributes->{name};

  return
    if $self->queue_exists($queue_name);

  $attributes //= {};

  my %default_attrs = (
    VisibilityTimeout             => $DEFAULT_SQS_VISIBILITY_TIMEOUT,
    MessageRetentionPeriod        => $DEFAULT_SQS_MESSAGE_RETENTION_PERIOD,
    ReceiveMessageWaitTimeSeconds => $DEFAULT_SQS_RECEIVE_MESSAGE_WAIT_TIME_SECONDS,
    DelaySeconds                  => $DEFAULT_SQS_DELAY_SECONDS,
  );

  my @attribute_names = qw(
    visibility_timeout
    message_retention_period
    receive_message_wait_time_seconds
    delay_seconds
  );

  my %queue_attributes;

  for my $attr (@attribute_names) {
    my $param = $attr;
    $param = join q{}, map {ucfirst} split /_/xsm, $attr;

    # apparently these all need to be strings?
    $queue_attributes{$param} = sprintf '%s', $self->get($attr) // $default_attrs{$param};
  }

  if ( my $dlq = $attributes->{dlq} ) {
    croak "ERROR: you must provide an target ARN when creating a dead letter queue\n"
      if !$dlq->{arn};

    croak "ERROR: if you want a DLQ you have to set the max_receive_count\n",
      if !exists $attributes->{max_receive_count};

    # really? a string AWS?...apparently... 🤯
    #
    # Invalid type for parameter Attributes.RedrivePolicy, value:
    # OrderedDict({'deadLetterTargetArn':
    # 'arn:aws:sqs:us-east-1:311974035819:fu-man-q-dlq',
    # 'maxReceiveCount': '5'}), type: <class
    # 'collections.OrderedDict'>, valid types: <class 'str'>

    my $max_receive_count = sprintf '%s', $attributes->{max_receive_count} || $DEFAULT_SQS_MAX_RECEIVE_COUNT;

    $queue_attributes{RedrivePolicy} = encode_json(
      { deadLetterTargetArn => $dlq->{arn},
        maxReceiveCount     => $max_receive_count,  # must be string not an int
      }
    );
  }

  my $attribute_payload = encode_json( \%queue_attributes );

  $self->get_logger->trace( sub { return Dumper( [ attributes => $attribute_payload ] ) } );

  return $self->command(
    'create-queue' => [
      '--attributes' => $attribute_payload,
      '--queue-name' => $queue_name,
    ]
  );
}

1;

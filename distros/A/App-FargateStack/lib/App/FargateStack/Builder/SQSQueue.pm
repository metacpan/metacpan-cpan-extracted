package App::FargateStack::Builder::SQSQueue;

use strict;
use warnings;

use App::SQS;
use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);

use Role::Tiny;

########################################################################
# Creates an SQS queue and possibly a dead letter queue
########################################################################
# YAML configuration syntax:
########################################################################
# queue:
#   name: queue-name # required if queue: defined
#   max_receive_count:  # if exists, we will create a DLQ
# optional queue attributes (use Amazon's defaults)
#   visibility_timeout:
#   maximum_message_size:
#   delay_seconds:
#   receive_message_wait_time_seconds:
#   message_retention_period:
# dlq:
#   name: optional, default queue-name-dlq
# optional queue attributes
#
########################################################################
sub build_queue {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun, $cache ) = $self->common_args(qw(config dryrun cache));

  my ( $queue, $dlq ) = @{$config}{qw(queue dlq)};

  return
    if !$queue || !$queue->{name};

  my $sqs = App::SQS->new( $self->get_global_options );

  my $queue_url = $self->queue_exists( sqs => $sqs, %{$queue} );

  if ($queue_url) {
    $queue->{url} = $queue_url;
    $self->inc_existing_resources( queue => $queue_url );
  }
  else {
    $self->get_logger->info( sprintf 'queue: %s will be created...%s', $queue->{name}, $dryrun );
    $self->inc_required_resources( 'queue' => $queue->{name} );
  }

  my $want_dlq = exists $queue->{max_receive_count};

  my $dlq_url = $want_dlq && $self->queue_exists( sqs => $sqs, %{$dlq} );

  $dlq = $want_dlq && !$dlq ? {} : $dlq;

  if ($want_dlq) {
    my $default_dlq_name = sprintf '%s-dlq', $queue->{name};

    $config->{dlq} //= $dlq;  # make sure dlq: key is set in config

    $dlq->{name} //= $default_dlq_name;

    if ($dlq_url) {
      $dlq->{url} = $dlq_url;

      # just in case the create succeeded but we failed to record the arn
      $self->ensure_queue_arn( $dlq, $sqs );

      $self->inc_existing_resources( 'queue:dlq' => $dlq_url );
    }
    else {
      $self->get_logger->info( sprintf 'queue: %s will be created...%s', $dlq->{name}, $dryrun );
      $self->inc_required_resources( 'queue:dlq' => $dlq->{name} );
    }
  }

  return
    if $dryrun || ( $dlq_url && $queue_url );

  $self->log_trace(
    sub {
      return Dumper(
        [ dlq_url => $dlq_url,
          dlq     => $dlq
        ]
      );
    }
  );

  ######################################################################
  # deadletter queue - if we have a dead letter queue defined, but the
  # url does not exists in config - we need to create the queue before
  # creating the main queue
  ######################################################################
  if ( $dlq && !$dlq_url ) {
    $self->apply_queue_defaults($dlq);

    my $result = $sqs->create_queue($dlq);

    log_die( $self, "ERROR: could not create queue: [%s]\n%s", $dlq->{name}, $sqs->get_error )
      if !$result;

    $dlq->{url} = $result->{QueueUrl};

    $self->ensure_queue_arn( $dlq, $sqs );

    $self->log_warn( 'queue: successfully created the dead letter queue: [%s]', $dlq->{name} );
  }

  return
    if $queue_url;

  ######################################################################
  # create the main queue
  ######################################################################
  $self->apply_queue_defaults($queue);

  ######################################################################
  # we recognized the need for a DLQ because max_receive_count
  # existed, but maybe not defined?
  ######################################################################
  if ($dlq) {

    ####################################################################
    # just is in case we don't have the arn recorded...set it since we
    # need it for creating the main queue
    ####################################################################
    $self->ensure_queue_arn( $dlq, $sqs );
  }

  my %queue_attributes = ( dlq => $dlq, %{$queue} );

  my $result = $sqs->create_queue( \%queue_attributes );

  croak sprintf "could not create queue: [%s]\n%s", $queue->{name}, $sqs->get_error
    if !$result;

  $queue->{url} = $result->{QueueUrl};

  my $arn = $sqs->get_queue_attributes(
    queue_url       => $queue->{url},
    attribute_names => ['QueueArn'],
    query           => 'Attributes.QueueArn'
  );

  croak sprintf "could not get queue attributes for queue: [%s]\n%s", $queue->{name}, $sqs->get_error
    if !$arn;

  $queue->{arn} = $arn;

  $self->log_warn( 'queue: successfully created queue: [%s]', $queue->{name} );

  return;
}

########################################################################
sub ensure_queue_arn {
########################################################################
  my ( $self, $queue, $sqs ) = @_;

  return if $queue->{arn};

  return $queue->{arn} = $sqs->get_queue_arn( $queue->{url} );
}

########################################################################
sub queue_exists {
########################################################################
  my ( $self, %args ) = @_;

  my ( $sqs, $queue_url, $queue_name ) = @args{qw(sqs url name)};

  my $cache = $self->get_cache;

  $queue_url = $cache && $queue_url ? $queue_url : $sqs->queue_exists($queue_name);

  return
    if !$queue_url;

  $self->get_logger->info( sprintf 'queue: [%s] exists...%s', $queue_name, $cache ? $cache : 'skipping' );

  return $queue_url;
}

########################################################################
sub apply_queue_defaults {
########################################################################
  my ( $self, $q ) = @_;

  $q->{maximum_message_size}              //= $DEFAULT_SQS_MAXIMUM_MESSAGE_SIZE;
  $q->{visibility_timeout}                //= $DEFAULT_SQS_VISIBILITY_TIMEOUT;
  $q->{message_retention_period}          //= $DEFAULT_SQS_MESSAGE_RETENTION_PERIOD;
  $q->{receive_message_wait_time_seconds} //= $DEFAULT_SQS_RECEIVE_MESSAGE_WAIT_TIME_SECONDS;
  $q->{delay_seconds}                     //= $DEFAULT_SQS_DELAY_SECONDS;

  # max_receive_count indicates we have a DLQ
  if ( exists $q->{max_receive_count} ) {
    $q->{max_receive_count} ||= $DEFAULT_SQS_MAX_RECEIVE_COUNT;
  }
  return;
}

########################################################################
sub add_queue_policy {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my $dlq = $config->{dlq};

  my @queue_arns = ( $config->{queue}->{arn}, defined $dlq && $dlq->{arn} ? $dlq->{arn} : () );

  return {
    Effect   => 'Allow',
    Action   => ['sqs:*'],
    Resource => \@queue_arns,
  };
}

1;

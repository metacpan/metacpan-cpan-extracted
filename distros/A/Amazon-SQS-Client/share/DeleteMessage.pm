package DeleteMessage;

use strict;
use warnings;

use Amazon::SQS::Model::DeleteMessageRequest;
use parent qw(Amazon::SQS::Sample);

########################################################################
sub sample {
########################################################################
  my ( $self, $receipt_handle, $queue_url ) = @_;

  my $service = $self->get_service;

  my $config = $self->get_config;
  $queue_url //= $config && $config->get_queue_url;

  if ( !$queue_url || !$receipt_handle ) {
    $self->help();
  }

  my $request = Amazon::SQS::Model::DeleteMessageRequest->new(
    { QueueUrl      => $queue_url,
      ReceiptHandle => $receipt_handle
    }
  );

  my $response = $service->deleteMessage($request);

  if ( $response->isSetResponseMetadata() ) {

    my $responseMetadata = $response->getResponseMetadata();
    if ( $responseMetadata->isSetRequestId() ) {
      my $requestId = $responseMetadata->getRequestId();
    }
  }

  return;
}

1;

## no critic

__END__

=pod

=head1 USAGE

 example.pl [-f config-file] DeleteMessage receipt-handle [queue-url]

Note: If you do not set the queue URL in the config, then you must
provide it on the command line.

=head1 OPTIONS

 --endpoint-url, -e  API endpoint, default: https://queue.amazonaws.com
 --file, -f          Name of a .ini configuration file
 --help, -h          help

=cut


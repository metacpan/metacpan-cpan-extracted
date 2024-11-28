package SendMessage;

use strict;
use warnings;

use Amazon::SQS::Model::SendMessageRequest;

use parent qw(Amazon::SQS::Sample);

########################################################################
sub sample {
########################################################################
  my ( $self, $message, $queue_url ) = @_;

  my $service = $self->get_service;

  my $config = $self->get_config;
  $queue_url //= $config && $config->get_queue_url;

  if ( !$queue_url ) {
    $self->help();
  }

  my $request = Amazon::SQS::Model::SendMessageRequest->new(
    { QueueUrl    => $queue_url,
      MessageBody => $message,
    }
  );

  my $response = $service->sendMessage($request);

  if ( $response->isSetSendMessageResult() ) {
    my $sendMessageResult = $response->getSendMessageResult();
    if ( $sendMessageResult->isSetMessageId() ) {
      print {*STDOUT} sprintf "%s\n", $sendMessageResult->getMessageId();
    }

    if ( $sendMessageResult->isSetMD5OfMessageBody() ) {
      my $md5 = $sendMessageResult->getMD5OfMessageBody();
    }
  }

  if ( $response->isSetResponseMetadata() ) {
    my $responseMetadata = $response->getResponseMetadata();
    if ( $responseMetadata->isSetRequestId() ) {
      my $requestId = $responseMetadata->getRequestId();
    }
  }

  return;
}

1;

=pod

=head1 USAGE

 example.pl [-f config-file] SendMessage message [queue-url]

Note: If you do not set the queue URL in the config, then you must
provide it on the command line.

=head1 OPTIONS

 --endpoint-url, -e  API endpoint, default: https://queue.amazonaws.com
 --file, -f          Name of a .ini configuration file
 --help, -h          help

=cut

package ReceiveMessage;

use strict;
use warnings;

use Amazon::SQS::Model::ReceiveMessageRequest;
use Data::Dumper;

use parent qw(Amazon::SQS::Sample);

########################################################################
sub sample {
########################################################################
  my ( $self, $queue_url ) = @_;

  my $service = $self->get_service;

  my $config = $self->get_config;
  $queue_url //= $config && $config->get_queue_url;

  if ( !$queue_url ) {
    $self->help();
  }

  my $request = Amazon::SQS::Model::ReceiveMessageRequest->new(
    { QueueUrl            => $queue_url,
      MaxNumberOfMessages => 10,
      WaitSeconds         => 20,
    }
  );

  my $response = $service->receiveMessage($request);

  if ( $response->isSetReceiveMessageResult() ) {
    my $receiveMessageResult = $response->getReceiveMessageResult();
    my $messageList          = $receiveMessageResult->getMessage();

    foreach ( @{$messageList} ) {
      my $message = $_;

      if ( $message->isSetMessageId() ) {
        my $messageId = $message->getMessageId();

        if ( $message->isSetReceiptHandle() ) {
          my $receiptHandle = $message->getReceiptHandle();
          print {*STDOUT} sprintf "RECEIPT_HANDLE='%s'\n", $receiptHandle;
        }
        if ( $message->isSetMD5OfBody() ) {
          my $md5 = $message->getMD5OfBody();
        }
        if ( $message->isSetBody() ) {
          print {*STDOUT} sprintf "MESSAGE='%s'\n", $message->getBody();
        }

        my $attributeList = $message->getMessageAttribute();

        foreach ( @{$attributeList} ) {
          my $attribute = $_;
          if ( $attribute->isSetName() ) {
            my $name = $attribute->getName();
          }
          if ( $attribute->isSetValue() ) {
            my $value = $attribute->getValue();
          }
        }
      }
    }
  }

  if ( $response->isSetResponseMetadata() ) {
    my $responseMetadata = $response->getResponseMetadata();
    if ( $responseMetadata->isSetRequestId() ) {
      my $request_id = $responseMetadata->getRequestId();
    }
  }

  return;
}

1;

## no critic

__END__

=pod

=head1 USAGE

 example.pl [-f config-file] ReceiveMessage [queue-url]

Note: If you do not set the queue URL in the config, then you must
provide it on the command line.

Will return the message and receipt handle. Use the receipt handle to
delete the message.

 example.pl -f aws-sqs.ini SendMessage "Hello World!"

=head1 OPTIONS

 --endpoint-url, -e  API endpoint, default: https://queue.amazonaws.com
 --file, -f          Name of a .ini configuration file
 --help, -h          help

=cut

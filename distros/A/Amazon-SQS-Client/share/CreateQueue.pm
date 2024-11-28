package CreateQueue;

use strict;
use warnings;

use Amazon::SQS::Model::CreateQueueRequest;

use English qw(-no_match_vars);
use JSON;
use Data::Dumper;

use parent qw(Amazon::SQS::Sample);

########################################################################
sub sample {
########################################################################
  my ($self, $queue_name) = @_;
  
  die "usage: example.pl [-f config-name] CreateQueue queue-name\n"
    if !$queue_name;

  my $service = $self->get_service;

  my $response = $service->createQueue( { QueueName => $queue_name } );

  if ( $response->isSetCreateQueueResult() ) {

    my $createQueueResult = $response->getCreateQueueResult();

    if ( $createQueueResult->isSetQueueUrl() ) {
      print {*STDOUT} Dumper( [ queueUrl => $createQueueResult->getQueueUrl() ] );
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

## no critic

__END__

=pod

=head1 USAGE

 example.pl CreateQueue queue-name

=cut

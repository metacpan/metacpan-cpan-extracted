package ListQueues;

use strict;
use warnings;

use Amazon::SQS::Model::ListQueuesRequest;
use English qw(-no_match_vars);
use JSON;

use parent qw(Amazon::SQS::Sample);

########################################################################
sub sample {
########################################################################
  my ($self) = @_;

  my $service = $self->get_service;

  my $response = $service->listQueues();

  if ( $response->isSetListQueuesResult() ) {
    my $listQueuesResult = $response->getListQueuesResult();
    my $queueUrlList     = $listQueuesResult->getQueueUrl();

    print {*STDOUT} JSON->new->pretty->encode($queueUrlList);
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

 example.pl ListQueues

=cut

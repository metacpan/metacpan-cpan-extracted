package GetQueueAttributes;

use strict;
use warnings;

use English qw(-no_match_vars);
use Amazon::SQS::Model::GetQueueAttributesRequest;
use Data::Dumper;

use parent qw(Amazon::SQS::Sample);

########################################################################
sub sample {
########################################################################
  my ( $self, $attributes, $queue_url ) = @_;

  $attributes //= 'All';

  $attributes = [ split /\s*,\s*/xsm, $attributes ];

  my $service = $self->get_service;

  my $config = $self->get_config;
  $queue_url //= $config && $config->get_queue_url;

  if ( !$queue_url ) {
    $self->help();
  }

  my $request = Amazon::SQS::Model::GetQueueAttributesRequest->new(
    { QueueUrl      => $queue_url,
      AttributeName => $attributes,
    }
  );

  my $response = $service->getQueueAttributes($request);

  if ( $response->isSetResponseMetadata() ) {
    my $responseMetadata = $response->getResponseMetadata();

    if ( $responseMetadata->isSetRequestId() ) {
      my $requestId = $responseMetadata->getRequestId();
    }
  }

  if ( $response->isSetGetQueueAttributesResult() ) {

    my $getQueueAttributesResult = $response->getGetQueueAttributesResult();
    my $attributeList            = $getQueueAttributesResult->getAttribute();

    my %attributes;

    foreach ( @{$attributeList} ) {
      if ( $_->isSetName() ) {
        $attributes{ $_->getName } = $_->getValue;
      }
    }

    print {*STDERR} Dumper( [ attributes => \%attributes ] );
  }

  return;
}

1;

## no critic

__END__

=pod

=head1 USAGE

 example.pl [-f config-file] GetQueueAttributes attributes [queue-url]

 attributes is a list of attributes. Default: 'All'

Note: If you do not set the queue URL in the config, then you must
provide it on the command line.

=head1 OPTIONS

 --endpoint-url, -e API endpoint, default: https://queue.amazonaws.com
 --file, -f Name of a .ini configuration file help, -h help

=cut

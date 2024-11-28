package SetQueueAttributes;

use strict;
use warnings;

use English qw(-no_match_vars);
use Amazon::SQS::Model::SetQueueAttributesRequest;
use Data::Dumper;
use List::Util qw(pairs);

use parent qw(Amazon::SQS::Sample);

########################################################################
sub sample {
########################################################################
  my ( $self, $attributes, $queue_url ) = @_;

  if ( !$attributes ) {
    warn "attributes is a required argument\n";
    $self->help();
  }

  my @attribute_list = map { split /\s*=s*/xsm, $_ } split /\s*,\s*/xsm, $attributes;
  my @attribute_names;

  foreach my $p ( pairs @attribute_list ) {
    push @attribute_names, { Name => $p->[0], Value => $p->[1], };
  }

  my $service = $self->get_service;

  my $config = $self->get_config;
  $queue_url //= $config && $config->get_queue_url;

  if ( !$queue_url ) {
    $self->help();
  }

  my $request = Amazon::SQS::Model::SetQueueAttributesRequest->new(
    { QueueUrl  => $queue_url,
      Attribute => \@attribute_names,
    }
  );

  my $response = $service->setQueueAttributes($request);

  if ( $response->isSetResponseMetadata() ) {
    my $responseMetadata = $response->getResponseMetadata();
    if ( $responseMetadata->isSetRequestId() ) {
      my $requesId = $responseMetadata->getRequestId();
    }
  }

  return;
}

1;

## no critic

__END__

=pod

=head1 USAGE

 example.pl [-f config-file] SetQueueAttributes attributes [queue-url]

 attributes is a list of key, value pairs. Example:

 'VisibilityTimeout=60,MessageRetentionPeriod=3600'

Note: If you do not set the queue URL in the config, then you must
provide it on the command line.

=head1 OPTIONS

 --endpoint-url, -e API endpoint, default: https://queue.amazonaws.com
 --file, -f Name of a .ini configuration file help, -h help

=cut

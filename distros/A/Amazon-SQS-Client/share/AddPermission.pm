package AddPermission;

use strict;
use warnings;
use English qw(-no_match_vars);
use Amazon::SQS::Model::AddPermissionRequest;
use Data::Dumper;

use parent qw(Amazon::SQS::Sample);

########################################################################
sub sample {
########################################################################
  my ( $self, $label, $actions, $account_ids, $queue_url ) = @_;

  if ( !$actions ) {
    warn "actions is a required argument\n";
    $self->help();
  }

  if ( !$account_ids ) {
    warn "acccount-ids is a required argument\n";
    $self->help();
  }

  if ( !$label ) {
    warn "label is a required argument\n";
    $self->help();
  }

  $actions     = [ split /\s*,\s*/xsm, $actions ];
  $account_ids = [ split /\s*,\s*/xsm, $account_ids ];

  my $service = $self->get_service;

  my $config = $self->get_config;
  $queue_url //= $config && $config->get_queue_url;

  if ( !$queue_url ) {
    $self->help();
  }

  my $request = Amazon::SQS::Model::AddPermissionRequest->new(
    { QueueUrl     => $queue_url,
      Label        => $label,
      ActionName   => $actions,
      AWSAccountId => $account_ids,
    }
  );

  my $response = eval { $service->addPermission($request); };

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

 example.pl [-f config-file] AddPermission label actions account-ids
 [queue-url]

 'actions' and 'account-ids' should be comma delimited strings.

Note: If you do not set the queue URL in the config, then you must
provide it on the command line.

=head1 OPTIONS

 --endpoint-url, -e API endpoint, default: https://queue.amazonaws.com
 --file, -f Name of a .ini configuration file help, -h help

=cut

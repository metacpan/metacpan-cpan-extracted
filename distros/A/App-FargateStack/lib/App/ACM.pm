package App::ACM;

use strict;
use warnings;

use Role::Tiny::With;
use JSON;
use File::Temp qw(tempfile);
use Data::Dumper;

with 'App::AWS';

use parent 'App::Command';

__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_accessors(qw(domain validation_method profile region));

########################################################################
sub list_certificates {
########################################################################
  my ($self) = @_;

  return $self->command( 'list-certificates' => [ '--query' => 'CertificateSummaryList', ] );
}

########################################################################
sub describe_certificate {
########################################################################
  my ( $self, $cert_arn, $query ) = @_;

  return $self->command(
    'describe-certificate' => [
      '--certificate-arn' => $cert_arn,
      $query ? ( '--query' => $query ) : (),
    ]
  );
}

########################################################################
# returns the certificate arn
########################################################################
sub request_certificate {
########################################################################
  my ($self) = @_;

  my $domain = $self->get_domain or die 'Domain not set';
  my $method = $self->get_validation_method // 'DNS';

  return $self->command(
    'request-certificate' => [
      '--domain-name'       => $domain,
      '--validation-method' => $method,
      '--output'            => 'text',
      '--query'             => 'CertificateArn',
    ]
  );
}

1;

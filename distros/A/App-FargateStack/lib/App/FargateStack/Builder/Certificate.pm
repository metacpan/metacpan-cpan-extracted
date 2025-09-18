package App::FargateStack::Builder::Certificate;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);

use App::FargateStack::Constants;

use Role::Tiny;

########################################################################
sub build_certificate {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun ) = $self->common_args(qw(config dryrun));

  my $domain = $config->{domain};

  my $acm = $self->fetch_acm( domain => $domain );

  my @all_certs = @{ $acm->list_certificates };

  my ($cert) = grep { $domain eq $_->{DomainName} } @all_certs;

  my $arn;

  if ($cert) {
    my $status = $cert->{Status};

    $self->log_info( 'certificate: [%s] certificate exists, status: [%s]...skipping', $domain, $status );

    $arn = $cert->{CertificateArn};

    $self->inc_existing_resources( certificate => $arn );
  }
  else {
    $self->log_warn( 'certificate: certificate for [%s] will be created...%s', $domain, $dryrun );

    $self->inc_required_resources(
      certificate => sub {
        return $self->get_config->{certficate_arn} // 'arn:???';
      }
    );

    if ( !$dryrun ) {

      $arn = $acm->request_certificate();
      $acm->check_result( message => 'ERROR: could not create certifcate for: [%s]', $domain );

      sleep $ACM_REQUEST_SLEEP_TIME;

      my $dns_record = $acm->describe_certificate( $arn, 'Certificate.DomainValidationOptions[0].ResourceRecord' );

      log_die( $self, 'ERROR: no DNS record found yet for %s', $arn )
        if !$dns_record;

      my ( $name, $type, $value ) = @{$dns_record}{qw(Name Type Value)};

      my $change_batch = {
        ChangeBatch => {
          Changes => [
            { Action            => 'UPSERT',
              ResourceRecordSet => {
                Name            => $name,
                Type            => $type,
                TTL             => 300,
                ResourceRecords => [ { Value => $value } ]
              }
            }
          ]
        }
      };

      my $route53 = $self->fetch_route53();

      $route53->set_change_batch($change_batch);

      $route53->change_resource_record_sets;

      print {*STDERR} Dumper( [$route53] );

      $route53->check_result( message => 'ERROR: could not insert DNS record' );

    }
  }

  $config->{certificate_arn} = $arn;

  return $cert;
}

1;

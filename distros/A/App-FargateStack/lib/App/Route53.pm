package App::Route53;

use strict;
use warnings;

use Carp;
use File::Temp qw(tempfile);
use Data::Dumper;
use JSON;
use App::FargateStack::Constants;

use Role::Tiny::With;
with 'App::AWS';

use parent 'App::Command';

__PACKAGE__->follow_best_practice;

__PACKAGE__->mk_accessors(
  qw(
    elbv2
    hosted_zone_id
    change_batch
    region
    profile
    unlink
  )
);

########################################################################
sub get_hosted_zone {
########################################################################
  my ( $self, $zone_id ) = @_;

  $zone_id //= $self->get_hosted_zone_id;

  return $self->command( 'get-hosted-zone' => [ '--id' => $self->get_hosted_zone_id, ] );
}

########################################################################
sub create_alias {
########################################################################
  my ( $self, %args ) = @_;

  my ( $elb, $zone_id, $domain ) = @args{qw(elb zone_id domain)};

  my ( $alb_dns_name, $alb_zone_id ) = @args{qw(alb_dns_name alb_zone_id)};

  $zone_id //= $self->get_hosted_zone_id;

  die "zone_id is a required argument\n"
    if !$zone_id;

  die "domain is a required argument\n"
    if !$domain;

  my $change_batch = {
    ChangeBatch => {
      Changes => [
        { Action            => 'UPSERT',
          ResourceRecordSet => {
            Name        => $domain,
            Type        => 'A',
            AliasTarget => {
              HostedZoneId         => $alb_zone_id,
              DNSName              => $alb_dns_name,
              EvaluateTargetHealth => JSON::false,
            }
          }
        }
      ]
    }
  };

  return $self->change_resource_record_sets( $zone_id, $change_batch );
}

########################################################################
sub change_resource_record_sets {
########################################################################
  my ( $self, $zone_id, $change_batch ) = @_;

  $zone_id //= $self->get_hosted_zone_id;

  $change_batch //= $self->get_change_batch;

  die "usage: change_resource_record_sets(zone-id, change-batch)\n"
    if !$zone_id || !$change_batch;

  my ( $fh, $filename ) = tempfile(
    'rrs-change-XXXXXX',
    UNLINK => $self->get_unlink,
    SUFFIX => '.json'
  );

  print {$fh} encode_json($change_batch);

  close $fh;

  return $self->command(
    'change-resource-record-sets' => [
      '--hosted-zone-id' => $zone_id,
      '--cli-input-json' => "file://$filename",
    ]
  );
}

########################################################################
sub list_hosted_zones {
########################################################################
  my ( $self, $zone_id ) = @_;

  my $query = $zone_id ? sprintf 'HostedZones[?Id == `/hostedzone/%s`]', $zone_id : $EMPTY;

  return $self->command( 'list-hosted-zones' => [ $query ? ( '--query' => $query ) : () ] );
}

########################################################################
sub validate_hosted_zone {
########################################################################
  my ( $self, %args ) = @_;

  my ( $zone_id, $domain, $alb_type ) = @args{qw(zone_id domain alb_type)};

  my $query = sprintf 'HostedZones[?Id == `/hostedzone/%s`]', $zone_id;

  my $zone = $self->list_hosted_zones($zone_id);

  die sprintf "invalid zone_id: [%s]\n", $zone_id
    if !$zone;

  $zone = $zone->[0];

  my $zone_name = $zone->{Name};

  my $zone_type = $zone->{Config}->{PrivateZone} ? 'private' : 'public';

  $zone_name =~ s/[.]$//xsm;

  die sprintf "your domain [%s] cannot be configured in [%s]'s zone (%s)\n", $domain, $zone_name, $zone_id
    if $domain !~ /$zone_name/xsm;

  die sprintf "your ALB type [%s] is not compatible with the hosted zone %s (%s)\n", $alb_type, $zone_id, $zone_type
    if $zone_type ne $alb_type;

  return $zone;
}

########################################################################
sub find_hosted_zone {
########################################################################
  my ( $self, $domain, $type ) = @_;

  $domain = sprintf '%s.%s.', ( split /[.]/xsm, $domain )[ -2, -1 ];

  die "usage: find_hosted_zone(domain, public|private)\n"
    if !$domain;

  $type //= 'public';

  $type = $type eq 'public' ? 'false' : 'true';

  my $query = sprintf 'HostedZones[?Name==`%s` && Config.PrivateZone ==`%s`]', $domain, $type;

  return $self->command( 'list-hosted-zones' => [ '--query' => $query ] );
}

########################################################################
sub list_resource_record_sets {
########################################################################
  my ( $self, $zone_id, $query ) = @_;

  croak "usage: list_resource_record_set(zone-id, [query])\n"
    if !$zone_id;

  return $self->command(
    'list-resource-record-sets' => [
      '--hosted-zone-id' => $zone_id,
      $query ? ( '--query' => $query ) : (),
    ]
  );
}

########################################################################
sub find_alias_record {
########################################################################
  my ( $self, %args ) = @_;

  my ( $zone_id, $dns_name, $domain_name ) = @args{qw(zone_id dns_name domain_name)};

  my $query = sprintf 'ResourceRecordSets[?Name==`%s.` && Type==`A` && AliasTarget.DNSName==`%s.`]', $domain_name, $dns_name;

  return $self->command(
    'list-resource-record-sets' => [
      '--hosted-zone-id', $zone_id,
      '--query'  => $query,
      '--output' => 'json'
    ]
  );
}

1;

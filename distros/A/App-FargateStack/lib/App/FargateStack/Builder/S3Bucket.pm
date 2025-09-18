package App::FargateStack::Builder::S3Bucket;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);

use App::S3Api;
use App::FargateStack::Constants;

use Role::Tiny;

########################################################################
# Create an S3 bucket and provides method adding a bucket policy for
# the Fargate role.
# YAML configuration syntax:
########################################################################
# bucket:
#   name: bucket-name
#   policy:
########################################################################
sub build_bucket {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my $bucket = $config->{bucket};

  return
    if !$bucket || !$bucket->{name};

  my $s3 = App::S3Api->new( %{$bucket}, %{ $self->get_global_options } );

  my $dryrun = $self->get_dryrun;

  if ( $s3->bucket_exists ) {
    $self->get_logger->info( sprintf 'bucket: [%s] exists skipping...', $bucket->{name} );

    $self->inc_existing_resources( bucket => $bucket->{name} );
  }
  else {
    $self->inc_required_resources( bucket => $bucket->{name} );

    $self->get_logger->info( sprintf 'bucket: [%s] will be created...%s', $bucket->{name}, $dryrun );

    if ( !$dryrun ) {
      $s3->create_bucket;
    }
  }

  if ( $bucket->{policy} && !$s3->policy_exists ) {
    $self->get_logger->info( sprintf 'bucket policy: [%s] will be attached...%s', $bucket->{policy}, $dryrun );
    $self->inc_required_resources( bucket_policy => $bucket->{policy} );

    if ( !$dryrun ) {
      $s3->put_bucket_policy;
    }
  }
  elsif ( $s3->policy_exists ) {
    $self->inc_existing_resources( bucket_policy => $bucket->{policy} // 'configured policy' );
  }

  return $TRUE;
}

########################################################################
sub add_bucket_policy {
########################################################################
  my ($self) = @_;

  my $bucket = $self->get_config->{bucket};

  my ( $readonly, $name, $paths ) = @{$bucket}{qw(readonly name paths)};

  $readonly //= $FALSE;
  $paths    //= [];

  my $bucket_arn = sprintf $S3_BUCKET_ARN_TEMPLATE, $name;
  my $action     = $readonly ? ['s3:GetObject'] : ['s3:*'];

  my @resources = ( $bucket_arn, map { sprintf '%s/%s', $bucket_arn, $_ } @{$paths} );

  # ListBucket needed if using paths with readonly access
  if ( $readonly && @{$paths} ) {
    push @{$action}, 's3:ListBucket';
  }

  return {
    Effect   => 'Allow',
    Action   => $action,
    Resource => \@resources,
  };
}

1;

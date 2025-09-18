package App::FargateStack::Builder::Cluster;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);

use App::FargateStack::Constants;

use Role::Tiny;

########################################################################
sub build_fargate_cluster {
########################################################################
  my ($self) = @_;

  my ( $config, $cluster, $dryrun ) = $self->common_args(qw(config cluster dryrun));

  $cluster //= {};

  my $ecs = $self->fetch_ecs;

  my ( $cluster_name, $cluster_arn ) = @{$cluster}{qw(name arn)};

  if ( !$cluster_name || !$cluster_arn ) {
    $config->{cluster} //= $cluster;
    $cluster_name = $self->create_default('cluster-name');
    $cluster->{name} = $cluster_name;
  }

  ## - cluster exists? -
  if ( !$cluster_arn || !$self->get_cache ) {
    # - validate cluster arn
    $cluster_arn = $ecs->cluster_exists($cluster_name);
  }

  if ($cluster_arn) {
    $self->log_info( sprintf 'cluster: [%s] exists...%s', $cluster_name, $self->get_cache || 'skipping' );

    $self->inc_existing_resources( cluster => [$cluster_arn] );
    $cluster->{arn} = $cluster_arn;

    return;
  }

  ## - create cluster -
  $self->log_warn( sprintf 'cluster: [%s] will be created...%s', $cluster_name, $dryrun );

  $self->inc_required_resources(
    cluster => sub {
      my ($dryrun) = @_;
      return $dryrun ? "arn:???/$cluster_name" : $config->{cluster}->{arn};
    }
  );

  return
    if $dryrun;

  my $result = $ecs->create_cluster($cluster_name);
  $ecs->check_result( 'ERROR: could not create cluster [%s]', $cluster_name );

  $self->log_warn( sprintf 'cluster: [%s] created...', $cluster_name );

  $cluster->{arn} = $result->{cluster}->{clusterArn};

  return $TRUE;
}

########################################################################
sub add_ecr_policy {
########################################################################
  my ($self) = @_;

  my $tasks = $self->get_config->{tasks};

  my @repos;

  foreach my $task_name ( keys %{$tasks} ) {
    my $image = $self->resolve_image_name( $tasks->{$task_name}->{image} );
    if ( $image =~ m{/}xsm ) {
      ($image) = ( split m{/}xsm, $image )[-1];
    }

    my ( $name, $tag ) = split /:/xsm, $image;
    push @repos, sprintf $ECR_ARN_TEMPLATE, $self->get_region, $self->get_account, $name;
  }

  return (
    { Effect   => 'Allow',
      Action   => ['ecr:GetAuthorizationToken'],
      Resource => q{*}
    },
    { Effect   => 'Allow',
      Action   => [qw(ecr:BatchGetImage ecr:GetDownloadUrlForLayer ecr:BatchCheckLayerAvailability)],
      Resource => \@repos,
    }
  );
}

1;

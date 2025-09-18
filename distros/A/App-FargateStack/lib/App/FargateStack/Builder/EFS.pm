package App::FargateStack::Builder::EFS;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use JSON;

use App::FargateStack::Constants;

use Role::Tiny;

########################################################################
sub add_volumes {
########################################################################
  my ( $self, $task ) = @_;

  return
    if !$task->{efs};

  require App::EFS;

  my $efs = $self->fetch_efs();

  my $efs_config = $task->{efs};

  my ( $id, $path, $mount_point ) = @{$efs_config}{qw(id path mount_point)};

  if ( !$mount_point ) {
    $self->log_error('task:efs WARNING: no mount point defined...using /mnt');
  }

  my ( $arn, $readonly ) = @{$efs_config}{qw(arn readonly)};

  log_die( $self, 'ERROR: no id set for EFS volume' )
    if !$id;

  # - validate id -
  if ( !$arn || !$self->get_cache ) {
    $self->log_info( 'task: validating EFS id: [%s]...', $id );

    my $file_system = $efs->describe_file_systems( $id, 'FileSystems' );

    log_die( $self, "ERROR: no such EFS file system (%s) found\n", $id )
      if !$file_system;

    $arn = $efs_config->{arn} = $file_system->[0]->{FileSystemArn};

    $self->log_info( 'task: EFS ARN: [%s]', $arn );
  }

  return (
    [ { name                   => 'efs-volume',
        efsVolumeConfiguration => {
          fileSystemId      => $id,
          rootDirectory     => $path // q{/},
          transitEncryption => 'ENABLED'
        }
      }
    ],
    [ { sourceVolume  => 'efs-volume',
        containerPath => $mount_point // '/mnt',
        readOnly      => defined $readonly && $readonly ? $JSON::true : $JSON::false,
      }
    ]
  );
}

########################################################################
sub add_efs_policy {
########################################################################
  my ($self) = @_;

  my $tasks = $self->get_config->{tasks};

  my @efs_arns;

  foreach my $task_name ( keys %{$tasks} ) {
    my $efs = $tasks->{$task_name}->{efs};
    next if !$efs || !$efs->{id};

    push @efs_arns, sprintf $EFS_ARN_TEMPLATE, $self->get_region, $self->get_account, $efs->{id};
  }

  return
    if !@efs_arns;

  return {
    Effect => 'Allow',
    Action => [
      qw(
        elasticfilesystem:ClientMount
        elasticfilesystem:ClientWrite
        elasticfilesystem:ClientRootAccess
      )
    ],
    Resource => \@efs_arns,
  };
}

1;

package App::EFS;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(profile region));

########################################################################
sub describe_file_systems {
########################################################################
  my ( $self, $file_system_id, $query ) = @_;

  return $self->command(
    'describe-file-systems' => [
      $file_system_id ? ( '--file-system-id' => $file_system_id ) : (),
      $query          ? ( '--query'          => $query )          : ()
    ]
  );
}

########################################################################
sub describe_mount_targets {
########################################################################
  my ( $self, $efs_id, $query ) = @_;

  return $self->command(
    'describe-mount-targets' => [
      '--file-system-id' => $efs_id,
      $query ? ( '--query' => $query ) : ()
    ]
  );

}

1;

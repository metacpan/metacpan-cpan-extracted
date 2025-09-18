package App::FargateStack::Builder::SecurityGroup;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);

use App::Events;
use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(log_die dmp);

use Role::Tiny;

########################################################################
sub build_security_group {
########################################################################
  my ($self) = @_;

  my ( $config, $security_groups, $dryrun ) = $self->common_args(qw(config security_groups dryrun));

  my $ec2 = $self->get_ec2;

  $security_groups //= {};
  $config->{security_groups} = $security_groups;

  my $default_security_group_name = $self->create_default('security-group');

  my $security_group_name = $security_groups->{fargate}->{group_name} // $default_security_group_name;

  my $security_group_id = $security_groups->{fargate}->{group_id};

  $security_groups->{fargate}->{group_name} = $security_group_name;

  $self->log_trace(
    sub {
      return Dumper(
        [ security_group_name => $security_group_name,
          security_group_id   => $security_group_id
        ]
      );
    }
  );

  if ( !$self->get_cache || !$security_group_id ) {
    my ($security_group) = $ec2->describe_security_group($security_group_name);
    $ec2->check_result( message => 'ERROR: could not describe security group: [%s]', $security_group_name );

    $self->log_debug( Dumper( [ 'security-group:' => $security_group ] ) );

    if ( !$security_group ) {
      $self->log_warn( 'security-group: [%s] will be created...%s', $security_group_name, $dryrun );

      $self->inc_required_resources( security_groups => [$security_group_name] );

      if ( !$dryrun ) {
        my $description = sprintf 'Security group for %s Fargate tasks', $config->{app}->{name};

        my $security_group_id = $ec2->create_security_group( $security_group_name, $description );

        log_die( $self, "ERROR: could not create security group:%s\n%s", $security_group_name, $ec2->get_error )
          if !$security_group_id;

        $security_groups->{fargate}->{group_id} = $security_group_id;

        # authorize ingress when/if we have an ALB
        $self->log_info( 'security-group: [%s] id: [%s] created', $security_group_name, $security_group_id );
      }

      return;
    }
    else {
      $security_groups->{fargate}->{group_id} = $security_group->{GroupId};
      $security_group_id = $security_group->{GroupId};
    }
  }

  $self->log_info( 'security-group: [%s] exists...%s', $security_group_name, $self->get_cache || 'skipping' );
  $self->inc_existing_resources( security_groups => [$security_group_id] );

  return;
}

1;

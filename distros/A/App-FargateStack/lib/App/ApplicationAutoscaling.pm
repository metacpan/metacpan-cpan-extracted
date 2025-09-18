#!/usr/bin/env perl
package App::ApplicationAutoscaling;

use strict;
use warnings;

use App::FargateStack::Constants;
use Carp;
use Data::Dumper;
use List::Util qw(any);

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(region profile));

# This command defines the "what" and "how" of scaling.
# It tells Auto Scaling to keep the requests per task at 500.

# This command registers your service with Application Auto Scaling.
# Replace the placeholders with your actual values.

=pod

 aws application-autoscaling register-scalable-target \
   --service-namespace ecs \
   --scalable-dimension ecs:service:DesiredCount \
   --resource-id service/YOUR_CLUSTER_NAME/YOUR_SERVICE_NAME \
   --min-capacity 1 \
   --max-capacity 10
 
 
 aws application-autoscaling put-scaling-policy \
   --policy-name "alb-requests-per-minute-policy" \
   --service-namespace ecs \
   --scalable-dimension ecs:service:DesiredCount \
   --resource-id service/YOUR_CLUSTER_NAME/YOUR_SERVICE_NAME \
   --policy-type TargetTrackingScaling \
   --target-tracking-scaling-policy-configuration '{
       "TargetValue": 500.0,
       "PredefinedMetricSpecification": {
         "PredefinedMetricType": "ALBRequestCountPerTarget",
         "ResourceLabel": "YOUR_ALB_AND_TARGET_GROUP_LABEL"
       },
       "ScaleOutCooldown": 60,
       "ScaleInCooldown": 300
     }'
 
=cut

########################################################################
sub register_scalable_targets {
########################################################################
  my ( $self, %args ) = @_;

  my ( $query, $service_namespace, $resource_id, $min_capacity, $max_capacity, $scalable_dimension )
    = @args{qw(query service_namespace resource_id min_capacity max_capacity scalable_dimension)};

  return $self->command(
    'register_scalable_targets' => [
      $query ? ( '--query' => $query ) : (),
      '--service-namespace'  => $service_namespace,
      '--scalable-dimension' => $scalable_dimension,
      '--resource_id'        => $resource_id,
      '--min-capacity'       => $min_capacity,
      '--max-capacity'       => $max_capacity,
    ]
  );
}

########################################################################
sub put_scaling_policy {
########################################################################
  my ( $self, %args ) = @_;

  my ( $query, $policy_name, $service_namespace, $scalable_dimension, $resource_id, $policy_type, $policy_configuration )
    = @args{qw(query policy_name service_namespace scalable_dimension resource_id policy_type policy_configuration)};

  return $self->command(
    'put-scaling-policy' => [
      '--policy-name'                                  => $policy_name,
      '--service-namespace'                            => $service_namespace,
      '--scalable-dimension'                           => $scalable_dimension,
      '--resource-id'                                  => $resource_id,
      '--policy-type'                                  => $policy_type,
      '--target-tracking-scaling-policy-configuration' => $policy_configuration,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub delete_scaling_policy {
########################################################################
  my ( $self, %args ) = @_;

  my ( $query, $service_namespace, $policy_name, $scalable_dimension, $resource_id )
    = @args{qw(query service_namespace policy_name scalable_dimension resource_id)};

  return $self->command(
    'delete-scaling-policy' => [
      '--policy-name'        => $policy_name,
      '--service-namespace'  => $service_namespace,
      '--scalable-dimension' => $scalable_dimension,
      '--resource-id'        => $resource_id,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub put_scheduled_action {
########################################################################
  my ( $self, %args ) = @_;

  my ( $query, $service_namespace, $scalable_dimension, $resource_id, $scheduled_action_name, $schedule,
    $scalable_target_action )
    = @args{qw(query service_namespace scalable_dimension resource_id name schedule scalable_target_action)};

  return $self->command(
    'put-scheduled-action' => [
      '--service-namespace'      => $service_namespace // 'ecs',
      '--resource-id'            => $resource_id,
      '--scalable-dimension'     => $scalable_dimension // 'ecs:service:DesiredCount',
      '--schedule'               => $schedule,
      '--scheduled-action-name'  => $scheduled_action_name,
      '--scalable-target-action' => $scalable_target_action,
      $query ? ( '--query' => $query ) : ()
    ]
  );

}

########################################################################
sub describe_scaling_policies {
########################################################################
  my ( $self, %args ) = @_;

  my ( $service_namespace, $policy_names, $query ) = @args{qw(service_namespace policy_names query)};

  return $self->command(
    'describe-scaling-policies' => [
      '--service-namespace' => $service_namespace,
      $policy_names ? ( '--policy-names' => $policy_names ) : (),
      $query        ? ( '--query'        => $query )        : ()
    ]
  );
}

########################################################################
sub describe_scalable_targets {
########################################################################
  my ( $self, %args ) = @_;

  my ( $service_namespace, $query ) = @args{qw(service_namespace query)};

  return $self->command(
    'describe-scalable-targets' => [
      '--service-namespace' => $service_namespace,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub describe_scheduled_actions {
########################################################################
  my ( $self, %args ) = @_;

  my ( $service_namespace, $scheduled_action_name, $resource_id, $scalable_dimension, $query )
    = @args{qw(service_namespace scheduled_action_name resource_id scalable_dimension query )};

  $service_namespace //= 'ecs';

  return $self->command(
    'describe-scheduled-actions' => [
      '--service-namespace' => $service_namespace,
      ($scheduled_action_name) ? ( '--scheduled-action-name' => $scheduled_action_name ) : (),
      ($resource_id)           ? ( '--resource-id'           => $resource_id )           : (),
      ($scalable_dimension)    ? ( '--scalable-dimension'    => $scalable_dimension )    : (),
      $query                   ? ( '--query'                 => $query )                 : ()
    ]
  );
}

########################################################################
sub delete_scheduled_action {
########################################################################
  my ( $self, %args ) = @_;

  my ( $service_namespace, $scheduled_action_name, $resource_id, $scalable_dimension, $query )
    = @args{qw(service_namespace scheduled_action_name resource_id scalable_dimension query )};

  $service_namespace //= 'ecs';

  return $self->command(
    'delete-scheduled-action' => [
      '--service-namespace'      => $service_namespace,
      '--scheduled-action-name', => $scheduled_action_name,
      '--resource-id'            => $resource_id,
      '--scalable-dimension'     => $scalable_dimension,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

1;

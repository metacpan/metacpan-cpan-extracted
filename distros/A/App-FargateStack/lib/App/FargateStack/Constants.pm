package App::FargateStack::Constants;

use strict;
use warnings;

use App::FargateStack::Builder::Utils qw(choose);

use Data::Dumper;
use English qw(no_match_vars);
use JSON;
use parent qw(Exporter);

use Readonly;

####################################################################
# Boolean constants
####################################################################
Readonly::Scalar our $TRUE  => 1;
Readonly::Scalar our $FALSE => 0;

####################################################################
# Character constants
####################################################################
Readonly::Scalar our $EMPTY => q{};
Readonly::Scalar our $SPACE => q{ };
Readonly::Scalar our $DASH  => q{-};

####################################################################
# Task definition defaults & constants
####################################################################
Readonly::Scalar our $DEFAULT_CPU_SIZE    => 256;
Readonly::Scalar our $DEFAULT_MEMORY_SIZE => 512;
Readonly::Scalar our $DEFAULT_PORT        => 80;
Readonly::Scalar our $DEFAULT_EFS_PORT    => 2049;
Readonly::Scalar our $DEFAULT_RULE_ID     => '1';
Readonly::Scalar our $IAM_POLICY_VERSION  => '2012-10-17';

Readonly::Hash our %AWS_SERVICE_DOMAINS => (
  events => 'events.amazonaws.com',
  ecs    => 'ecs-tasks.amazonaws.com',
  task   => 'ecs-tasks.amazonaws.com'
);

Readonly::Hash our %ECS_TASK_PROFILES => (
  tiny      => { cpu => 256,  memory => 512 },
  small     => { cpu => 512,  memory => 1024 },
  medium    => { cpu => 1024, memory => 2048 },
  large     => { cpu => 2048, memory => 4096 },
  xlarge    => { cpu => 4096, memory => 8192 },
  '2xlarge' => { cpu => 8192, memory => 16_384 },
);

Readonly::Hash our %ECS_TASK_PROFILE_TYPES => (
  web    => 'medium',
  job    => 'medium',
  daemon => 'medium',
  task   => 'tiny',
);

########################################################################
# Poll timeouts
########################################################################
Readonly::Scalar our $DEFAULT_ECS_POLL_TIME       => 5;
Readonly::Scalar our $DEFAULT_ECS_POLL_LIMIT      => 5 * 60 * 60;  # 5m
Readonly::Scalar our $ACM_REQUEST_SLEEP_TIME      => 5;
Readonly::Scalar our $DEFAULT_ALB_MAX_TRIES       => 120;
Readonly::Scalar our $DEFAULT_ALB_POLL_SLEEP_TIME => 5;

########################################################################
# CloudTrail defaults & constants
########################################################################
Readonly::Scalar our $DEFAULT_MAX_EVENTS => 5;

########################################################################
# Autoscaling defaults & constants
########################################################################
Readonly::Scalar our $DEFAULT_CPU_SCALING_LEVEL              => 60;
Readonly::Scalar our $DEFAULT_REQUESTS_SCALING_LEVEL         => 500;
Readonly::Scalar our $DEFAULT_AUTOSCALING_MIN_CAPACITY       => 1;
Readonly::Scalar our $DEFAULT_AUTOSCALING_MAX_CAPACITY       => 2;
Readonly::Scalar our $DEFAULT_AUTOSCALING_SCALE_OUT_COOLDOWN => 60;
Readonly::Scalar our $DEFAULT_AUTOSCALING_SCALE_IN_COOLDOWN  => 300;

########################################################################
# WAF defaults & constants
########################################################################
Readonly::Scalar our $WAF_AVAILABILITY_TIMEOUT    => 5 * 60;
Readonly::Scalar our $WAF_AVAILABILITY_SLEEP_TIME => 5;

Readonly::Hash our %WAF_MANAGED_RULES => (
  premium => [
    qw(
      AWSManagedRulesACFPRuleSet
      AWSManagedRulesATPRuleSet
      AWSManagedRulesBotControlRuleSet
    )
  ],
  base => [
    qw(
      AWSManagedRulesCommonRuleSet
      AWSManagedRulesAmazonIpReputationList
      AWSManagedRulesKnownBadInputsRuleSet
    )
  ],
  admin => [
    qw(
      AWSManagedRulesAdminProtectionRuleSet
    )
  ],
  linux => [
    qw(
      AWSManagedRulesLinuxRuleSet
      AWSManagedRulesUnixRuleSet
    )
  ],
  wordpress => [
    qw(
      AWSManagedRulesWordPressRuleSet
    )
  ],
  windows => [
    qw(
      AWSManagedRulesWindowsRuleSet
    )
  ],
  php => [
    qw(
      AWSManagedRulesPHPRuleSet
    )
  ],
  sql => [
    qw(
      AWSManagedRulesSQLiRuleSet
    )
  ],
  anonymous => [
    qw(
      AWSManagedRulesAnonymousIpList
    )
  ],
  ddos => [
    qw(
      AWSManagedRulesAntiDDoSRuleSet
    )
  ],
);

Readonly::Hash our %WAF_MANAGED_RULE_BUNDLES => (
  all             => [qw(base linux wordpress php windows sql admin)],
  default         => [qw(base sql)],
  'linux-app'     => [qw(base sql linux)],
  'wordpress-app' => [qw(base sql wordpress linux)],
  'windows-app'   => [qw(base sql windows)],
);

Readonly::Scalar our $WAF_RULE_STUB => <<'END_OF_STUB';
{
  "Name": "",
  "Priority": 0,
  "Statement":{
    "ManagedRuleGroupStatement": {
      "VendorName": "AWS",
      "Name": ""
    }
  },
  "OverrideAction": { "None": {} },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": ""
  }
}
END_OF_STUB

####################################################################
# ARN templates
####################################################################
Readonly::Scalar our $EFS_ARN_TEMPLATE             => 'arn:aws:elasticfilesystem:%s:%s:file-system/%s';
Readonly::Scalar our $TASK_DEFINITION_ARN_TEMPLATE => 'arn:aws:ecs:%s:%s:task-definition/%s:*';
Readonly::Scalar our $CLUSTER_ARN_TEMPLATE         => 'arn:aws:ecs:%s:%s:cluster/%s';
Readonly::Scalar our $ROLE_ARN_TEMPLATE            => 'arn:aws:iam::%s:role/%s';
Readonly::Scalar our $QUEUE_ARN_TEMPLATE           => 'arn:aws:sqs:%s:%s:%s';
Readonly::Scalar our $S3_BUCKET_ARN_TEMPLATE       => 'arn:aws:s3:::%s';
Readonly::Scalar our $ECR_ARN_TEMPLATE             => 'arn:aws:ecr:%s:%s:repository/%s';

########################################################################
# Health check defaults & constants
########################################################################
Readonly::Scalar our $DEFAULT_HEALTH_CHECK_INTERVAL            => 30;
Readonly::Scalar our $DEFAULT_HEALTH_CHECK_TIMEOUT             => 5;
Readonly::Scalar our $DEFAULT_HEALTH_HEALTHY_CHECK_THRESHOLD   => 5;
Readonly::Scalar our $DEFAULT_HEALTH_UNHEALTHY_CHECK_THRESHOLD => 2;

########################################################################
# SQS defaults & constants
########################################################################
Readonly::Scalar our $DEFAULT_SQS_VISIBILITY_TIMEOUT                => 30;
Readonly::Scalar our $DEFAULT_SQS_MESSAGE_RETENTION_PERIOD          => 345_600;
Readonly::Scalar our $DEFAULT_SQS_RECEIVE_MESSAGE_WAIT_TIME_SECONDS => 0;
Readonly::Scalar our $DEFAULT_SQS_DELAY_SECONDS                     => 0;
Readonly::Scalar our $DEFAULT_SQS_MAX_RECEIVE_COUNT                 => 5;
Readonly::Scalar our $DEFAULT_SQS_MAXIMUM_MESSAGE_SIZE              => 262_144;

require App::FargateStack::Builder::Utils;

Readonly::Scalar our $QUEUE_ATTRIBUTES => App::FargateStack::Builder::Utils::ToCamelCase(
  [ qw(
      delay_seconds
      last_modified_timestamp
      max_receive_count
      maximum_message_size
      message_retention_period
      receive_message_wait_time_seconds
      redrive_policy
      visibility_timeout
    )
  ],
);

########################################################################
# CloudWatch Logs defaults & constants
########################################################################
Readonly::Scalar our $CLOUDWATCH_LOGS_RETENTION_DAYS =>
  [ 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, ];
Readonly::Scalar our $DEFAULT_LOG_RETENTION_DAYS => 14;
Readonly::Scalar our $DEFAULT_LOG_POLL_TIME      => 5;

########################################################################
# Time defaults & constants
########################################################################
Readonly::Scalar our $SEC_PER_MIN  => 60;
Readonly::Scalar our $SEC_PER_HOUR => 60 * $SEC_PER_MIN;
Readonly::Scalar our $SEC_PER_DAY  => 24 * $SEC_PER_HOUR;

########################################################################
# Default name functions
# (see App::FargateStack::Builder::Utils::create_default)
########################################################################
Readonly::Hash our %DEFAULT_NAMES => (
  'autoscaling-policy-name' => sub {
    my ( $self, $task_name ) = @_;

    my $app_name = $self->get_config->{app}->{name};

    return sprintf 'app-fargatestack-%s-%s-autoscaling-policy', $app_name, $task_name;
  },
  'security-group' => sub {
    my ( $self, @args ) = @_;

    return sprintf '%s-sg', $self->get_config->{app}->{name};
  },
  'log-group' => sub {
    my ( $self, @args ) = @_;

    return sprintf '/ecs/app-fargatestack/%s', $self->get_config->{app}->{name};
  },
  'role-name' => sub {
    my ( $self, $type ) = @_;

    my $app_name = $self->normalize_name( $self->get_config->{app}->{name} );

    my @args = choose {
      return ( 'Events', $app_name, $EMPTY )
        if $type eq 'events';

      return ( 'Fargate', $app_name, $EMPTY )
        if $type eq 'ecs';

      return ( 'Fargate', $app_name, 'Task' )
        if $type eq 'task';
    };

    # Ex: FargateSqsExampleTaskRole'
    return sprintf '%s%s%sRole', @args;
  },
  'policy-name' => sub {
    my ( $self, $type ) = @_;

    my $app_name = $self->normalize_name( $self->get_config->{app}->{name} );

    my @args = choose {
      return ( 'Events', $app_name, $EMPTY )
        if $type eq 'events';

      return ( 'Fargate', $app_name, $EMPTY )
        if $type eq 'ecs';

      return ( 'Fargate', $app_name, 'Task' )
        if $type eq 'task';
    };

    # Ex: FargateSqsExampleTaskPolicy'
    return sprintf '%s%s%sPolicy', @args;
  },
  'rule-id' => sub {
    my ( $self, $task_name ) = @_;

    return sprintf '%s-target', $task_name;
  },
  'rule-name' => sub {
    my ( $self, $task_name ) = @_;

    return sprintf '%s-schedule', $task_name;
  },
  'target-group-name' => sub {
    my ($self) = @_;

    my $app_name = $self->get_config->{app}->{name};
    return sprintf '%s-tg', $app_name;
  },
  'cluster-name' => sub {
    my ($self) = @_;

    my $app_name = $self->get_config->{app}->{name};

    return sprintf '%s-cluster', $app_name;
  },
  'alb-name' => sub {
    my ($self) = @_;

    my $app_name = $self->get_config->{app}->{name};

    return sprintf '%s-alb', $app_name;
  },
  'alb-security-group-name' => sub {
    my ($self) = @_;

    my $app_name = $self->get_config->{app}->{name};

    return sprintf '%s-alb-sg', $app_name;
  },
  'scheduled-action-name' => sub {
    my ( $self, $action_name ) = @_;

    my $app_name = $self->get_config->{app}->{name};

    return sprintf '%s-%s-schedule', $app_name, $action_name;
  },

  'web-acl-name' => sub {
    my ($self) = @_;

    my $app_name = $self->get_config->{app}->{name};
    return sprintf '%s-acl', $app_name;
  },
);

########################################################################
# EventBridge defaults & constants
########################################################################
Readonly::Scalar our $EVENT_SCHEDULER_TYPE_URL => 'https://docs.aws.amazon.com/scheduler/latest/UserGuide/schedule-types.html';

########################################################################
# Help subjects
########################################################################
Readonly::Hash our %HELP_SUBJECTS => (
  'tbd' => [
    'TBD' => <<'END_OF_TEXT'
Our current TODO list. Add your request at
https://github.com/rlauer6/App-Fargate
END_OF_TEXT
  ],
  'overview' => [
    'OVERVIEW' => <<'END_OF_TEXT'
An overview of the App::FargateStack framework.
END_OF_TEXT
  ],
  'cloudwatch logs' => [
    'CLOUDWATCH LOGS' => <<'END_OF_TEXT'
Information on Cloudwatch log groups and how to view logs from your tasks.
END_OF_TEXT
  ],
  'command list' => [
    'COMMAND LIST' => <<'END_OF_TEXT'
A detailed description of available commands.
END_OF_TEXT
  ],
  'daemon services' => [
    'DAEMON SERVICES' => <<'END_OF_TEXT'
Information on how to create long running daemon services using this
framework.
END_OF_TEXT
  ],
  'scheduled jobs' => [
    'SCHEDULED JOBS' => <<'END_OF_TEXT'
A description of using the framework to create scheduled and one-shot workloads.
END_OF_TEXT
  ],
  'task size' => [
    'TASK SIZE' => <<'END_OF_TEXT'
Using the "size:" key to set the task's memory and cpu parameters.
END_OF_TEXT
  ],
  'http services' => [
    'HTTP SERVICES' => <<'END_OF_TEXT'
A description of how the framework can provision a fully functional
web application using Fargate.
END_OF_TEXT
  ],

  'log groups' => [
    'CLOUDWATCH LOG GROUPS' => <<'END_OF_TEXT'
Information on how log groups are provisioned and configure.
END_OF_TEXT
  ],
  'iam permissions' => [
    'IAM PERMISSIONS' => <<'END_OF_TEXT'
A discussion of how the framework creates IAM roles and policies for
the resources used in your tasks.
END_OF_TEXT
  ],
  'environment variables' => [
    'ENVIRONMENT VARIABLES' => <<'END_OF_TEXT'
How to injecting environment variables into your container. Also
include information on using secrets fromSecretsManager in your
environment.
END_OF_TEXT
  ],
  'queues' => [
    'SQS QUEUES' => <<'END_OF_TEXT'
How to create and configure SQS queues for your application.
END_OF_TEXT
  ],
  'efs support' => [
    'FILESYSTEM SUPPORT' => <<'END_OF_TEXT'
Configuring support for EFS files systems inside your container.
END_OF_TEXT
  ],
  'filesystem support' => 'efs support',
  'buckets'            => [
    'S3 BUCKETS' => <<'END_OF_TEXT'
Creating and configuring S3 buckets.
END_OF_TEXT
  ],
  'networking' => [
    'NETWORKING' => <<'END_OF_TEXT'
Explanation of how the framework recognizes and uses your networking
resources.
END_OF_TEXT
  ],
  'roadmap' => [
    'ROADMAP' => <<'END_OF_TEXT'
A peek at what's next for App::FargateStack.
END_OF_TEXT
  ],
  'cli option defaults' => [
    'CLI OPTION DEFAULTS' => <<'END_OF_TEXT'
Save keystrokes with App::Fargate's automatic option saving feature.
END_OF_TEXT
  ],
  'configuration file' => [
    'CONFIGURATION' => <<'END_OF_TEXT'
Detailed explanation of the App::Fargate configuration file.
END_OF_TEXT
  ],
  'limitations' => [
    'LIMITATIONS' => <<'END_OF_TEXT'
END_OF_TEXT
  ],
  'troubleshooting' => [
    'TROUBLESHOOTING' => <<'END_OF_TEXT'
Hints and tips for troubleshooting.
END_OF_TEXT
  ],
  'security groups' => [
    'SECURITY GROUPS' => <<'END_OF_TEXT'
How the framework provisions and configures security groups.
END_OF_TEXT
  ],
);

Readonly::Scalar our $LOG4PERL_CONF => <<'END_OF_CONF';
log4perl.logger = INFO, Screen
log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.stderr = 1
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = [%d] %m%n
log4perl.appender.Screen.color.DEBUG=magenta
log4perl.appender.Screen.color.INFO=green
log4perl.appender.Screen.color.WARN=yellow
log4perl.appender.Screen.color.ERROR=red
log4perl.appender.Screen.color.FATAL=bold red
log4perl.appender.Screen.color.TRACE=bold white
END_OF_CONF

our @EXPORT = (
  ######################################################################
  # chars
  ######################################################################
  qw(
    $EMPTY
    $DASH
    $SPACE
  ),
  ######################################################################
  # booleans
  ######################################################################
  qw(
    $FALSE
    $TRUE
  ),
  ######################################################################
  # CloudTrail
  ######################################################################
  qw(
    $DEFAULT_MAX_EVENTS
  ),
  ######################################################################
  # EFS
  ######################################################################
  qw(
    $DEFAULT_EFS_PORT
  ),
  ######################################################################
  # EventBridge
  ######################################################################
  qw(
    $DEFAULT_RULE_ID
    $EVENT_SCHEDULER_TYPE_URL
  ),
  ######################################################################
  # Miscellaneous
  ######################################################################
  qw(
    %DEFAULT_NAMES
  ),
  ######################################################################
  # Log4perl
  ######################################################################
  qw(
    $LOG4PERL_CONF
  ),
  ######################################################################
  # Help
  ######################################################################
  qw(
    %HELP_SUBJECTS
  ),
  ######################################################################
  # Poll timeouts
  ######################################################################
  qw(
    $ACM_REQUEST_SLEEP_TIME
    $DEFAULT_ALB_MAX_TRIES
    $DEFAULT_ALB_POLL_SLEEP_TIME
    $DEFAULT_ECS_POLL_LIMIT
    $DEFAULT_ECS_POLL_TIME
  ),
  ######################################################################
  # Task definition defaults
  ######################################################################
  qw(
    $DEFAULT_CPU_SIZE
    $DEFAULT_MEMORY_SIZE
    $DEFAULT_PORT
    $IAM_POLICY_VERSION
    %AWS_SERVICE_DOMAINS
    %ECS_TASK_PROFILES
    %ECS_TASK_PROFILE_TYPES
  ),
  ######################################################################
  # CloudWatch Logs
  ######################################################################
  qw(
    $CLOUDWATCH_LOGS_RETENTION_DAYS
    $DEFAULT_LOG_POLL_TIME
    $DEFAULT_LOG_RETENTION_DAYS
  ),
  ######################################################################
  # WAF
  ######################################################################
  qw(
    $WAF_AVAILABILITY_SLEEP_TIME
    $WAF_AVAILABILITY_TIMEOUT
    $WAF_RULE_STUB
    %WAF_MANAGED_RULES
    %WAF_MANAGED_RULE_BUNDLES
  ),
  ######################################################################
  # Health Checks
  ######################################################################
  qw(
    $DEFAULT_HEALTH_CHECK_INTERVAL
    $DEFAULT_HEALTH_CHECK_TIMEOUT
    $DEFAULT_HEALTH_HEALTHY_CHECK_THRESHOLD
    $DEFAULT_HEALTH_UNHEALTHY_CHECK_THRESHOLD
  ),
  ######################################################################
  # SQS
  ######################################################################
  qw(
    $DEFAULT_SQS_DELAY_SECONDS
    $DEFAULT_SQS_MAXIMUM_MESSAGE_SIZE
    $DEFAULT_SQS_MAX_RECEIVE_COUNT
    $DEFAULT_SQS_MESSAGE_RETENTION_PERIOD
    $DEFAULT_SQS_RECEIVE_MESSAGE_WAIT_TIME_SECONDS
    $DEFAULT_SQS_VISIBILITY_TIMEOUT
    $QUEUE_ATTRIBUTES
  ),
  ######################################################################
  # Time defaults
  ######################################################################
  qw(
    $SEC_PER_DAY
    $SEC_PER_HOUR
    $SEC_PER_MIN
  ),
  ######################################################################
  # Autoscaling
  ######################################################################
  qw(
    $DEFAULT_AUTOSCALING_MAX_CAPACITY
    $DEFAULT_AUTOSCALING_MIN_CAPACITY
    $DEFAULT_AUTOSCALING_SCALE_IN_COOLDOWN
    $DEFAULT_AUTOSCALING_SCALE_OUT_COOLDOWN
    $DEFAULT_CPU_SCALING_LEVEL
    $DEFAULT_REQUESTS_SCALING_LEVEL
  ),
  ######################################################################
  # Templates
  ######################################################################
  qw(
    $CLUSTER_ARN_TEMPLATE
    $ECR_ARN_TEMPLATE
    $EFS_ARN_TEMPLATE
    $QUEUE_ARN_TEMPLATE
    $ROLE_ARN_TEMPLATE
    $S3_BUCKET_ARN_TEMPLATE
    $TASK_DEFINITION_ARN_TEMPLATE
  ),
);

1;

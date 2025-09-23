package App::FargateStack::Pod;
# just pod maam...

use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

App::FargateStack

=head1 SYNOPSIS

 # Dry-run and analyze the configuration
 app-FargateStack plan -c my-stack.yml

 # Provision the full stack
 app-FargateStack apply -c my-stack.yml

=head1 DESCRIPTION

B<App::FargateStack> is a lightweight deployment framework for Amazon
ECS on Fargate.  It enables you to define and launch containerized
services with minimal AWS-specific knowledge and virtually no
boilerplate. Designed to simplify cloud infrastructure without
sacrificing flexibility, the framework lets you declaratively specify
tasks, IAM roles, log groups, secrets, and networking in a concise
YAML configuration.

By automating the orchestration of ALBs, security groups, EFS mounts,
CloudWatch logs, and scheduled or daemon tasks, B<App::FargateStack>
reduces the friction of getting secure, production-grade workloads
running in AWS. You supply a config file, and the tool intelligently
discovers or provisions required resources.

It supports common service types such as HTTP, HTTPS, daemon, and cron
tasks, and handles resource scoping, role-based access, and health
checks behind the scenes.  It assumes a reasonable AWS account layout
and defaults, but gives you escape hatches where needed.

B<App::FargateStack> is ideal for developers who want the power of ECS
and Fargate without diving into the deep end of Terraform,
CloudFormation, or the AWS Console.

=head2 Current Status of App::FargateStack

I<This is a work in progress.> Versions prior to 1.1.0 are considered usable
but may still contain issues related to edge cases or uncommon configuration
combinations.

This documentation corresponds to version 1.0.50.

The release of version I<1.1.0> will mark the first production-ready release.
Until then, you're encouraged to try it out and provide feedback. Issues or
feature requests can be submitted via
L<GitHub|https://github.com/rlauer6/App-FargateStack/issues>.

=head2 Caveats

=over 4

=item * The documentation may be incomplete or inaccurate.

=item * Features may change, and new ones will be added. See the
L</ROADMAP> for details.

=item * Deploying resources using this framework may result in AWS charges.

=item * This software is provided "as is", without warranty of any kind.
Use at your own risk.

=back

=head2 Features

=over 4

=item *

Minimal configuration: launch a Fargate service with just a task name
and container image

=item *

Supports multiple task types: HTTP, HTTPS, daemon, cron (scheduled)

=item *

Automatic resource provisioning: IAM roles, log groups, target groups,
listeners, etc.

=item *

Discovers and reuses existing AWS resources when available (e.g.,
VPCs, subnets, ALBs)

=item *

Secret injection from AWS Secrets Manager

=item *

CloudWatch log integration with configurable retention

=item *

Optional EFS volume support (per-task configuration)

=item *

Public or private service deployment (via ALB in public subnet or
internal-only)

=item *

Built-in service health check integration

=item *

Automatic IAM role and policy generation based on configured resources

=item *

Optional HTTPS support with ACM certificate discovery and creation

=item * 

Optional support for adding AWS WAF support for your HTTPS site

=item *

Lightweight dependency stack: Perl, AWS CLI, a few CPAN modules

=item *

Convenient CLI: start, stop, update, and tail logs for any service

=item *

Scheduled and metric based autoscaling

=back

=head1 METHODS AND SUBROUTINES

This class is implemented as a modulino and is not designed for traditional 
object-oriented use. As such, this section is intentionally omitted.

=head1 USAGE

=head2 Commands

 Command                   Arguments                    Description
 -------                   ---------                    -----------
 add-scaling-policy        See Note 12                  adds an autoscaling policy to the configuration
 add-schedule-action       See Note 13                  adds a scheduled scaling action
 apply                                                  reads config and creates resources
 create-stack              app-name service-clauses...  creates a new stack configuration
 delete-scaling-policy     task-name                    deletes the autoscaling policy for a task from your configuration
 delete-scheduled-action   action-name                  deletes a named scheduled action from your configuration
 delete-service            task-name                    alias for remove-service
 delete-task               task-name                    deletes all resources associated with a task (See Note 11)
 delete-autoscaling-policy task-name                    deletes a metric based scaling policy for the task
 delete-scheduled-action   action-name                  deletes an existing autoscaling scheduled action
 delete-scheduled-task     task-name                    deletes all resources associated with a scheduled task (See Note 11)
 delete-daemon             task-name                    deletes all resources associated with a daemon  (See Note 11)
 delete-http-service       task-name                    deletes all resources associated with a http service  (See Note 11)
 deploy-service            task-name                    create a new service (see Note 4)
 destroy                                                removes all resources in your stack that were provisioned by App::FargateStack
 disable-scheduled-task    task-name                    disable a scheduled task
 enable-scheduled-task t   ask-name                     enable a scheduled task
 help                      [subject]                    displays general help or help on a particular subject (see Note 2)
 list-tasks                                             list running or stopped tasks
 list-zones                domain                       list the hosted zones for a domain
 logs                      task-name start end          display CloudWatch logs (see Note 5)
 plan                                                  reads config and reports on resource creation
 register-task-definition  task-name                    creates a new task definition revision
 remove-service            task-name                    removes an existing service but does not delete the task
 run-task                  task-name                    launches an adhoc task
 show                      command args                 output additional info about the stack or run states
  cloudtrail-events task-name start-time [end-time]  show cloudtrail events for a scheduled task (useful for debugging)
  stack                                                shows a summary of the stack configuration
 start-service             task-name [count]            starts a service
 status                    task-name                    provides the current status for a task
 stop-service              task-name                    stops a running service
 tasks                                                  displays a summary of all tasks in your stack
 update-policy                                          updates the ECS policy in the event of resource changes
 update-target             task-name                    force update of target definition
 version                                                display the current version number

=head2 Options

 -h, --help                 help
 --cache, --no-cache        use the configuration file as the source of truth (see Note 8)
 -c, --config               path to the .yml configuration
 -C, --create-alb           forces creation of a new ALB, prevents use of an existing ALB
 --color, --no-color        default: color
 --confirm-all              confirm deletion of all resources
 -d, --dryrun               just report actions, do not apply
 --dns-profile              alias for --route53-profile
 -f, --force                force action (depends on context)
 --history, --no-history    save cli parameters to .fargatestack/defaults.json
 --log-level                'trace', 'debug', 'info', 'warn', 'error', default: info (See Note 6)
 --log-time, --no-log-time  for logs command, output CloudWatch timestamp (default: --no-log-time)
 --log-wait, --no-log-wait  for logs command, continue to monitor logs (default: --log-wait)
 --log-poll-time            amount of time in seconds to sleep between requesting new log events
 --max-events, -m           maximum number of events to show for status command (default: 5)
 --output                   output type for some commands, valid values: text|json
 -p, --profile              AWS profile (see Note 1)
 --purge-config             remove deleted tasks from multi-task configs
 --route53-profile          set this if your Route 53 zones are in a different account (See Note 10)
 -s, --skip-register        skips registering a new task definition when using update-target (See Note 7)
 -u, --update, --no-update  update config (See Note 9)
 -U, --unlink, --no-unlink  delete or keep temp files (default: --unlink)
 -w, --wait, --no-wait      wait for tasks to complete and then dump the log (applies to adhoc tasks)
 -v, --version              script version

=head2 Notes

=over 4

=item (1) Use the C<--profile> option to override the profile defined in
the configuration file.

I<Note: The Route 53 service uses the same profile unless you specify
C<--route53-profile> or set a profile name in the C<route53> section
of the configuration file.>

=item (2) You can get help using the C<--help> option or use the help
command with a subject or one of the commands.

 app-FargateStack help overview
 app-FargateStack help redeploy

If you do not provide a subject then you will get the same information
as C<--help>. Use C<help help> to get a list of available subjects.

=item (3) You must log at least at the 'info' level to report
progress. This is set for you when your C<plan> or C<apply>.

=item (4) By default an ECS service is NOT created for you by default
for daemon and http tasks. Instead, after creating all of the
necessary resources using C<apply>, run C<app-FargateStack
deploy-service task-name>. This will launch your service with a count
of 1 task. You can optionally specify a different count after the task
name.

=item (5) You can tail or display a set of log events from a task's
log stream:

 app-Fargate logs [--log-wait] [--log-time] start end

=over 8

=item --log-wait --no-log-wait (optional)

Continue to monitor stream and dump logs to STDOUT

default: --log-wait

=item --log-time, --no-log-time (optional)

Output the CloudWatch timestamp of the message.

default: --log-time

=item task-name

The name of the task whose logs you want to view.

=item start

Starting date and optionally time of the log events to display. Format can be one
of:

 Nd => N days ago
 Nm => N minutes ago
 Nh => N hours ago

 mm/dd/yyyy
 mm/dd/yyyy hh:mm::ss

=item end

If provided both start and end must date-time strings.

=back

=item (6) The default log level is 'info' which will create an audit
trail of resource provisioning. Certain commands log at the 'error'
level to reduce console noise. Logging at lower levels will prevent
potential useful messages from being displayed. To see the AWS CLI
commands being executed, log at the 'debug' level. The 'trace' level
will output the result of the AWS CLI commands.

=item (7) Use C<--skip-register> if you want to update a tasks target
rule without registering a new task definition. This is typically done
if for some reason your target rule is out of sync with your task
definition version.

=item (8) To speed up processing and avoid unnecessary API calls the
framework considers the configuration file the source of truth and a
reliable representation of the state of the stack. If you want to
re-sync the configuration file set C<--no-cache> and run C<plan>. In
most cases this should not be necessary as the framework will
invalidate the configuration if an error occurs forcing a re-sync on
the next run of C<plan> or C<apply>.

=item (9) C<--no-update> is not permitted with C<apply>. If you need a
dry plan without applying or updating the config, use C<--dryrun> (and
optionally C<--no-update>) with C<plan>.

=item (10) Set C<--route53-profile> to the profile that has
permissions to manage your hosted zones. By default the script will
use the default profile.

=item (11) Deleting a task, daemon, or http service will delete all of
the resources associated with that task.

=over 4

=item * For scheduled tasks you can disable the job from running instead of
deleting its resources.

=item * For services (daemons or HTTP services) you
can stop them or delete the service (C<delete-service>) instead of
deleting all of the resources. 

=item * These resources will B<NOT> be removed:

 - ECR image associated with a task
 - An ACM certificate provisioned by App::FargateStack

=back

=item (12) This command will add a scaling policy to an HTTP, HTTPS or
daemon task. In order to apply the policy you must run C<plan> &
C<apply>. You provide the following arguments in order:

 [task-name] metric-type metric-value [min-capacity max-capacity [scale-out-cooldown scale-in-cooldown]]

=over 4

=item * C<task-name> is optional if you only have 1 scalable task.

=item * C<min-capacity>, C<max-capacity> are optional and will default to 1 and 2 respectively.

=item * C<scale-out-cooldown>, C<scale-in-cooldown> are optional. If
you provided you must include the capacity paramters.

 app-FargateStack apache requests 500 2 3 60 300

=back

=item (13) This command will add a schedule scaling action to your
configuration. In order to activate the schedule you must run C<plan>
and C<apply>. You provide the following arguments in order:

 [task-name] action-name start-time end-time days scale-out-capacity scale-in-capacity

=over 4

=item * C<task-name> is optional if you only have 1 scalable task.

=item * C<action-name> is a name for your schedule. It must be
unique within your entire configuration.

=item C<start-time> is UTC. The format for the staring time is
MM::HH. (Example: 00:18)

=item C<days> is the day or days of the week for the scheduled action.

I<Note: Days should be one of MON,TUE,WED,THU,FRI,SAT or 1-7>

Example:

Scale out to 4 tasks at 10pm (EDT) for 30 minutes to run a batch job
on Friday night.

 00:02 30:02 SAT 4/1 4/1

I<Note that the cron specification is in UTC, hence we run at 2am for
30 minutes on Saturday morning in UTC.>

=item C<end-time> time t scale back in. Same format as C<start-time>

=item C<scale-out-capacity>, C<scale-in-capacity> - These options
represent the scale out and scale in capacities.

Each value should be a tuple separated by '/', ',', ':' or '-'. The
first value represents the minimum or maximum capacity for scaling out
or in at the specified starting time of schedule action. The second
value represents the minimum or maximum capacity for scaling in or out
at the ending time of the action.

Example to scale out to 2 tasks during business hours of 8:30am and
5:30pm and scale in to 1 task during non-business hours.

 app-FargateStack add-scheduled-action business_hours 30:12 30:21 MON-FRI 2/1 2/1

If you had a scaling policy, your scaling policies C<max_capacity>
must be greater than or equal to the largest maximum capacity of your
all of you scheduled actions for that task.

 app-FargateStack add-scheduled-action business_hours 30:12 30:21 2/1 4/1

In this case, your scaling policy C<max_capacity> value must be at least
4.

=back

=back

=head1 OVERVIEW

I<NOTE: This is a brief introduction to C<App::FargateStack>. To see a 
list of topics providing more detail use the C<help help> command.>

The C<App::FargateStack> framework, as its name implies provides
developers with a tool to create Fargate tasks and services. It has
been designed to make creating and launching Fargate based services as
simple as possible. Accordingly, it provides logical and pragmatic
defaults based on the common uses for Fargate based applications. You
can however customize many of the resources being built by the script.

Using a YAML based configuration file, you specify your required
resources and their attributes, run the C<app-FargateStack> script and
launch your application.

Using this framework you can:

=over 4

=item * ...build internal or external facing HTTP services that:

=over 8

=item * ...automatically provision certificates for external facing web applications

=item * ...use an existing or create a new internal or external facing application load balancer (ALB).

=item * ...automatically create an alias record in Route 53 for your domain

=item * ...create a listener rule to redirect port 80 requests to 443 

=back

=item * ...create queues and buckets to support your application

=item * ...use a dryrun mode to report the resources that will be built
before building them

=item * ...run C<app-FargateStack> multiple times (idempotency)

=item * ...create daemon services

=item * ...create scheduled jobs

=item * ...execute adhoc jobs

=back

=head2 Additional Features

=over 4

=item inject secrets into the container's environment using a simple
syntax (See L</INJECTING SECRETS FROM SECRETS MANAGER>)

=item detection and re-use of existing resources like EFS files systems, load balancers, buckets and queues

=item automatic IAM role and policy generation based on configured resources

=item define and launch multiple independent Fargate tasks and services under a single stack

=item automatic creation of log groups with customizable retention period

=item discovery of existing environment to intelligently populate configuration defaults

=item automatically create a minimal Fargate app/service config from shorthand

=item support for scheduled and metric based L<autoscaling|/"AUTOSCALING">

=back

=head2 Minimal Configuration

Getting a Fargate task up and running requires that you provision and
configure multiple AWS resources. Stitching it together using
B<Terraform> or B<CloudFormation> can be tedious and time consuming,
even if you know what resources to provision AND how to stitch it
together.

The motivation behind writing this framework was to take the drudgery
of writing declarative resource generators for all of the resources required
to run a simple task, create basic web applications or RESTful
APIs. Instead, we wanted a framework that covered 90% of our use cases
while allowing our development workflow to go something like:

=over 4

=item Create a Docker image that implements our worker, web app or API

=item Create a minimal configuration file that describes our application

=item Execute the framework's script and create the necessary AWS infrastructure

=item Launch the http server, daemon, scheduled job, or adhoc worker

=back

Of course, this is only a "good idea" if creating the initial
configuration file is truly minimal, otherwise it becomes an exercise
similar to using Terraform or CloudFormation. So what is the minimum
amount of configuration to inform our framework so it can create our
Fargate worker? How's this for minimal?

 ---
 app:
   name: my-stack
 tasks:
   my-worker:
     type: task
     image: my-worker:latest
     schedule: cron(50 12 * * * *)

I<TIP: You can use the L</create-stack> command to create minimal
configuration files for various Fargate application scenarios.>

Using this minimal configuration and running C<app-FargateStack> like this:

 app-FargateStack plan

...the framework would create the following resources in your VPC:

=over 8

=item * a cluster named C<my-stack-cluster>

=item * a security group for the cluster

=item * an IAM role for the the cluster

=item * an IAM  policy that has permissions enabling your worker

=item * an ECS task definition that describes your task

=item * a CloudWatch log group

=item * an EventBridge target event

=item * an IAM role for EventBridge

=item * an IAM policy for EventBridge

=item * an EventBridge rule that schedules the worker

=back

...so as you can see, rolling all of this by hand could be a daunting
task and one made even more difficult when you decide to use other AWS
resources inside your task like buckets, queues or an EFS file
systems!

=head2 Web Applications

Creating a web application using a minimal configuration works too. To
build a web application you can start with this minimal configuration:

 ---
 app:
   name: my-web-app
 domain: my-web-app.example.com
 tasks:
   apache:
     type: https
     image: my-web-app:latest

This will create an externally facing web application for you with
these resources:

=over 4

=item *  A certificate for your domain

=item * A Fargate cluster

=item * IAM roles and policies

=item * A listener and listener rules

=item * A CloudWatch log group

=item * Security groups

=item * A target group

=item * A task definition

=item * An ALB if one is not detected

=back

Once again, launching a Fargate service requires a
lot of fiddling with AWS resources! Getting all of the plumbing
installed and working requires a lot of what and how knowledge.

=head2 Adding or Changing Resources

Adding or updating resources for an existing application should also
be easy. Updating the infrastructure should just be a matter of
updating the configuration and re-running the framework's script. When
you update the configuration the C<App::FargateStack> will detect the
changes and update the necessary resources.

Currently the framework supports adding a single SQS queue, a single
S3 bucket, volumes using EFS mount points, environment variables and
secrets from AWS Secrets Manager.

 my-worker:
   image: my-worker:latest
   command: /usr/local/bin/my-worker.pl
   type: task
   schedule: cron(00 15 * * * *)   
   bucket:
     name: my-worker-bucket
   queue:
     name: my-worker-queue
   environment:
     ENVIRONMENT=prod
   secrets:
     db_password:DB_PASSWORD
   efs:
     id: fs-abcde12355
     path: /
     mount_point: /mnt/my-worker

Adding new resources would normally require you to update your
policies to allow your worker to access these resource. However, the
framework automatically detects that the policy needs to be updated
when new resources are added (even secrets) and takes care of that for
you.

See C<app-Fargate help configuration> for more information about
resources and options.

=head2 Configuration as State

The framework attempts to be as transparent as possible regarding what
it is doing, how long it takes, what the result was and most
importantly I<what defaults were used during resource
provisioning>. Every time the framework is run, the configuration file
is updated based on any new resources provisioned or configured.  For
example, if you did not specify subnets, they are inferred by
inspecting your VPC and automatically added to the configuration file.

This gives you a single view into your Fargate application

=head1 CLI OPTION DEFAULTS

When enabled, C<App::FargateStack> automatically remembers the most recently
used values for several CLI options between runs. This feature helps streamline
repetitive workflows by eliminating the need to re-specify common arguments
such as the AWS profile, region, or config file.

The following options are tracked and persisted:

=over 4

=item * C<--profile>

=item * C<--region>

=item * C<--config>

=item * C<--route53-profile>

=item * C<--max-events>

=back

These values are stored in F<.fargatestack/defaults.json> within your current
project directory. If you omit any of these options on subsequent runs, the
most recently used value will be reused.

Typically, you would create a dedicated project directory for your
stack and place your configuration file there. Once you invoke a
command that includes any of the tracked CLI options, the
F<.fargatestack/defaults.json> file will be created
automatically. Future commands run from that directory can then omit
those options. A typical workflow to create a new stack with a
scheduled job might look like this:

 mkdir my-project
 cd my-project
 app-FargateStack create-stack foo task:my-cron image:my-project 'schedule:cron(0 10 * * * *)'
 app-FargateStack plan
 app-FargateStack apply

That's it...you just created a scheduled job that will run at 10 AM every day!

=head2 Disabling and Resetting

Use the C<--no-history> option to temporarily disable this feature for a single
run. This allows you to override stored values without modifying or deleting
them.

To clear all saved defaults entirely, use the C<reset-history> command. This
removes all of the tracked values from the F<.fargatestack/defaults.json> file,
but preserves the file itself.

=head2 Notes

Only explicitly provided CLI options are tracked. Values derived from
environment variables or configuration files are not saved.

This feature is enabled by default.

=head1 COMMAND LIST

The basic syntax of the framework's CLI is:

 app-FargateStack command --config fargate-stack.yml [options] command-args

You must provide at least a command.

=head2 Configuration File Naming

Your configuration file can be named anything, but by convention your
configuration file should have a F<.yml> extension. If you don't
provide a configuration filename the default configuration file
F<fargate-stack.yml> will be used. You can also set the
C<FARGATE_STACK_CONFIG> environment variable to the name of your
configuration file.

=head2 Command Logging

=over 4

=item Commands will generally produce log output at the default level
(C<info>). You can see what AWS commands are being executed using the
C<debug> level. If you'd like see the results of the AWS CLI commands use the
C<trace> level.

=item Commands that are expected to produce informational output
(e.g. C<status>, C<logs>, C<list-tasks>, C<list-zone>, etc) will log
at the C<error> level which will eliminate log noise on the console.

=item Logs are written to STDERR.

=item The default is to colorize log
messages. Use C<--no-color> if you don't like color.

=back

=head2 Command Descriptions

=head3 help

 help [subject]

Displays basic usage or help on a particular subject. To see a list of
help subject use C<help help>. The script will attemp to do a regexp
match if you do provide the exact help topic, so you can cheat and use
shortened versions of the topic.

 help cloudwatch

=head3 add-autoscaling-policy

=head3 add-scaling-policy

This command will add a scaling policy to an HTTP, HTTPS or
daemon task. In order to apply the policy you must run C<plan> &
C<apply>. You provide the following arguments in order:

 [task-name] metric-type metric-value [min-capacity max-capacity [scale-out-cooldown scale-in-cooldown]]

Example:

 app-FargateStack add-scaling-policy cpu 60 1 3

=over 4

=item task-name

The task in your configuration that will contain the new scaling
policy. This is optional if you only have 1 scalable task.

=item metric-type (required)

One of C<cpu> or C<requests>

=item metric-value (required)

The metric value. For C<cpu> it should be an integer between 1 and
100. For C<requests> it should be a count representing the number of
requests your ALB receives per minute.

=item min-capacity

The minimum number of tasks to maintain.

default: 1

=item max-capacity

The maximum number of tasks to scale up.

default: 2

=item scale-out-cooldown

The number of seconds to wait before scaling up another task.

default: 60

=item scale-in-cooldown

The number of seconds to wait until scaling down a task.

default: 300 (5 minutes)

=back

=head3 add-scheduled-action

This command will add a schedule scaling action to your
configuration. In order to activate the schedule you must run C<plan>
and C<apply>. You provide the following arguments in order:

 [task-name] action-name start-time end-time days scale-out-capacity scale-in-capacity

=over 4

=item task-name (optional)

The task in your configuration that will contain the new scheduled action configuration.
This is optional if you only have 1 scalable task.

=item action-name

C<action-name> is a name for your schedule. It must be
unique within your entire configuration.

=item start-time

The starting time of the scheduled action as MM::HH (UTC).

 Example: 00:18

=item end-time

The time to scale back in. Same format as C<start-time>.

=item days

The the day or days of the week for the scheduled action.

I<Note: Days should be one of MON,TUE,WED,THU,FRI,SAT or 1-7>

Example 1:

Scale out to 4 tasks at 10pm (EDT) for 30 minutes to run a batch job
on Friday night.

 00:02 30:02 SAT 4/1 4/1

I<Note that the cron specification is in UTC, hence we run at 2am for
30 minutes on Saturday morning in UTC.>

=item scale-out-capacity

=item scale-in-capacity

These options represent the scale out and scale in capacities.

Each value should be a tuple separated by '/', ',', ':' or '-'. The
first value represents the minimum or maximum capacity for scaling out
or in at the specified starting time of schedule action. The second
value represents the minimum or maximum capacity for scaling in or out
at the ending time of the action.

B<Example 1:>

To scale out to 2 tasks during business hours of 8:30am and 5:30pm and
scale in to 1 task during non-business hours (with no metric based
scaling policy):

 app-FargateStack add-scheduled-action business_hours 30:12 30:21 2/1 2/1

I<Note that without a scaling policy your minimum and maximum
capacities for scaling in and out must be equal.>

B<Example 2:>

If your task includes a scaling policy, your scaling policy's C<max_capacity>
must be greater than or equal to the largest maximum capacity of your
scheduled action.

 app-FargateStack add-scheduled-action business_hours 30:12 30:21 2/1 3/1

In this case, your scaling policy C<max_capacity> value must be at least
4. You C<autoscaling:> section will look like this:

 tasks:
   apache:
     type: https
     autoscaling:
       min_capacity: 1
       max_capacity: 3
       requests: 1000
       scale_in_cooldown: 300
       scale_out_cooldown: 60
       scheduled:
         business_hours:
           start_time: 30:12
           end_time: 21:30
           min_capacity: 2/1
           max_capacity: 3/1

=back

B<Note:>

I<Scheduled actions are only for HTTP, HTTPS and daemon tasks. If you
need to run a one-shot job at a particular time use a L<scheduled
task|/SCHEDULED JOBS>.>

=head3 apply

Reads the configuration file and determines what actions to perform
and what resources will be built.  Builds resources incrementally and
updates configuration file with resource details.

=head3 create-stack

 create-stack app-name service-clauses...

Parses a compact, positional CLI grammar and emits a ready-to-edit YAML
configuration for your Fargate framework. The command B<does not> create any
AWS resources; it only synthesizes a configuration based on the clauses you pass.

Examples:

  # One task service
  app-fargate create-stack foo task:job image:myrepo:1.2.3

  # HTTP service (ALB) + image
  app-fargate create-stack foo http:web image:site:2025-08-14 domain:api.example.com

  # HTTPS service (ALB + ACM; config only, no deploy)
  app-fargate create-stack foo https:web image:site:stable domain:api.example.com

  # Scheduled task (EventBridge schedule expression)
  app-fargate create-stack foo scheduled:bar 'schedule:cron(0 10 * * * *)' image:helloworld

  # Multiple services in one run
  app-fargate create-stack foo \
    task:ingest image:etl:42 \
    scheduled:nightly 'schedule:rate(1 day)' image:etl:42 \
    http:api image:rest:latest domain:api.example.com

=head4 Service clause grammar

Each service is introduced by C<< <type>:<name> >> followed by its required
key:value pairs. You may specify multiple services in one command.

I<Note: You must start each task definition set with a task type (one of
daemon, task, scheduled, http or https).>

Valid C<type> values and minimum keys:

=over 4

=item C<environment>

  environment:RUN_ONCE=1

Sets an environment variable in the task. You can use C<env:> as an
abbreviation for C<environment:>.

=item C<task>

  task:<name> image:<repo[:tag]>

Non-daemon task that can be run on demand.

=item C<http>

  http:<name> image:<repo[:tag]> domain:<fqdn>

ALB-backed HTTP service.

=item C<https>

  https:<name> image:<repo[:tag]> domain:<fqdn>

ALB-backed HTTPS service (certificate discovery/validation is out of scope for
this command; see the env checker).

=item C<scheduled>

  scheduled:<name> image:<repo[:tag]> schedule:<expr>

EventBridge-scheduled task. C<schedule> must be a valid C<cron(...)> or
C<rate(...>) expression. Quote it in the shell, for example:
C<'schedule:cron(0 10 * * * *)'>.

I<Note: You can use C<task:> or C<scheduled:> to indicate a scheduled task
as long as you include a C<schedule:> term.>

=item C<daemon>

  daemon:<name>

Long-running service without a load balancer.


=item C<image>

 image:<repo[:tag]>

If C<image> is given as C<< repo[:tag] >> without a registry host:

=over 4

=item *

The command I<assumes> the image lives in the current account's ECR and will
format the Docker reference as:

  <account_id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>

=item *

If ECR lookup does not find the repository+tag, the tool emits a warning and
leaves the image string as-is (allowing public registries like Docker Hub to
work). This preserves convenience while making the fallback explicit.

=item *

Fully-qualified images (e.g., C<public.ecr.aws/namespace/image:tag>,
C<docker.io/library/nginx:1.27>) are accepted as-is.

=back

=item C<autoscaling>

 autoscaling:cpu|request[=value]

For services of type C<https>, C<http>, or C<daemon>, you can enable
and configure autoscaling directly from the command line. This provides a
quick-start method to make your service elastic from the moment it's created.

The C<autoscaling:> keyword accepts a metric and an optional target value:

=over 4

=item * B<Enable with a specific target value:>

 autoscaling:requests=500
 autoscaling:cpu=60

This will enable autoscaling and set the target for either ALB requests per
task or average CPU utilization.

=item * B<Enable with default target value:>

 autoscaling:requests
 autoscaling:cpu

If you omit the target value, a sensible default will be used (e.g.,
C<500> for requests, C<60> for CPU).

=back

When the C<create-stack> command sees the C<autoscaling:> keyword, it
will generate a complete C<autoscaling> block in your configuration
file. This block will be populated with safe defaults (C<min_capacity: 1>,
C<max_capacity: 2>), the specified metric, and all other necessary fields,
making it easy to review and customize later. See L</AUTOSCALING> for
a full list of configuration options.

=item C<waf>

 waf:true|enabled|default|rule...

For C<https> services, you can enable and configure an AWS Web
Application Firewall (WAF) directly from the command line. This
provides a powerful shortcut to bootstrapping a secure,
production-ready WAF with minimal configuration.

The C<waf:> keyword is highly flexible and accepts several forms:

=over 4

=item * B<Enable with defaults:>

  waf:true
  waf:enabled
  waf:default

Any of these will enable WAF and apply the C<default> managed rule
bundle, which provides a strong security baseline including
protections against the OWASP Top 10 and SQL injection.

=item * B<Enable with specific rule sets:>

You can specify a comma-separated list of rule set keywords. This
allows you to tailor the protection to your application's specific
needs from the very first command.

  waf:base,php,admin

=item * B<Enable with bundles and subtractive syntax:>

For more complex configurations, you can use pre-configured bundles
and the subtractive syntax (prefixing a keyword with a C<->) to remove
unwanted rule sets.

  waf:all,-windows,-php

=back

When the C<create-stack> command sees the C<waf:> keyword, it will
automatically generate the corresponding C<waf> block in your
F<fargate-stack.yml> file, including C<enabled: true> and the
specified C<managed_rules>. See L</Configuring Managed Rules> for a
full list of available keywords and bundles.

For more information see L</AWS WAF Support>.

=back

=head4 Output

Emits YAML to STDOUT that includes:

=over 4

=item *

C<account>, C<profile>, C<region>

=item *

C<app.name> set from the first positional C<< <app-name> >>

=item *

Optional C<domain> (for HTTP/HTTPS stacks)

=item *

C<tasks> map keyed by service C<< <name> >> with fields such as C<type>,
C<image>, and C<schedule> (when applicable)

=back

=head4 Options

=over 4

=item B<--route53-profile> I<STR>

AWS profile to use when performing Route 53 API calls. Many environments
use a separate account for DNS management; this option lets you target
that account. If not provided, the tool uses B<--profile>.

This option is only consulted when the command needs Route 53 (for example,
HTTP/HTTPS stacks that require hosted zone lookups or record creation).

=item B<--dns-profile> I<STR>

Alias for B<--route53-profile>.

=item B<--region> I<STR>

AWS region used when expanding ECR shorthand.

=item B<--out> I<FILE>

Write YAML to a file instead of STDOUT.

=item B<--force>

Proceed even if some validations warn (for example, missing ECR repo).

=back

=head4 Exit Status

  0 on success
  non-zero on argument or validation errors

=head4 NOTES

=over 4

=item *

This command generates config; it does not deploy. Run your normal "plan/apply"
flow after reviewing the YAML.

=item *

For HTTP/HTTPS, C<domain:> is required at creation time in this shorthand.

=item *

Always quote C<schedule:...> to avoid shell interpretation of parentheses.

=back

=head3 deploy-service

 deploy-service service-name

When you provision an HTTP, HTTPS, or daemon service, the framework
sets up all the necessary infrastructure components -- but it B<does not>
automatically create and start the ECS service.

Use this command to start the service:

  app-FargateTask deploy-service service-name

If you want to start multiple tasks for the service, you can include a
count argument:

  app-FargateTask deploy-service service-name 2

=head3 delete-daemon

 delete-daemon task-name

Deletes the AWS resources associated with a task of type
C<daemon>. Consider removing the service
(L</remove-service>) or stopping the service
(L</stop-service>) if you do not want to delete the actual
resources.

See L</Notes on Deletion of Resources> for additional details.

=head3 delete-scheduled-task

 delete-scheduled-task task-name

Deletes the AWS resources associated with a task of type C<task> that
includes a C<schedule:> key.

See L</Notes on Deletion of Resources> for additional details.

=head3 delete-task

 delete-task task-name

Deletes the AWS resources associated with a task of type C<task>.

See L</Notes on Deletion of Resources> for additional details.

=head3 delete-http-service

Deletes the AWS resources associated with a task of type C<http> or C<https>.

If the Application Load Balancer (ALB) used by the service was
provisioned by C<App::FargateStack>, it will be automatically
deleted. However, if the ALB was discovered but not created by
C<App::FargateStack>, it will be preserved. In that case, only the listener
rules provisioned by C<App::FargateStack> will be removed.

This command will also not delete any ACM certificate that was
provisioned by C<App::FargateStack>.

See L</Notes on Deletion of Resources> for additional details.

=head3 destroy

Removes all resources provisioned by App::FargateStack. This command
will confirm deletion before removing any resources. Use C<--force> to
prevent confirmation.  Use C<--confirm-all> to confirm deletion of
every resource.

After this command is executed a skeleton of the tasks will
remain. You can run C<--plan> again and then C<--apply> to reprovision
the stack.

=head3 disable-scheduled-task

 disable-scheduled-task task-name

Use this command to disable a scheduled task.

If you omit C<task-name>, the command will attempt to determine the
target task selecting the task of type C<task> with a defined
C<schedule:> key but only if exactly one such task is defined in
your configuration file.

=head3 enable-scheduled-task

 enable-scheduled-task task-name

Use this command to enable a scheduled task.

If you omit C<task-name>, the command will attempt to determine the
target task selecting the task of type C<task> with a defined
C<schedule:> key but only if exactly one such task is defined in
your configuration file.

=head3 list-tasks

 list-tasks [stopped]

Lists running or stopped tasks and outputs a table of information about the tasks.

 Task Name
 Task Id
 Status
 Memory
 CPU
 Start Time
 Elapsed Time
 Stopped Reason

=head3 list-zones

 list-zones domain-name

This command will list the hosted zones for a specific domain. The
framework automatically detects the appropriate hosted zone for your
domain if the C<zone_id:> key is missing from your configuration when
you have an HTTP or HTTPS task defined.

Example:

 app-FargateStack list-zones --profile prod

=head3 logs

 logs start-time end-time

To view your log streams use the C<logs> command. This command will
display the logs for the most recent log stream in the log group. By
default the start time is the time of the first event.

=over 4

=item Use C<--log-wait> to continuously poll the log stream.

=item Use C<--no-log-time> if your logs already have timestamps and do
not want to see CloudWatch timestamps. This is useful when you are
logging time in your time zone and do not want to be confused seeing
times that don't line up.

=item C<start-time> can be a "Nh", "Nm", "Nd" where N is an integer
and h=hours ago, m=minutes ago and d=days ago.

=item C<start-time> and C<end-time> can be "mm/dd/yyyy hh:mm:ss" or just "mm/dd/yyyy"

=item C<end-time> must always be a date-time string.

=back

=head3 plan              

Reads the configuration file and determines what actions to perform
and what resources will be built. Only updates configuration file with
resource details but DOES NOT build them.

=head3 redeploy

  redeploy service-name

Forces a new deployment of the specified ECS service without registering a new
task definition. This triggers ECS to stop the currently running task and
launch a new one using the same task definition revision.

If you omit C<service-name>, the command will attempt to determine the
target service by selecting the task of type C<daemon>, C<http>, or
C<https>, but only if exactly one such service is defined in your
configuration file.

If the task definition references an image by tag (such as C<:latest>), this
command ensures ECS re-pulls the image from ECR at deployment time. This allows
you to deploy a newly pushed image without needing to create a new revision of
the task definition.

This command is especially useful when:

=over 4

=item *

You have pushed a new version of an image using the same tag (e.g. C<:latest>)

=item *

You want to roll the service without changing other configuration

=item *

You want to confirm ECS tasks are using the most up-to-date image tag from ECR

=back

Note that if your task definition references an image by digest
(e.g. C<@sha256:...>), ECS will continue to use that exact image. In that case,
you must register a new task definition to update the image.

For best results, use this command as a shortcut to avoid
C<register-task>, C<update-service> steps and only when your service's
task definition uses an image tag that can be re-resolved, such as
C<:latest> or a CI-generated version tag.

=head3 register-task-definition

 register-task-definition task-name

Creates a new task definition revision in ECS for the specified task.

Under normal circumstances, you should not need to run this command
manually. Task definitions are automatically registered when you
execute C<plan> or C<apply>.

This command is provided for exceptional cases where you need to force
a new revision using a previously generated task definition file.

B<Warning:> You should not manually modify the generated file
(F<taskdef-{task-name}.json>), as doing so may cause
C<App::FargateStack> to lose track of your task's configuration.

=head3 remove-service

 remove-service service-name

Deletes a running ECS service without removing any of the underlying
AWS resources.

If you simply want to stop the service temporarily, use the
C<stop-service> command instead.

This command does not delete associated infrastructure such as the
target group, security group, or load balancer listener rules. To
delete those resources, see L</delete-daemon> or
L</delete-http-service>, depending on the task type.

=head3 run-task

 run-task task-name

Launches a one-shot Fargate task. By default, the command waits for the
task to complete and streams the task's logs to STDERR. Use the C<--no-wait>
option to launch the task and return immediately.

When you register a task definition, ECS records the image digest of the
image specified in your configuration file. If you later push a new image
tagged with the same name (e.g., C<latest>) without updating the task
definition, ECS will continue to use the original image digest.

To detect this kind of drift, C<app-FargateStack> records the image digest
at the time of task registration and compares it to the current digest
associated with the tag (typically C<latest>) at runtime.

If the digests do not match, the default behavior is to abort execution
and warn you about the mismatch. To override this safety check and proceed
anyway, use the C<--force> option.

=head3 state

 state config-name

You can use this command to switch the default configuration that
C<app-FargateStack> will use when run without arguments.

The default configuration controls which task profile, region, and
configuration file are considered "current." This allows you to run
commands without repeatedly specifying the same options.

This command will output the table below that shows the currently
active defaults:

  .--------------------------------------------------------------------------------------------------.
  |                                    Current Defaults: http-test                                   |
  +---------+-------------+-----------+-------------------------------------------------+------------+
  | Profile | DNS Profile | Region    | Config                                          | Max Events |
  +---------+-------------+-----------+-------------------------------------------------+------------+
  | sandbox | prod        | us-east-1 | /home/rlauer/git/App-FargateStack/http-test.yml |          5 |
  '---------+-------------+-----------+-------------------------------------------------+------------'

=head3 status

  status service-name

Displays the status of a running service and its most recent event messages
in tabular form.

If you omit C<service-name>, the command will attempt to determine the
target service by selecting the task of type C<daemon>, C<http>, or
C<https>, but only if exactly one such service is defined in your
configuration file.

Use the C<--max-events> option to control how many recent events are shown.
The default is 5.

=head3 stop-task

 stop-task task-arn|task-id

Stops a running task. To get the task id, use the C<list-tasks>
command.

=head3 stop-service

 stop-service service-name

Stops a running service by setting its desire count to 0.

If you omit C<service-name>, the command will attempt to determine the
target service by selecting the task of type C<daemon>, C<http>, or
C<https>, but only if exactly one such service is defined in your
configuration file.

=head3 start-service

 start-service service-name [count]

Start a service. C<count> is the desired count of tasks. The default
count is 1.

If you omit C<service-name>, the command will attempt to determine the
target service by selecting the task of type C<daemon>, C<http>, or
C<https>, but only if exactly one such service is defined in your
configuration file.

=head3 tasks

Displays a table that summarizes your stack resources.

=head3 update-policy

 update-policy

Forces the framework to re-evaluate resources and align the
policy. Will not apply changes in C<--dryrun> mode. Under normal
circumstances you should not need to run this command, however if you
find that your Fargate policy lacks permissions for resources you have
configure, this will make sure that all configured resources are
included in your policy.

If C<update-policy> identifies a need to update your role policy, you
can view the changes before they are applied by running the C<plan>
command at the C<trace> log level.

 app-Fargate --log-level trace plan

=head3 update-service

update-service [service-name]

Updates an ECS service's configuration to use the latest registered
task definition. This is the primary command for deploying any changes
to your application, including new container images, environment
variables, or resource allocations.

When an ECS service is launched, it is "pinned" to a specific revision
of a task definition (e.g., my-task:9). If you later push a new
container image or change the task's configuration in your
configuration file, the running service B<will not> automatically pick up
those changes.

This command is the essential final step in the deployment process.

=over 4

=item * If the service is running, this command will trigger a rolling
deployment to replace the existing tasks with new ones based on the
new task definition.

=item * If the service is stopped, this command updates its
configuration. The next time you run start-service, it will launch
tasks using the new task definition.

=back

B<When to use C<update-service> vs. C<redeploy>>

While both commands can result in a new deployment, they serve
different purposes:

Use C<update-service> when you have made any change to your
configuration file that affect the task definition. This is the
correct command for deploying a new image, adding environment
variables, injecting secrets, changing CPU/memory, or adding EFS mount
points. The workflow is:

Update your configuration file.

Run C<app-FargateStack register-task-definition task-name>

Run C<app-FargateStack update-service task-name>

Use C<redeploy> as a shortcut only when you have pushed a new image using
the same tag (e.g., :latest) and have made no other configuration
changes. redeploy forces a new deployment using the existing task
definition, which is simpler but will not apply any other updates.

The status command can help you detect drift by showing if the running
task definition is out of sync with your latest configuration.

=head3 update-target

 update-target task-name

Updates an EventBridge rule and rule target. For tasks of type "task"
(typically scheduled jobs) when you change the schedule the rule must
be deleted, re-created and associated with the target task. This
command will detect the drift in your configuration and apply the
changes if not in C<--dryrun> mode.

=head3 version              

Outputs the current version of C<App::FargateStack>.

=head2 Notes on Deletion of Resources

=over 4

=item *

You will be prompted to confirm the operation before any task is
deleted.

=item *

If the specified task is the only one defined in your configuration
file, its configuration will not be fully removed. Instead, the task's
provisioned resource ARNs and names will be deleted, leaving behind a
minimal configuration skeleton. This allows you to re-provision the
task later by running C<plan> against the skeleton, avoiding the need
to recreate it from scratch.

=item *

C<App::FargateStack> does not delete ECR images associated with tasks.

=item *

ACM certificates provisioned by C<App::FargateStack> will not be
deleted.

=back

=head1 DEPLOYMENT WORKFLOW GUIDE

One of the most common questions when managing a stack is, "I changed
X, what command(s) do I need to run now?" This guide provides a
quick-reference matrix to help you choose the correct workflow for the
most common changes.

=head2 How to Use This Matrix

Find the change you made in the "Change Description" column and follow
the row across to see which commands are required. Commands should be
run in order from left to right.

 +---------------------------------------------+---------+---------+----------+----------+
 | Change Description                          | apply   | register| update-  | redeploy |
 |                                             |         | -task   | service  |          |
 +---------------------------------------------+---------+---------+----------+----------+
 | Updated container image (new tag/digest)    |         |    X    |    X     |          |
 |---------------------------------------------+---------+---------+----------+----------|
 | Updated container image (same :latest tag)  |         |         |          |    X     |
 |---------------------------------------------+---------+---------+----------+----------|
 | Added/changed environment variables         |         |    X    |    X     |          |
 |---------------------------------------------+---------+---------+----------+----------|
 | Added/changed secrets                       |    X    |    X    |    X     |          |
 |---------------------------------------------+---------+---------+----------+----------|
 | Added/changed CPU, memory, or size          |         |    X    |    X     |          |
 |---------------------------------------------+---------+---------+----------+----------|
 | Changed a scheduled task's cron/rate        |    X    |         |          |          |
 |---------------------------------------------+---------+---------+----------+----------|
 | Added a new S3 bucket or SQS queue          |    X    |    X    |    X     |          |
 |---------------------------------------------+---------+---------+----------+----------|
 | Added or changed an EFS mount point         |    X    |    X    |    X     |          |
 +---------------------------------------------+---------+---------+----------+----------+

=head2 Notes on the Workflow

=over 4

=item * 
C<plan> is Your Best Friend: Before running apply or any command that
makes changes, it is always a good practice to run app-FargateStack
plan first. This will give you a dry-run preview of the changes and
help you catch any configuration errors.

=item * Why apply is Sometimes Needed: Changes that affect AWS
resources beyond the ECS task definition itself -- like IAM
permissions for a new secret, EventBridge rules for a new schedule, or
provisioning a new S3 bucket -- require running apply to create or
update that infrastructure.

=item * redeploy is a Shortcut: The redeploy command is a special
case. It's a convenient shortcut for the common scenario where you've
pushed a new image to the :latest tag and need to force a deployment
without changing the task definition itself. For all other changes,
the register-task and update-service workflow is the correct and safer
path.

=back

=head1 CLOUDWATCH LOG GROUPS

A CloudWatch log group is automatically provisioned for each
application stack. By default, the log group name is
/ecs/<application-name>, and log streams are created per task.

For example, given the following configuration:

 app:
   name: my-stack
 ...
 tasks:
   apache:
     type: https

The framework will:

=over 4

=item * ...create a log group named /ecs/my-stack

=item * ...configure the apache task to write log streams with a prefix
like my-stack/apache/*

=back

By default, the log group is set to retain logs for 14 days if
C<retention_days> is not specified. You can override this by
specifying a custom retention period using the C<retention_days> key
in the task's log_group section:

 log_group:
   retention_days: 30

=head2 Log Group Notes

=over 4

=item * The log group is reused if it already exists.

=item * Only numeric values accepted by CloudWatch are valid for
retention_days (e.g., 1, 3, 5, 7, 14, 30, 60, 90, etc.).

=item * You can customize the log group name by setting the name in
the C<log_group:> section (not recommended).

 log_group:
   retention_days: 14
   name: /ecs/my-stack

=item * You can change the retention period by updating the
configuration file and re-running C<apply>.

=item * To retain logs indefinitely, remove the C<retention_days>
entry in your configuration file.

=back

=head1 IAM PERMISSIONS

This framework uses a single IAM role for all tasks defined within an
application stack.  The assumption is that services within the stack
share a trust boundary and operate on shared infrastructure.  This
simplifies IAM management while maintaining strict isolation between
stacks.

IAM roles and policies are automatically created based on your
configuration.  Only the minimum required permissions are granted.
For example, if your configuration defines an S3 bucket, the ECS task
role will be permitted to access only that specific bucket - not all
buckets in your account. The policy is updated when new resources are
added to the configuration file.

The task execution role name and role policy name are found under the
C<role:> key in the configuration. The task role is found under the
C<task_role:> key. Role names and role policy names are automatically
fabricated for you from the name you specified under the C<app:> key.

=head2 Task Execution Role vs. Task Role

It's important to understand that App::FargateStack provisions two
distinct IAM roles for your service. The Task Role, which is detailed
above, grants your application the specific permissions it needs to
interact with other AWS services like S3 or SQS. In addition, the
framework also creates a Task Execution Role. This second role is used
by the Amazon ECS container agent itself and grants it permission to
perform essential actions, such as pulling container images from ECR
and sending logs to CloudWatch. You typically won't need to modify the
Task Execution Role, as the framework manages its permissions
automatically.

=head1 SECURITY GROUPS

A security group is automatically provisioned for your Fargate
cluster.  If you define a task of type C<http> or C<https>, the
security group attached to your Application Load Balancer (ALB) is
automatically authorized for ingress to your Fargate task. This is a
rule allowing ALB-to-Fargate traffic.

=head1 FILESYSTEM SUPPORT

EFS volumes are defined per task and mounted according to the task
definition. This design provides fine-grained control over EFS usage,
rather than treating it as a global, stack-level resource.

Each task that requires EFS support must include both a volume and
mountPoint configuration. The ECS task role is automatically updated
to allow EFS access based on your specification.

To specify EFS support in a task:

 efs:
   id: fs-1234567b
   mount_point: /mnt/my-stack
   path: /
   readonly:

Acceptable values for C<readonly> are "true" and "false".

=head2 Field Descriptions

=over 4

=item id:

The ID of an existing EFS filesystem. The framework does not provision
the EFS, but will validate its existence in the current AWS account
and region.

=item mount_point:

The container path to which the EFS volume will be mounted.

=item path:

The path on the EFS filesystem to map to your container's mount point.

=item readonly:

Optional. Set to C<true> to mount the EFS as read-only. Defaults to
C<false>.

=back

=head2 Additional Notes

=over 4

=item * The ECS role's policy for your task is automatically modified
to allow read/write EFS access. Set C<readonly:> in your task's
C<efs:> section to "true" if only want read support.

=item * Your EFS security group must allow access from private subnets
where the Fargate tasks are placed.

=item * No changes are made to the EFS security group; the framework
assumes access is already configured

=item * Only one EFS volume is currently supported per task configuration.

=item * EFS volumes are task-scoped and reused only where explicitly configured.

=item * The framework does not automatically provision an EFS
filesystem for you. The framework does however validate that the
filesystem exists in the current account and region.

=back

=head1 CONFIGURATION

The C<App::FargateStack> framework defines your application stack
using a YAML configuration file. This file describes your
application's services, their resource needs, and how they should be
deployed. Then configuration is updated whenever your run C<plan> or
C<apply>.

=head2 GETTING STARTED

The fastest way to get up and running with C<App::FargateStack> is to
use the C<create-stack> command to generate a configuration file,
inspect the deployment plan, and then apply it.

=head3 Step 1: Create a Configuration Stub

First, generate a minimal YAML configuration file. The C<create-stack>
command provides a shorthand syntax to do this. You only need to
provide an overall application name, a service type, a service name,
and the container image to use.

This command will create a file named F<my-stack.yml> in your current
directory. Make sure you have your AWS profile configured in your
environment or pass it using the C<--profile> option.

  app-FargateStack create-stack my-stack daemon:my-stack-daemon image:my-stack-daemon:latest

This will produce a configuration stub that looks like this:

  app:
    name: my-stack
  tasks:
    my-stack-daemon:
      image: my-stack-daemon:latest
      type: daemon

This file contains the three key pieces of information you provided:
the application name, the task name, and the image to use.

=head3 Step 2: Plan the Deployment (Dry Run)

Next, run the C<plan> command. This is a crucial step that acts as a
dry run. The framework will:

=over 4

=item * Read your minimal configuration file.

=item * Intelligently discover resources in your AWS account (like your VPC and subnets).

=item * Determine what new resources need to be created (like IAM roles, a security group, an ECS cluster and a CloudWatch log group).

=item * Report a full plan of action without making any actual changes.

=item * Update your configuration file with the discovered values and
sensible defaults.

=back

  app-FargateStack plan

After this command completes, your F<my-stack.yml> file will be fully
populated with all the information needed to provision your stack.

=head3 Step 3: Apply the Plan

Once you have reviewed the plan and are satisfied with the proposed
changes, run the C<apply> command. This will execute the plan and
create all the necessary AWS resources.

  app-FargateStack apply

=head3 Step 4: Deploy and Start the Service

The C<apply> command creates all the necessary B<infrastructure>, but
it does not start your service. This separation allows you to manage
your infrastructure and your application's runtime state
independently.

To create the ECS service and start your container, use the
C<deploy-service> command.

  app-FargateStack deploy-service my-stack-daemon

By default, this will start one instance of your task. To check its
status, use the C<status> command:

  app-FargateStack status my-stack-daemon

And to stop the service, simply run:

  app-FargateStack stop-service my-stack-daemon

To restart a stopped service, run:

  app-FargateStack start-service my-stack-daemon

=head2 VPC AND SUBNET DISCOVERY

If you do not specify a C<vpc_id> in your configuration, the framework will attempt
to locate a usable VPC automatically.

A VPC is considered usable if it meets the following criteria:

=over 4

=item * It is attached to an Internet Gateway (IGW)

=item * It has at least one available NAT Gateway

=back

If no eligible VPCs are found, the process will fail with an error. If multiple
eligible VPCs are found, the framework will abort and list the candidate VPC IDs.
You must then explicitly set the C<vpc_id:> in your configuration to resolve
the ambiguity.

If exactly one eligible VPC is found, it will be used automatically,
and a warning will be logged to indicate that the selection was
inferred.

=head2 SUBNET SELECTION

If no subnets are specified in the configuration, the framework will query all
subnets in the selected VPC and categorize them as either public or private.

The task will be placed in a private subnet by default. For this to succeed,
your VPC must have at least one private subnet with a route to a NAT Gateway,
or have appropriate VPC endpoints configured for ECR, S3, STS, CloudWatch Logs,
and any other services your task needs.

If subnets are explicitly specified in your configuration, the
framework will validate them and warn if they are not reachable or are
not usable for Fargate tasks.

=head3 Task placement and Availability Zones

The framework places each task's ENI into exactly one subnet, which fixes
that task in a single AZ. A service can span multiple AZs by listing
subnets from at least two AZs.

What the framework does:

=over 4

=item * Prefers private subnets

If private subnets are defined in the configuration, tasks are placed
there. If no private subnets are defined, the framework falls back to
public subnets.

=item * Aligns ALB AZs with task placement

When a load balancer is used, the framework enables the ALB in the same
AZ set it selects for tasks (best practice). This is for resilience and
to avoid unnecessary cross-AZ hops; it is not a hard technical requirement.

=item * Requires two subnets

The configuration must specify at least two subnets in different AZs.
If subnets are not specified, the framework attempts to discover them,
but still requires at least two usable subnets (either both private or
both public). If fewer than two are available, it errors with guidance.

=back

Notes on internet access and ALBs:

=over 4

=item * Internet-facing ALB

An internet-facing ALB must be created in public subnets. Tasks may (and
usually should) remain in private subnets behind it.

=item * Egress from private subnets

For image pulls and outbound calls, use either a NAT Gateway in each AZ
or VPC endpoints for ECR (api and dkr) and S3.

=item * Egress from public subnets

If tasks are placed in public subnets without endpoints or NAT, they
require C<assignPublicIp=ENABLED> to reach ECR/S3.

=back

=head2 REQUIRED SECTIONS

At minimum, your configuration must include the following:

  app:
    name: my-stack

  tasks:
    my-task:
      image: my-image
      type: daemon | task | http | https

For task types C<http> or C<https>, you must also specify a domain name:

  domain: example.com

=head2 FULL SCHEMA OVERVIEW

The framework will expand and update your configuration file with default values as needed.
Here is the full schema outline. All keys are optional unless otherwise noted:

  ---
  account:
  alb:
    arn:
    name:
    port:
    type:
  app:
    name:             # required
    version:
  certificate_arn:
  cluster:
    arn:
    name:
  default_log_group:
  domain:              # required for http/https tasks
  id:
  last_updated:
  region:
  role:
    arn:
    name:
    policy_name:
  route53:
    profile:
    zone_id:
  security_groups:
    alb:
      group_id:
      group_name:
    fargate:
      group_id:
      group_name:
  subnets:
    private:
    public:
  tasks:
    my-task:
      arn:
      cpu:
      family:
      image:           # required
      log_group:
        arn:
        name:
        retention_days:
      memory:
      name:
      size:
      target_group_arn:
      target_group_name:
      task_definition_arn:
      type:            # required (daemon, task, http, https)
  vpc_id:

=head1 TASK SIZE

To simplify task configuration, the framework supports a shorthand key called
C<size> that maps to common CPU and memory combinations supported by Fargate.

If specified, the C<size> parameter should be one of the following profile names:

  tiny     => 256 CPU, 512 MB memory
  small    => 512 CPU, 1 GB memory
  medium   => 1024 CPU, 2 GB memory
  large    => 2048 CPU, 4 GB memory
  xlarge   => 4096 CPU, 8 GB memory
  2xlarge  => 8192 CPU, 16 GB memory

When a C<size> is provided, the framework will automatically populate the
corresponding C<cpu> and C<memory> values in the task definition. If you
manually specify C<cpu> or C<memory> alongside C<size>, those manual values
will take precedence and override the defaults from the profile.

B<Important:> If you change the C<size> after an initial deployment, you should
remove any manually defined C<cpu> and C<memory> keys in your configuration.
This ensures that the framework can correctly apply the new profile values
without conflict.

If neither C<size>, C<cpu>, nor C<memory> are provided, the framework will infer
a sensible default size based on the task type. For example:

  - "http" or "https" => "medium"
  - "task"            => "small"
  - "task" + schedule => "medium"
  - "daemon"          => "medium"

This behavior helps minimize configuration boilerplate while still providing
sane defaults.

=head1 ENVIRONMENT VARIABLES

The Fargate stack framework allows you to define environment variables for each
task. These variables are included in the ECS task definition and made available
to your container at runtime.

Environment variables are specified under the C<environment:> key within the task
configuration.

=head2 BASIC USAGE

  task:
    apache:
      environment:
        ENVIRONMENT: prod
        LOG_LEVEL: info
        DEBUG_MODE: 0

Each key/value pair will be passed to the container as an environment
variable.

Environment variable values are treated literally; shell-style
expressions such as ${VAR} are not interpolated. If you need dynamic
values, populate them explicitly in the configuration or use the
C<secrets:> block for sensitive data.

This mechanism is ideal for non-sensitive configuration such as
runtime flags, environment names, or log levels.

=head2 SECURITY NOTE

Avoid placing secrets (such as passwords, tokens, or private keys) directly in the
C<environment:> section. That mechanism is intended for non-sensitive configuration
data.

To securely inject secrets into the task environment, use the C<secrets:> section
of your task configuration. This integrates with AWS Secrets Manager and ensures
secrets are passed securely to your container.

=head2 INJECTING SECRETS FROM SECRETS MANAGER

To inject secrets into your ECS task from AWS Secrets Manager, define a C<secrets:>
block in the task configuration. Each entry in this list maps a Secrets Manager
secret path to an environment variable name using the following format:

  /secret/path:ENV_VAR_NAME

Example:

  task:
    apache:
      secrets:
        - /my-stack/mysql-password:DB_PASSWORD

This configuration retrieves the secret value from C</my-stack/mysql-password>
and injects it into the container environment as C<DB_PASSWORD>.

Secrets are referenced via their ARN using ECS's native secrets mechanism,
which securely injects them without placing plaintext values in the task definition.

=head2 BEST PRACTICES

Avoid placing secrets in the C<environment:> block. That block is for non-sensitive
configuration values and exposes data in plaintext.

Use clear, descriptive environment variable names (e.g., C<DB_PASSWORD>, C<API_KEY>)
and organize your Secrets Manager paths consistently with your stack naming.

=head1 SQS QUEUES

The Fargate stack framework supports configuring and provisioning a
single AWS SQS queue, including an optional dead letter queue (DLQs).

A queue is defined at the stack level and is accessible to all tasks
and services within the same stack. IAM permissions are automatically
scoped to include only the explicitly configured queue and its
associated DLQ (if any).

I<Only one queue and one optional DLQ may be configured per stack.>

=head2 BASIC CONFIGURATION

At minimum, a queue requires a name:

  queue:
    name: fu-man-q

If you define C<max_receive_count> in the queue configuration, a DLQ
will be created automatically. You can optionally override its name
and attributes using the top-level C<dlq> key:

  queue:
    name: fu-man-q
    max_receive_count: 5

  dlq:
    name: custom-dlq-name

If you do not specify a C<dlq.name>, the framework defaults to appending C<-dlq> to
the main queue name (e.g., C<fu-man-q-dlq>).

=head2 DEFAULT QUEUE ATTRIBUTES

If not specified, the framework applies default values to match AWS's standard SQS behavior:

  queue:
    name: fu-man-q
    visibility_timeout: 30
    delay_seconds: 0
    receive_message_wait_time_seconds: 0
    message_retention_period: 345600
    maximum_message_size: 262144
    max_receive_count: 5  # triggers DLQ creation

  dlq:
    visibility_timeout: 30
    delay_seconds: 0
    receive_message_wait_time_seconds: 0
    message_retention_period: 345600
    maximum_message_size: 262144

=head2 DLQ DESIGN NOTE

A dead letter queue is not a special type - it is simply another queue used
to receive messages that have been unsuccessfully processed. It is modeled
as a standalone queue and defined at the top level of the stack configuration.

The C<dlq> block is defined at the same level as C<queue>, not nested within it.
If no overrides are provided, DLQ attributes default to AWS attribute defaults.

=head2 IAM POLICY UPDATES

Adding a new queue to an existing stack will not only create the queue, but
also update the IAM policy associated with your stack to include permissions
for the newly defined queue and DLQ (if applicable).

=head1 SCHEDULED JOBS

The Fargate stack framework allows you to schedule container-based jobs
using AWS EventBridge. This is useful for recurring tasks like report generation,
batch processing, database maintenance, and other periodic workflows.

A scheduled job is defined like any other task, using C<type: task>, and
adding a C<schedule:> key in AWS EventBridge cron format.

=head2 SCHEDULING A JOB

To schedule a job, add a C<schedule:> key to your task definition. The
value must be a valid AWS cron expression, such as:

  cron(0 2 * * ? *)   # every day at 2:00 AM UTC

Example:

  tasks:
    daily-report:
      type: task
      image: report-runner:latest
      schedule: cron(0 2 * * ? *)

I<Note: All cron expressions are interpreted in UTC.>

The framework will automatically create an EventBridge rule tied to
the task definition. When triggered, it will launch a one-off Fargate
task based on the configuration. The EventBridge rule is named using
the pattern "<task>-schedule".

All scheduled tasks support environment variables, secrets, and other
standard task features.

=head2 RUNNING AN ADHOC JOB

You can run a scheduled (or unscheduled) task manually at any time using:

  app-FargateStack run-task task-name

By default, this will:

=over 4

=item * Launch the task using the defined image and configuration

=item * Wait for the task to complete (unless C<--no-wait> is passed)

=item * Retrieve and print the logs from CloudWatch when the task exits

=back

This is ideal for debugging, re-running failed jobs, or triggering
occasional maintenance tasks on demand.

=head2 SERVICES VS TASKS

A task of type C<daemon> is launched as a long-running ECS service
and benefits from restart policies and availability guarantees.

A task of type C<task> is run using C<run-task> and may run once,
forever, or periodically - but it will not be automatically restarted
if it fails.

=head1 S3 BUCKETS

The Fargate stack framework supports creating a new S3 bucket or
using an existing one. The bucket can be used by your ECS tasks
and services, and the framework will configure the necessary IAM
permissions for access.

By default, full read/write access is granted unless you specify
restrictions (e.g., read-only or path-level constraints). In this model,
no bucket policy is required or modified.

I<Note: Full access includes s3:GetObject, s3:PutObject, s3:DeleteObject, and
s3:ListBucket.  Readonly access is limited to s3:GetObject and
s3:ListBucket.>

=head2 BASIC CONFIGURATION

You define a bucket in your configuration like this:

  bucket:
    name: my-app-bucket

By default, this grants full read/write access to the entire bucket via the
IAM role attached to your ECS task definition.

=head2 RESTRICTED ACCESS

You can limit access to a subset of the bucket using the C<readonly:> and
C<paths:> keys:

  bucket:
    name: my-app-bucket
    readonly: true
    paths:
      - public/*
      - logs/*

This will:

=over 4

=item * Grant only C<s3:GetObject> and C<s3:ListBucket> permissions

=item * Limit access to the specified path prefixes

=back

The C<paths:> values are interpreted as S3 key prefixes and inserted
directly into the role policy.

If you specify C<readonly: true> but omit C<paths:>, read-only access will
apply to the entire bucket. If you omit both keys, full read/write access
is granted.

=head2 IAM-BASED ENFORCEMENT

Bucket access is enforced exclusively through IAM role permissions. The
framework does not modify or require an S3 bucket policy. This keeps your
configuration simpler and avoids potential conflicts with externally
managed bucket policies.

=head2 USING EXISTING BUCKETS

If you reference an existing bucket not created by the framework, be aware
that the bucket's own policy may still restrict access.

In particular:

=over 4

=item * The IAM role created by the framework may permit access to a path

=item * But a bucket policy with an explicit C<Deny> will override that and block access

=item * This restriction will only be discovered at runtime when your task attempts access

=back

To avoid surprises, ensure that any bucket policy on an external bucket
permits access from the IAM role you're configuring.

=head1 HTTP SERVICES

=head2 Overview

To create a Fargate HTTP service set the C<type:> key in your task's
configuration section to "http" or "https".

The task type ("http" or "https") determines:

=over 4 

=item *  the B<type of load balancer> that will be used or created

=item * whether or not a B<certificate will be used or created>

=item * what B<default port> will be configured in your ALB's listener
rule

=back

=head2 Key Assumptions When Creating HTTP Services

=over 4

=item * Your domain is managed in Route 53 and your profile can create
Route 53 record sets.

I<Note: If your domain is managed in a different AWS account, set a
separate C<profile:> value in the C<route53:> section of the
configuration file.  Your profile should have sufficient permissions
to manage Route 53 recordsets.>

=item * Your Fargate task will be deployed in a private subnet and
will listen on port 80.

=item * No certificate will be provisioned for internal facing
applications. Traffic by default to internal facing applications
(those that use an internal ALB) will be insecure. I<This may become
an option in the future.>

=back

=head2 Architecture

When you set your task type to "http" or "https" a default
architecture depicted below will be provisioned.

                            (optional)
                        +------------------+
                        |  Internet Client |
                        +--------+---------+
                                 |
                      [only if ALB is external]
                                 |
                    +------------v--------------+
                    |  Route 53 Hosted Zone     |
                    |  Alias: myapp.example.com |
                    |     --> ALB DNS Name      |
                    +----------+----------------+
                                 |
                      +----------v----------+
                      | Application Load    |
                      | Balancer (ALB)      |
                      | [internal or        |
                      |  internet-facing]   |
                      |                     |
                      | Listeners:          |
                      |   - Port 80         |
                      |   - Port 443 w/ TLS |
                      |     + ACM Cert      |
                      |       (TLS/SSL)     |
                      |     [if external]   |
                      +----------+----------+
                                 |
                          +------v-------+
                          | Target Group |
                          +------+-------+
                                 |
                         +-------v---------+
                         | ECS Service     |
                         | (Fargate Task)  |
                         +-------+---------+
                                 |
                       +---------v----------+
                       | VPC Private Subnet |
                       +--------------------+

This default architecture provides a repeatable, production-ready
deployment pattern for HTTP services with minimal configuration.

=head2 Behavior by Task Type

For HTTP services, you set the task type to either "http" or "https"
(these are the only options that will trigger a task to be configured
for HTTP services). The table below summarizes the configurations by
task type.

 +-------+----------+-------------+-----------+---------------+
 | Type  | ALB type | Certificate |    Port   |  Hosted Zone  |
 +-------+----------+-------------+-----------+---------------+
 | http  | internal |    No       |    80     |   private     |
 | https | external |   Yes       |   443     |   public      |
 |       |          |             | 80 => 443 |               |
 +-------+----------+-------------+-----------+---------------+

I<NOTE: You must provide a domain name for both an internal and
external facing HTTP service. This also implies you must have a
both a B<private> and B<public> hosted zone for your domain.>

Your task type will also determine which type of subnet is required
and where to search for an existing ALB to use. If you want to prevent
re-use of an existing ALB and force the creation of a new one use the
C<--create-alb> option when you run your first plan.

In your initial configuration you do not need to specify the subnets
or the hosted zone id.  The framework will discover those and report
if any required resources are unavailable. If the task type is
"https", the script looks for a public zone, public subnets and an
internet-facing ALB otherwise it looks for a private zone, private
subnets and an internal ALB.

=head2 ACM Certificate Management

If the task type is "https" and no ACM certificate currently exists
for your domain, the framework will automatically provision one. The
certificate will be created in the same region as the ALB and issued
via AWS Certificate Manager. If the certificate is validated  via DNS
and subsequently attached to the listener on port 443.

=head2 Port and Listener Rules

For external-facing apps, a separate listener on port 80 is
created. It forwards traffic to port 443 using a default redirect rule
(301). If you do not want a redirect rule, set the C<redirect_80:> in
the C<alb:> section to "false".

If you want your internal application to listen on a port other than
80, set the C<port:> key in the C<alb:> section to a new port
value.

=head2 Example Minimal Configuration

 app:
   name: http-test
 domain: http-test.example.com
 task:
   apache:
     type: http
     image: http-test:latest

Based on this minimal configuration C<app-FargateStack> will enrich
the configuration with appropriate defaults and proceed to provision
your HTTP service.

To do that, the framework attempts to discover the resources required
for your service. If your environment is not compatible with creating
the service, the framework will report the missing resources and
abort the process.

Given this minimal configuration for an internal ("http") or
external ("https") HTTP service, discovery entails:

=over 4

=item  ...determining your VPC's ID

=item  ...identifying the private subnet IDs

=item ...determining if there is and existing load balancer with the
correct scheme

=item  ...finding your load balancer's security group (if an ALB exists)

=item  ...looking for a listener rule on port 80 (and 443 if type is
"https"), including a default forwarding redirect rule

=item  ...validating that you have a private or public hosted zone
in Route 53 that supports your domain

=item  ...setting other defaults for additional resources to be built (log
groups, cluster, target group, etc)

=item  ...determining if an ACM certificate exists for your domain
(if type is "https")

=back

I<Note: Discovery of these resources is only done when they are
missing from your configuration. If you have multiple VPCs for example
you can should explicitly set C<vpc_id:> in the configuration to
identify the target VPC.  Likewise you can explicitly set other
resource configurations (subnets, ALBs, Route 53, etc).>

Resources are provisioned and your configuration file is updated
incrementally as C<app-FargateStack> compares your environment to the
environment required for your stack. When either plan or
apply complete your configuration is updated giving you complete
insight into what resources were found and what resources will be
provisioned. See L<CONFIGURATION> for complete details on resource
configurations.>

Your environment will be validated against the criteria described
below.

=over 4

=item * You have at least 2 private subnets available for deployment

Technically you can launch a task with only 1 subnet but for services
behind an ALB Fargate requires 2 subnets.

I<When you create a service with a load balancer, you must specify
two or more subnets in different Availability Zones. - AWS Docs>

=item * You have a hosted zone for your domain of the appropriate type
(private for type "http", public for type "https")

=back

As discovery progresses, existing and required resources are logged
and your configuration file is updated. If you are B<NOT> running in
dryrun mode, resources will be created immediately as they are
discovered to be missing from your environment.

=head2 Application Load Balancer

When you provision an HTTP service, whether or not it is secure, the
service will placed behind an application load balancer. Your Fargate
service is created in private subnets, so your VPC must contain at
least two private subnets.  Your load balancer can either be
I<internally> or I<externally facing>.

By default, the framework looks for and will reuse a load balancer
with the correct scheme (internal or internet-facing), in a subnet
aligned with your task type. The ALB will be placed in public subnets
if it is internet-facing. You can override that behavior by either
explicitly setting the ALB arn in the C<alb:> section of the
configuration or pass C<--create-alb> when you run our plan and apply.

If no ALB is found or you passed the C<--create-alb> option, a new ALB
is provisioned. When creating a new ALB, C<app-FargateStack> will also
create the necessary listeners and listener rules for the ports you
have configured.

=head3 Why Does the Framework Force the Use of a Load Balancer?

While it is possible to avoid the use or the creation of a load balancer
for your service, the framework forces you to use one for at least two
reasons. Firstly, the IP address of your service may not be stable and
is not friendly for development or production purposes. The framework
is, after all trying its best to promote best practices while
preventing you from having to know how all the sausage is made.

Secondly, it is almost guaranteed that you will eventually want
a domain name for your production service - whether it is an
internally facing microservice or an externally facing web
application.

Creating an alias in Route 53 for your domain pointing to the ALB
ensures you don't need to update application configurations with the
service's dynamic IP address. Additionally, using a load balancer
allows you to create custom routing rules to your service. If you want
to run multiple tasks for your service to support handling more
traffice a load balancer is required.

With those things in mind the framework automatically uses an ALB for
HTTP services and creates an alias record (A) for your domain for both
internal and external facing services.

=head2 AWS WAF Support

For external-facing HTTPS services, C<App::FargateStack> can automate
the creation and association of an AWS Web Application Firewall (WAF)
to provide an essential layer of security. This protects your
application from common web exploits and bots that could affect
availability or compromise security.

The framework follows a "Hybrid Management Model" for WAF, designed to
provide a secure, sensible baseline out-of-the-box while giving you
full control over fine-grained rule customization.

=head3 Enabling WAF Protection

To enable WAF, simply add a C<waf> block with C<enabled: true> to your
C<alb> configuration:

  alb:
    # ... existing alb configuration ...
    waf:
      enabled: true

=head3 Configuring Managed Rules

To simplify configuration, C<App::FargateStack> uses a keyword-based
system for enabling AWS Managed Rule Groups. You can specify a list of
keywords under the C<managed_rules> key in your C<waf> configuration.

If the C<managed_rules> key is omitted, the framework will apply the
C<default> bundle, which provides a strong and cost-effective security
baseline.

  waf:
    enabled: true
    managed_rules: [linux-app, admin, -php]

The framework supports both individual rule sets and pre-configured
"bundles" for common application types. It also supports a subtractive
syntax (prefixing a keyword with a C<->) to remove rule sets from a
bundle.

=head4 Rule Set Keywords

=over 4

=item * B<base>: A strong baseline including C<AWSManagedRulesCommonRuleSet>, C<AWSManagedRulesAmazonIpReputationList>, and C<AWSManagedRulesKnownBadInputsRuleSet>.

=item * B<admin>: Protects exposed administrative pages (C<AWSManagedRulesAdminProtectionRuleSet>).

=item * B<sql>: Protects against SQL injection attacks (C<AWSManagedRulesSQLiRuleSet>).

=item * B<linux>: Includes rules for Linux and Unix-like environments.

=item * B<php>: Includes rules for applications running on PHP.

=item * B<wordpress>: Includes rules specific to WordPress sites.

=item * B<windows>: Includes rules for Windows Server environments.

=item * B<anonymous>: B<Use with caution.> Blocks traffic from anonymous sources like VPNs and proxies, which may block legitimate users.

=item * B<ddos>: Mitigates application-layer (Layer 7) DDoS attacks like HTTP floods.

=item * B<premium>: B<Warning: Extra Cost.> Enables advanced, paid protections for bot control and account takeover prevention.

=back

=head4 Rule Bundles

=over 4

=item * B<default>: Includes C<base> and C<sql>. This is the recommended starting point for most applications.

=item * B<linux-app>: Includes C<default> and C<linux>.

=item * B<wordpress-app>: Includes C<default>, C<linux>, and C<wordpress>.

=item * B<windows-app>: Includes C<default> and C<windows>.

=item * B<all>: Includes all standard, non-premium rule sets. B<Warning:> This will likely exceed the default WCU quota and may incur additional costs.

=back

=head3 The Bootstrap Process (First Run)

On the first C<apply> run with WAF enabled, the framework will perform
a one-time bootstrap:

=over 4

=item 1.

It generates a default F<web-acl.json> file in your project
directory. This file contains the complete definition of your Web ACL,
including the rules generated from your C<managed_rules> keywords.

=item 2.

It calls C<aws wafv2 create-web-acl> to create a new Web ACL.

=item 3.

It calls C<aws wafv2 associate-web-acl> to link the new Web ACL to
your Application Load Balancer.

=item 4.

It updates your configuration file with the state of the new
WAF resources, including its Name, ID, ARN, LockToken, and a checksum
of the F<web-acl.json> file.

=item 5.

The C<waf> block in your F<fargate-stack.yml> is updated to reflect
the bootstrapped state. If the C<managed_rules> key was not present,
it will be added with the default value of C<[default]>.

=back

=head3 Ongoing Management (Subsequent Runs)

After the initial creation, you take full control of the rules. To
add, remove, or modify rules, you simply edit the F<web-acl.json> file
directly.

On subsequent runs of C<apply>, C<App::FargateStack> will:

=over 4

=item *

Calculate a checksum of your F<web-acl.json> file.

=item *

If the checksum has changed, it will safely update the remote Web ACL
with your new rule set.

=item *

If the checksum has not changed, it will skip the update to avoid
unnecessary API calls.

=back

This model gives you the best of both worlds: the "minimal
configuration, maximum results" of a secure default, and the full
"transparent box" control to customize your security posture as your
application's needs evolve.

=head3 Conflict and Drift Management

The framework includes robust safety checks to prevent accidental data
loss. If it detects that the Web ACL has been modified in the AWS
Console I<and> you have also modified your local F<web-acl.json> file,
it will detect the state conflict, refuse to make any changes, and
provide a clear error message with instructions on how to resolve it.

=head3 Estimated Cost

The default WAF configuration is designed to provide a strong security
baseline while remaining cost-effective. When you enable WAF without
specifying any C<managed_rules>, the framework applies the C<default>
bundle, which includes the C<base> and C<sql> rule sets.

The approximate monthly cost for this default configuration is
B<~$9.00 per month>, plus per-request charges.

The cost is broken down as follows:

=over 4

=item * B<$5.00 / month> for the Web ACL itself.

=item * B<$4.00 / month> for the four AWS Managed Rule Groups included
in the C<default> bundle (3 in 'base', 1 in 'sql').

=item * B<$0.60 / per 1 million requests> processed by the Web ACL.

=back

B<Warning:> Enabling the C<premium> rule set will incur significant
additional monthly and per-request fees for services like Bot Control
and Account Takeover Prevention. Always review the L<AWS WAF
pricing|https://aws.amazon.com/waf/pricing/> page before enabling
premium features.

=head2 Roadmap for HTTP Services

=over 4

=item * path based routing on ALB listeners

=back

=head1 AUTOSCALING

=head2 Overview

For services that experience variable load, such as HTTP applications or
background job processors, C<App::FargateStack> can automate the process of
scaling the number of running tasks up or down to meet demand. This ensures
high availability during traffic spikes and saves costs during quiet periods.

The framework integrates with AWS Application Auto Scaling to provide target
tracking scaling policies. This allows you to define a target metric - such as
average CPU utilization or the number of requests per minute - and the framework
will automatically manage the number of Fargate tasks to keep that metric at
your desired level.

=head2 Enabling Autoscaling

To enable autoscaling for a service, add an C<autoscaling> block to its task
configuration in your .yml configuration file.

tasks:
  my-service:
    # ... other task settings ...
    autoscaling:
      min_capacity: 1
      max_capacity: 10
      cpu: 60

=head2 Configuration Parameters

The C<autoscaling> block accepts the following keys:

=over

=item * B<min_capacity> (Required)

The minimum number of tasks to keep running at all times. The service will
never scale in below this number.

=item * B<max_capacity> (Required)

The maximum number of tasks that the service can scale out to. This acts as
a safeguard to control costs.

=item * B<cpu> OR B<requests> (Required, mutually exclusive)

You must specify exactly one scaling metric.

=over

=item * C<cpu>: The target average CPU utilization percentage across all tasks in
the service. Valid values are between 1 and 100.

=item * C<requests>: The target number of requests per minute for each task. This
is only valid for tasks of type C<http> or C<https> that are behind an
Application Load Balancer.

=back

=item * B<scale_in_cooldown> (Optional)

The amount of time, in seconds, to wait after a scale-in activity before
another scale-in activity can start. This prevents the service from scaling
in too aggressively.

Default: C<300>

=item * B<scale_out_cooldown> (Optional)

The amount of time, in seconds, to wait after a scale-out activity before
another scale-out activity can start. This allows new tasks time to warm up
and start accepting traffic before the service decides to scale out again.

Default: C<60>

=item * B<policy_name> (Managed by CApp::FargateStack)

This is a unique name for the scaling policy generated by the framework. It
is written to your configuration file and used to detect drift between your
configuration and the live environment in AWS. You should not modify this
value.

=back

=head2 Example: Scaling on CPU Utilization

This configuration will maintain at least 1 task, scale up to a maximum of 5
tasks, and will add or remove tasks to keep the average CPU utilization at or
near 60%.

 tasks:
   my-cpu-intensive-worker:
     type: daemon
     image: my-worker:latest
     autoscaling:
       min_capacity: 1
       max_capacity: 5
       cpu: 60

=head2 Example: Scaling on ALB Requests

This configuration will maintain at least 2 tasks, scale up to a maximum of 20
tasks, and will add or remove tasks to keep the number of requests per minute
for each task at or near 1000. It also specifies custom cooldown periods.

 tasks:
   my-website:
     type: https
     image: my-website:latest
     autoscaling:
       min_capacity: 2
       max_capacity: 20
       requests: 1000
       scale_in_cooldown: 600
       scale_out_cooldown: 120

=head2 Scheduled Scaling Configuration

To configure predictive, time-based scaling, add a C<scheduled> block
inside the main C<autoscaling> configuration. This allows you to
define named time windows for scaling.

Example:

 autoscaling:
   ...
   scheduled:
     business_hours:
       start_time: 00:18
       end_time: 00:02
       min_capacity: 2/1
       max_capacity: 3/2

I<Note: B<start_time> and B<end_time> are UTC>

=over

=item * B<scheduled> (Optional)

A hash where each key is a unique, descriptive name for the schedule
group (e.g., C<business_hours>). Each group defines a time window and
the capacity changes for that window.

=over

=item * B<start_time> (Required): The time to scale up, in HH:MM
format (24-hour clock, UTC).

=item * B<end_time> (Required): The time to scale down, in HH:MM
format (24-hour clock, UTC).

=item * B<days> (Required): The days of the week for the schedule. Can
be a range (e.g., C<MON-FRI>) or comma-separated values.

=item * B<min_capacity> (Optional): The minimum capacity during and
outside the window. The two values should be separated by a slash,
comma, colon, hyphen, or space (e.g., C<2/1> or C<2,1>).

=item * B<max_capacity> (Optional): The maximum capacity during and
outside the window, using the same C<in/out> format as
C<min_capacity>.

=back

=back

The parser will generate two scheduled actions from this block: one to
apply the "in" capacity at the C<start_time> and one to apply the
"out" capacity at the C<end_time>.

=head2 Example: Combined Metric and Scheduled Scaling

This configuration creates a robust scaling strategy. The service will
reactively scale based on CPU load at all times, but the capacity
"guardrails" will be adjusted automatically for business hours.

 tasks:
   my-website:
     type: https
     image: my-website:latest
     autoscaling:
       # Default metric-based scaling policy
       min_capacity: 1
       max_capacity: 10
       cpu: 75
 
       # Scheduled scaling actions to adjust the guardrails
       schedule:
         business_hours:
           start_time: "09:00"
           end_time: "18:00"
           days: MON-FRI
           min_capacity: 2/1
           max_capacity: 10/2

=head2 Drift Detection and Management

CApp::FargateStack treats your YAML configuration as the single source of
truth. On every C<plan> or C<apply> run, it will compare the C<autoscaling>
configuration in your file with the live scaling policy in AWS.

If it detects any differences (e.g., someone manually changed the max capacity
in the AWS Console), it will report the drift and will not apply any changes.
To overwrite the live settings and enforce the configuration from your file,
you must re-run the C<apply> command with the C<--force> flag. This provides a
critical safety check against accidental configuration changes.

=head3 The C<autoscaling> keyword

For any service type (C<https>, C<http>, C<daemon>, or C<task>), you can enable
and configure autoscaling directly from the command line. This provides a
quick-start method to make your service elastic from the moment it's created.

The Cautoscaling: keyword accepts a metric and an optional target value:

=over

=item * B<Enable with a specific target value:>

autoscaling:requests=500
autoscaling:cpu=60

This will enable autoscaling and set the target for either ALB requests per
task or average CPU utilization.

=item * B<Enable with default target value:>

autoscaling:requests
autoscaling:cpu

If you omit the target value, a sensible default will be used (e.g.,
C<500> for requests, C<60> for CPU).

=back

When the C<create-stack> command sees the Cautoscaling: keyword, it
will generate a complete C<autoscaling> block in your F<fargate-stack.yml>
file. This block will be populated with safe defaults (C<min_capacity: 1>,
C<max_capacity: 2>), the specified metric, and all other necessary fields,
making it easy to review and customize later. See L<"AUTOSCALING"> for
a full list of configuration options.

=head1 CURRENT LIMITATIONS

=over 4

=item * Stacks may contain multiple daemon services, but only one task
may be exposed as an HTTP/HTTPS service via an ALB.

=item * Limited configuration options for some resources such as
advanced load balancer listener rules, custom CloudWatch metrics, or
task health check tuning.

=item * Some out of band infrastructure changes may break the ability
to re-run C<app-FargateStack> without manually updating the
configuration

=item * Support for only 1 EFS filesystem per task

=item * This framework assumes that the
L<operatingSystemFamily|https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters_ec2.html#runtime-platform_ec2>
is "LINUX" and the C<cpuArchitecture> is "X86_64" LINUX. This is
unlikely to change.

=back

=head1 TROUBLESHOOTING

=head2 Warning: task placed in a public subnet

When running a task you may see:

  [2025/08/05 03:40:58] run-task: subnet-id: [subnet-7c160c37] is in a public subnet...consider running your jobs in a private subnet

This means the task is being scheduled in a subnet that has a
0.0.0.0/0 route to an Internet Gateway (a public subnet).

While not fatal, placing tasks in public subnets is discouraged unless
you have a specific need.

=head3 Why this matters

Running tasks in public subnets can introduce risk and operational
surprises:

=over 4

=item * Accidental exposure

If the task is assigned a public IP and the security group allows
inbound access, it may be reachable from the internet.

=item * Unintended dependency

Public-subnet egress typically relies on a public IP and the Internet
Gateway. That can bypass intended egress controls, logging, or central
inspection.

=item * Narrow security margin

Safety depends entirely on security groups and NACLs. A small
misconfiguration can expose services or data.

=back

=head3 Recommended pattern

Use private subnets for most Fargate workloads. Private subnets do not
route directly to the internet.

If the task needs outbound access (for example, to pull images from
ECR or call external APIs), use one of:

=over 4

=item * A NAT Gateway (private subnet egress to the internet)

=item * VPC interface endpoints for ECR (ecr.api and ecr.dkr) and a
gateway endpoint for S3, so image pulls stay inside the VPC with no
public IPs

=back

For public-facing applications, the common pattern is: tasks in
private subnets, fronted by a public Application Load Balancer in
public subnets.

=head3 When is a public subnet acceptable?

Use a public subnet only when the task itself must have a public IP
and terminate client connections directly (uncommon). If you do:

=over 4

=item * Set assignPublicIp=ENABLED so the task can reach the internet
via the Internet Gateway

=item * Keep security groups locked down and monitor egress on TCP 443

=back

=head3 Note on image pulls

To pull from ECR, the task needs a path to ECR API, ECR DKR, and S3:

=over 4

=item * Public subnet: requires a public IP (assignPublicIp=ENABLED),
unless you provision VPC endpoints

=item * Private subnet: works via a NAT Gateway, or entirely private
via VPC endpoints (no public IPs)

=back

=head2 My task fails with this message:

 ResourceInitializationError: unable to pull secrets or registry auth:
 The task cannot pull registry auth from Amazon ECR: There is a
 connection issue between the task and Amazon ECR. Check your task
 network configuration. operation error ECR: GetAuthorizationToken,
 exceeded maximum number of attempts, 3, https response error
 StatusCode: 0, RequestID: , request send failed, Post
 "https://api.ecr.us-east-1.amazonaws.com/": dial tcp 44.213.79.10:443:
 i/o timeout

This error usually occurs when your task is launched in a subnet that
does not have outbound access to the internet. Internet access - or a
properly configured VPC endpoint - is required for Fargate to
authenticate with ECR and pull your container image.

=head3 Common causes

=over 4

=item * The task was placed in a public subnet but was not assigned a
public IP.

=item * The task was placed in a private subnet without access to a
NAT gateway or VPC endpoints.

=back

Even though the subnet may have a route to an Internet Gateway (i.e.,
it is technically a "public" subnet), if the task does not receive a
public IP, it cannot use that route to reach external services like
ECR or Secrets Manager.

=head3 How to fix it

=over 4

=item * If using public subnets, ensure the task is assigned a public
IP.

=item * If using private subnets, ensure a NAT gateway is available
and the subnet has a route to it.

=item * Alternatively, configure VPC endpoints for ECR, Secrets
Manager, and related services to avoid needing internet access
altogether.

=back

=head3 Note on Subnet Selection

C<App::FargateStack> attempts to prevent this situation by analyzing
your VPC configuration during planning. It categorizes subnets as
private or public and evaluates whether they provide the necessary
network access to launch a Fargate task successfully. The framework
warns if you attempt to use a subnet that lacks internet or endpoint
access.

=head2 My task failed to start and the reason is unclear

This is one of the most common and frustrating scenarios when working
with Fargate. You run C<start-service> or C<run-task>, the command
seems to succeed, but then the task quickly stops. The C<status>
command shows the desired count is 1 but the running count is 0, and
the logs are empty.

This often happens due to a B<resource initialization error>. The
problem isn't with your container image itself, but with the
infrastructure Fargate is trying to set up for it.

Common causes include:

=over 4

=item *

B<Networking Issues>: The task is in a subnet that can't pull the
image from ECR (e.g., no NAT Gateway or VPC endpoints).

=item *

B<Permissions Errors>: The task's IAM role is missing a required
permission.

=item *

B<EFS Mount Failures>: The task cannot mount an EFS volume, often due
to a misconfigured security group or incorrectly specified path.

=back

These errors are opaque because they happen deep inside the
AWS-managed environment. The high-level ECS API only reports a generic
failure, and since it's not an API call error, it won't appear in
CloudTrail.

=head3 The Solution: Finding the C<stoppedReason>

To solve this, C<App-FargateStack> provides an optional argument to
the C<list-tasks> command. By default, this command only shows
C<RUNNING> tasks. However, if you add the C<stopped> argument, it will
show recently stopped tasks and, most importantly, the reason they
stopped.

B<The Command:>

 app-FargateStack list-tasks stopped

This will display a table of stopped tasks, including a C<Stopped
Reason> column. This column often contains the detailed, multi-line
error message from the underlying AWS service that caused the failure,
giving you the exact information you need to debug the problem.

For example, if an EFS mount failed, the C<stoppedReason> might
contain:

 ResourceInitializationError: failed to invoke EFS utils
 commands... mount.nfs4: mounting failed, reason given by server: No
 such file or directory

This tells you immediately that the problem is with the EFS path, not
a generic "task failed" message.

=head2 Why is my task or service still using an old image?

This is one of the most common points of confusion when working with
ECS and Fargate.

You may have just built and pushed a new image to ECR using the same
tag (e.g. C<latest>), but when you launch a task or deploy a service,
ECS appears to continue using the old image.  Here's why.

=head3 One-off tasks: C<run-task> uses a fixed image digest

When you run a task using:

  app-FargateStack run-task my-task

ECS uses the exact task definition revision as registered. If the
image was specified using a tag like C<:latest>, ECS resolves that tag
once -- at the time the task starts -- and stores the resolved digest
(e.g. C<sha256:...>).

This means:

=over 4

=item *

Tasks launched this way will continue to run the old image, even if
the C<latest> tag in ECR now points to a newer image.

=item *

The only way to run a task with the new image is to register a new
task definition that references the updated image. You can force a new
task definition by registering the definition.

 app-FargateStack register my-task

=back

=head3 Services: C<create-service> and C<update-service> use frozen images too

When you create or update a service, ECS also resolves any image tags
to their current digest and stores that in the registered task
definition.

This means that ECS services are also tied to the image that existed
at the time of task definition registration.

If you push a new image to ECR using the same tag (e.g. C<:latest>),
the service will not automatically use it.  ECS does not re-resolve
the tag unless you explicitly tell it to.

=head3 C<--force-new-deployment> re-pulls image tags (if not pinned by digest)

If your task definition references the image by tag
(e.g. C<http-service:latest>), and not by digest, then running:

  app-FargateStack redeploy my-service

will cause ECS to:

=over 4

=item *

Stop the currently running tasks

=item *

Start new tasks using the same task definition revision

=item *

Re-resolve and pull the image tag from ECR

=back

This allows your service to pick up a newly pushed image without
registering a new task definition, as long as the task definition used
a tag (not a digest).

=head3 Confirm what your task definition is using

To see whether your task definition uses a tag or a digest, run:

  aws ecs describe-task-definition --task-definition my-task:42

Look at the C<image> field under C<containerDefinitions>. It will either be:

  image: http-service:latest     # tag -- will be re-resolved by --force-new-deployment
  image: http-service@sha256:... # digest -- frozen, cannot be re-resolved

=head3 Best practices

=over 4

=item *

Avoid using C<:latest> in production. Use immutable tags
(e.g. C<:v1.2.3>) or digests.

=item *

If you want to deploy a new image, the safest and most deterministic approach is to:

  - Build and push the image using a new tag or digest
  - Register a new task definition revision referencing that tag or digest
  - Update your service to use the new task definition

=item *

Use C<--force-new-deployment> only if your task definition uses a tag
and you want to re-resolve it without changing the task definition
itself.

=back

=head1 ROADMAP

=over 4

=item * Scaling configuration

=item * Service Connect, including certificates for internal HTTP services

=item * Multiple HTTP services

=item * Path based routing

=back

=head1 SEE ALSO

L<IPC::Run>, L<App::Command>, L<App::AWS>, L<CLI::Simple>

=head1 AUTHOR

Rob Lauer - rclauer@gmail.com

=head1 LICENSE

This script is released under the same terms as Perl itself.

=cut

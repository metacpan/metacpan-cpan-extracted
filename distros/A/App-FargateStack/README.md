# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
  * [Current Status of App::FargateStack](#current-status-of-appfargatestack)
  * [Caveats](#caveats)
  * [Features](#features)
* [METHODS AND SUBROUTINES](#methods-and-subroutines)
* [USAGE](#usage)
  * [Commands](#commands)
  * [Options](#options)
  * [Notes](#notes)
* [OVERVIEW](#overview)
  * [Additional Features](#additional-features)
  * [Minimal Configuration](#minimal-configuration)
  * [Web Applications](#web-applications)
  * [Adding or Changing Resources](#adding-or-changing-resources)
  * [Configuration as State](#configuration-as-state)
* [CLI OPTION DEFAULTS](#cli-option-defaults)
  * [Disabling and Resetting](#disabling-and-resetting)
  * [Notes](#notes)
* [COMMAND LIST](#command-list)
  * [Configuration File Naming](#configuration-file-naming)
  * [Command Logging](#command-logging)
  * [Command Descriptions](#command-descriptions)
    * [help](#help)
    * [add-autoscaling-policy](#add-autoscaling-policy)
    * [add-scaling-policy](#add-scaling-policy)
    * [add-scheduled-action](#add-scheduled-action)
    * [apply](#apply)
    * [create-stack](#create-stack)
      * [Service clause grammar](#service-clause-grammar)
      * [Output](#output)
      * [Options](#options)
      * [Exit Status](#exit-status)
      * [NOTES](#notes)
    * [deploy-service](#deploy-service)
    * [delete-daemon](#delete-daemon)
    * [delete-scheduled-task](#delete-scheduled-task)
    * [delete-task](#delete-task)
    * [delete-http-service](#delete-http-service)
    * [destroy](#destroy)
    * [disable-scheduled-task](#disable-scheduled-task)
    * [enable-scheduled-task](#enable-scheduled-task)
    * [list-tasks](#list-tasks)
    * [list-zones](#list-zones)
    * [logs](#logs)
    * [plan              ](#plan-)
    * [redeploy](#redeploy)
    * [register-task-definition](#register-task-definition)
    * [remove-service](#remove-service)
    * [run-task](#run-task)
    * [state](#state)
    * [status](#status)
    * [stop-task](#stop-task)
    * [stop-service](#stop-service)
    * [start-service](#start-service)
    * [tasks](#tasks)
    * [update-policy](#update-policy)
    * [update-service](#update-service)
    * [update-target](#update-target)
    * [version              ](#version-)
  * [Notes on Deletion of Resources](#notes-on-deletion-of-resources)
* [DEPLOYMENT WORKFLOW GUIDE](#deployment-workflow-guide)
  * [How to Use This Matrix](#how-to-use-this-matrix)
  * [Notes on the Workflow](#notes-on-the-workflow)
* [CLOUDWATCH LOG GROUPS](#cloudwatch-log-groups)
  * [Log Group Notes](#log-group-notes)
* [IAM PERMISSIONS](#iam-permissions)
  * [Task Execution Role vs. Task Role](#task-execution-role-vs-task-role)
* [SECURITY GROUPS](#security-groups)
* [FILESYSTEM SUPPORT](#filesystem-support)
  * [Field Descriptions](#field-descriptions)
  * [Additional Notes](#additional-notes)
* [CONFIGURATION](#configuration)
  * [GETTING STARTED](#getting-started)
    * [Step 1: Create a Configuration Stub](#step-1-create-a-configuration-stub)
    * [Step 2: Plan the Deployment (Dry Run)](#step-2-plan-the-deployment-dry-run)
    * [Step 3: Apply the Plan](#step-3-apply-the-plan)
    * [Step 4: Deploy and Start the Service](#step-4-deploy-and-start-the-service)
  * [VPC AND SUBNET DISCOVERY](#vpc-and-subnet-discovery)
  * [SUBNET SELECTION](#subnet-selection)
    * [Task placement and Availability Zones](#task-placement-and-availability-zones)
  * [REQUIRED SECTIONS](#required-sections)
  * [FULL SCHEMA OVERVIEW](#full-schema-overview)
* [TASK SIZE](#task-size)
* [ENVIRONMENT VARIABLES](#environment-variables)
  * [BASIC USAGE](#basic-usage)
  * [SECURITY NOTE](#security-note)
  * [INJECTING SECRETS FROM SECRETS MANAGER](#injecting-secrets-from-secrets-manager)
  * [BEST PRACTICES](#best-practices)
* [SQS QUEUES](#sqs-queues)
  * [BASIC CONFIGURATION](#basic-configuration)
  * [DEFAULT QUEUE ATTRIBUTES](#default-queue-attributes)
  * [DLQ DESIGN NOTE](#dlq-design-note)
  * [IAM POLICY UPDATES](#iam-policy-updates)
* [SCHEDULED JOBS](#scheduled-jobs)
  * [SCHEDULING A JOB](#scheduling-a-job)
  * [RUNNING AN ADHOC JOB](#running-an-adhoc-job)
  * [SERVICES VS TASKS](#services-vs-tasks)
* [S3 BUCKETS](#s3-buckets)
  * [BASIC CONFIGURATION](#basic-configuration)
  * [RESTRICTED ACCESS](#restricted-access)
  * [IAM-BASED ENFORCEMENT](#iam-based-enforcement)
  * [USING EXISTING BUCKETS](#using-existing-buckets)
* [HTTP SERVICES](#http-services)
  * [Overview](#overview)
  * [Key Assumptions When Creating HTTP Services](#key-assumptions-when-creating-http-services)
  * [Architecture](#architecture)
  * [Behavior by Task Type](#behavior-by-task-type)
  * [ACM Certificate Management](#acm-certificate-management)
  * [Port and Listener Rules](#port-and-listener-rules)
  * [Example Minimal Configuration](#example-minimal-configuration)
  * [Application Load Balancer](#application-load-balancer)
    * [Why Does the Framework Force the Use of a Load Balancer?](#why-does-the-framework-force-the-use-of-a-load-balancer)
  * [AWS WAF Support](#aws-waf-support)
    * [Enabling WAF Protection](#enabling-waf-protection)
    * [Configuring Managed Rules](#configuring-managed-rules)
      * [Rule Set Keywords](#rule-set-keywords)
      * [Rule Bundles](#rule-bundles)
    * [The Bootstrap Process (First Run)](#the-bootstrap-process-first-run)
    * [Ongoing Management (Subsequent Runs)](#ongoing-management-subsequent-runs)
    * [Conflict and Drift Management](#conflict-and-drift-management)
    * [Estimated Cost](#estimated-cost)
  * [Roadmap for HTTP Services](#roadmap-for-http-services)
* [AUTOSCALING](#autoscaling)
  * [Overview](#overview)
  * [Enabling Autoscaling](#enabling-autoscaling)
  * [Configuration Parameters](#configuration-parameters)
  * [Example: Scaling on CPU Utilization](#example-scaling-on-cpu-utilization)
  * [Example: Scaling on ALB Requests](#example-scaling-on-alb-requests)
  * [Scheduled Scaling Configuration](#scheduled-scaling-configuration)
  * [Example: Combined Metric and Scheduled Scaling](#example-combined-metric-and-scheduled-scaling)
  * [Drift Detection and Management](#drift-detection-and-management)
    * [The `autoscaling` keyword](#the-autoscaling-keyword)
* [CURRENT LIMITATIONS](#current-limitations)
* [TROUBLESHOOTING](#troubleshooting)
  * [Warning: task placed in a public subnet](#warning-task-placed-in-a-public-subnet)
    * [Why this matters](#why-this-matters)
    * [Recommended pattern](#recommended-pattern)
    * [When is a public subnet acceptable?](#when-is-a-public-subnet-acceptable)
    * [Note on image pulls](#note-on-image-pulls)
  * [My task fails with this message:](#my-task-fails-with-this-message)
    * [Common causes](#common-causes)
    * [How to fix it](#how-to-fix-it)
    * [Note on Subnet Selection](#note-on-subnet-selection)
  * [My task failed to start and the reason is unclear](#my-task-failed-to-start-and-the-reason-is-unclear)
    * [The Solution: Finding the `stoppedReason`](#the-solution-finding-the-stoppedreason)
  * [Why is my task or service still using an old image?](#why-is-my-task-or-service-still-using-an-old-image)
    * [One-off tasks: `run-task` uses a fixed image digest](#one-off-tasks-run-task-uses-a-fixed-image-digest)
    * [Services: `create-service` and `update-service` use frozen images too](#services-create-service-and-update-service-use-frozen-images-too)
    * [`--force-new-deployment` re-pulls image tags (if not pinned by digest)](#--force-new-deployment-re-pulls-image-tags-if-not-pinned-by-digest)
    * [Confirm what your task definition is using](#confirm-what-your-task-definition-is-using)
    * [Best practices](#best-practices)
* [ROADMAP](#roadmap)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
* [LICENSE](#license)
* [POD ERRORS](#pod-errors)
---
[Back to Table of Contents](#table-of-contents)

# NAME

App::FargateStack

[Back to Table of Contents](#table-of-contents)

# SYNOPSIS

    # Dry-run and analyze the configuration
    app-FargateStack plan -c my-stack.yml

    # Provision the full stack
    app-FargateStack apply -c my-stack.yml

[Back to Table of Contents](#table-of-contents)

# DESCRIPTION

**App::FargateStack** is a lightweight deployment framework for Amazon
ECS on Fargate.  It enables you to define and launch containerized
services with minimal AWS-specific knowledge and virtually no
boilerplate. Designed to simplify cloud infrastructure without
sacrificing flexibility, the framework lets you declaratively specify
tasks, IAM roles, log groups, secrets, and networking in a concise
YAML configuration.

By automating the orchestration of ALBs, security groups, EFS mounts,
CloudWatch logs, and scheduled or daemon tasks, **App::FargateStack**
reduces the friction of getting secure, production-grade workloads
running in AWS. You supply a config file, and the tool intelligently
discovers or provisions required resources.

It supports common service types such as HTTP, HTTPS, daemon, and cron
tasks, and handles resource scoping, role-based access, and health
checks behind the scenes.  It assumes a reasonable AWS account layout
and defaults, but gives you escape hatches where needed.

**App::FargateStack** is ideal for developers who want the power of ECS
and Fargate without diving into the deep end of Terraform,
CloudFormation, or the AWS Console.

## Current Status of App::FargateStack

_This is a work in progress._ Versions prior to 1.1.0 are considered usable
but may still contain issues related to edge cases or uncommon configuration
combinations.

This documentation corresponds to version 1.0.47.

The release of version _1.1.0_ will mark the first production-ready release.
Until then, you're encouraged to try it out and provide feedback. Issues or
feature requests can be submitted via
[GitHub](https://github.com/rlauer6/App-FargateStack/issues).

## Caveats

- The documentation may be incomplete or inaccurate.
- Features may change, and new ones will be added. See the
["ROADMAP"](#roadmap) for details.
- Deploying resources using this framework may result in AWS charges.
- This software is provided "as is", without warranty of any kind.
Use at your own risk.

## Features

- Minimal configuration: launch a Fargate service with just a task name
and container image
- Supports multiple task types: HTTP, HTTPS, daemon, cron (scheduled)
- Automatic resource provisioning: IAM roles, log groups, target groups,
listeners, etc.
- Discovers and reuses existing AWS resources when available (e.g.,
VPCs, subnets, ALBs)
- Secret injection from AWS Secrets Manager
- CloudWatch log integration with configurable retention
- Optional EFS volume support (per-task configuration)
- Public or private service deployment (via ALB in public subnet or
internal-only)
- Built-in service health check integration
- Automatic IAM role and policy generation based on configured resources
- Optional HTTPS support with ACM certificate discovery and creation
- Optional support for adding AWS WAF support for your HTTPS site
- Lightweight dependency stack: Perl, AWS CLI, a few CPAN modules
- Convenient CLI: start, stop, update, and tail logs for any service
- Scheduled and metric based autoscaling

[Back to Table of Contents](#table-of-contents)

# METHODS AND SUBROUTINES

This class is implemented as a modulino and is not designed for traditional 
object-oriented use. As such, this section is intentionally omitted.

[Back to Table of Contents](#table-of-contents)

# USAGE

## Commands

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

## Options

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

## Notes

- (1) Use the `--profile` option to override the profile defined in
the configuration file.

    _Note: The Route 53 service uses the same profile unless you specify
    `--route53-profile` or set a profile name in the `route53` section
    of the configuration file._

- (2) You can get help using the `--help` option or use the help
command with a subject or one of the commands.

        app-FargateStack help overview
        app-FargateStack help redeploy

    If you do not provide a subject then you will get the same information
    as `--help`. Use `help help` to get a list of available subjects.

- (3) You must log at least at the 'info' level to report
progress. This is set for you when your `plan` or `apply`.
- (4) By default an ECS service is NOT created for you by default
for daemon and http tasks. Instead, after creating all of the
necessary resources using `apply`, run `app-FargateStack
deploy-service task-name`. This will launch your service with a count
of 1 task. You can optionally specify a different count after the task
name.
- (5) You can tail or display a set of log events from a task's
log stream:

        app-Fargate logs [--log-wait] [--log-time] start end

    - --log-wait --no-log-wait (optional)

        Continue to monitor stream and dump logs to STDOUT

        default: --log-wait

    - --log-time, --no-log-time (optional)

        Output the CloudWatch timestamp of the message.

        default: --log-time

    - task-name

        The name of the task whose logs you want to view.

    - start

        Starting date and optionally time of the log events to display. Format can be one
        of:

            Nd => N days ago
            Nm => N minutes ago
            Nh => N hours ago

            mm/dd/yyyy
            mm/dd/yyyy hh:mm::ss

    - end

        If provided both start and end must date-time strings.

- (6) The default log level is 'info' which will create an audit
trail of resource provisioning. Certain commands log at the 'error'
level to reduce console noise. Logging at lower levels will prevent
potential useful messages from being displayed. To see the AWS CLI
commands being executed, log at the 'debug' level. The 'trace' level
will output the result of the AWS CLI commands.
- (7) Use `--skip-register` if you want to update a tasks target
rule without registering a new task definition. This is typically done
if for some reason your target rule is out of sync with your task
definition version.
- (8) To speed up processing and avoid unnecessary API calls the
framework considers the configuration file the source of truth and a
reliable representation of the state of the stack. If you want to
re-sync the configuration file set `--no-cache` and run `plan`. In
most cases this should not be necessary as the framework will
invalidate the configuration if an error occurs forcing a re-sync on
the next run of `plan` or `apply`.
- (9) `--no-update` is not permitted with `apply`. If you need a
dry plan without applying or updating the config, use `--dryrun` (and
optionally `--no-update`) with `plan`.
- (10) Set `--route53-profile` to the profile that has
permissions to manage your hosted zones. By default the script will
use the default profile.
- (11) Deleting a task, daemon, or http service will delete all of
the resources associated with that task.
    - For scheduled tasks you can disable the job from running instead of
    deleting its resources.
    - For services (daemons or HTTP services) you
    can stop them or delete the service (`delete-service`) instead of
    deleting all of the resources. 
    - These resources will **NOT** be removed:

            - ECR image associated with a task
            - An ACM certificate provisioned by App::FargateStack
- (12) This command will add a scaling policy to an HTTP, HTTPS or
daemon task. In order to apply the policy you must run `plan` &
`apply`. You provide the following arguments in order:

        [task-name] metric-type metric-value [min-capacity max-capacity [scale-out-cooldown scale-in-cooldown]]

    - `task-name` is optional if you only have 1 scalable task.
    - `min-capacity`, `max-capacity` are optional and will default to 1 and 2 respectively.
    - `scale-out-cooldown`, `scale-in-cooldown` are optional. If
    you provided you must include the capacity paramters.

            app-FargateStack apache requests 500 2 3 60 300

- (13) This command will add a schedule scaling action to your
configuration. In order to activate the schedule you must run `plan`
and `apply`. You provide the following arguments in order:

        [task-name] action-name start-time end-time days scale-out-capacity scale-in-capacity

    - `task-name` is optional if you only have 1 scalable task.
    - `action-name` is a name for your schedule. It must be
    unique within your entire configuration.
    - `start-time` is UTC. The format for the staring time is
    MM::HH. (Example: 00:18)
    - `days` is the day or days of the week for the scheduled action.

        _Note: Days should be one of MON,TUE,WED,THU,FRI,SAT or 1-7_

        Example:

        Scale out to 4 tasks at 10pm (EDT) for 30 minutes to run a batch job
        on Friday night.

            00:02 30:02 SAT 4/1 4/1

        _Note that the cron specification is in UTC, hence we run at 2am for
        30 minutes on Saturday morning in UTC._

    - `end-time` time t scale back in. Same format as `start-time`
    - `scale-out-capacity`, `scale-in-capacity` - These options
    represent the scale out and scale in capacities.

        Each value should be a tuple separated by '/', ',', ':' or '-'. The
        first value represents the minimum or maximum capacity for scaling out
        or in at the specified starting time of schedule action. The second
        value represents the minimum or maximum capacity for scaling in or out
        at the ending time of the action.

        Example to scale out to 2 tasks during business hours of 8:30am and
        5:30pm and scale in to 1 task during non-business hours.

            app-FargateStack add-scheduled-action business_hours 30:12 30:21 MON-FRI 2/1 2/1

        If you had a scaling policy, your scaling policies `max_capacity`
        must be greater than or equal to the largest maximum capacity of your
        all of you scheduled actions for that task.

            app-FargateStack add-scheduled-action business_hours 30:12 30:21 2/1 4/1

        In this case, your scaling policy `max_capacity` value must be at least
        4.

[Back to Table of Contents](#table-of-contents)

# OVERVIEW

_NOTE: This is a brief introduction to `App::FargateStack`. To see a 
list of topics providing more detail use the `help help` command._

The `App::FargateStack` framework, as its name implies provides
developers with a tool to create Fargate tasks and services. It has
been designed to make creating and launching Fargate based services as
simple as possible. Accordingly, it provides logical and pragmatic
defaults based on the common uses for Fargate based applications. You
can however customize many of the resources being built by the script.

Using a YAML based configuration file, you specify your required
resources and their attributes, run the `app-FargateStack` script and
launch your application.

Using this framework you can:

- ...build internal or external facing HTTP services that:
    - ...automatically provision certificates for external facing web applications
    - ...use an existing or create a new internal or external facing application load balancer (ALB).
    - ...automatically create an alias record in Route 53 for your domain
    - ...create a listener rule to redirect port 80 requests to 443 
- ...create queues and buckets to support your application
- ...use a dryrun mode to report the resources that will be built
before building them
- ...run `app-FargateStack` multiple times (idempotency)
- ...create daemon services
- ...create scheduled jobs
- ...execute adhoc jobs

## Additional Features

- inject secrets into the container's environment using a simple
syntax (See ["INJECTING SECRETS FROM SECRETS MANAGER"](#injecting-secrets-from-secrets-manager))
- detection and re-use of existing resources like EFS files systems, load balancers, buckets and queues
- automatic IAM role and policy generation based on configured resources
- define and launch multiple independent Fargate tasks and services under a single stack
- automatic creation of log groups with customizable retention period
- discovery of existing environment to intelligently populate configuration defaults
- automatically create a minimal Fargate app/service config from shorthand
- support for scheduled and metric based [autoscaling](#autoscaling)

## Minimal Configuration

Getting a Fargate task up and running requires that you provision and
configure multiple AWS resources. Stitching it together using
**Terraform** or **CloudFormation** can be tedious and time consuming,
even if you know what resources to provision AND how to stitch it
together.

The motivation behind writing this framework was to take the drudgery
of writing declarative resource generators for all of the resources required
to run a simple task, create basic web applications or RESTful
APIs. Instead, we wanted a framework that covered 90% of our use cases
while allowing our development workflow to go something like:

- Create a Docker image that implements our worker, web app or API
- Create a minimal configuration file that describes our application
- Execute the framework's script and create the necessary AWS infrastructure
- Launch the http server, daemon, scheduled job, or adhoc worker

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

_TIP: You can use the ["create-stack"](#create-stack) command to create minimal
configuration files for various Fargate application scenarios._

Using this minimal configuration and running `app-FargateStack` like this:

    app-FargateStack plan

...the framework would create the following resources in your VPC:

- a cluster named `my-stack-cluster`
- a security group for the cluster
- an IAM role for the the cluster
- an IAM  policy that has permissions enabling your worker
- an ECS task definition that describes your task
- a CloudWatch log group
- an EventBridge target event
- an IAM role for EventBridge
- an IAM policy for EventBridge
- an EventBridge rule that schedules the worker

...so as you can see, rolling all of this by hand could be a daunting
task and one made even more difficult when you decide to use other AWS
resources inside your task like buckets, queues or an EFS file
systems!

## Web Applications

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

- A certificate for your domain
- A Fargate cluster
- IAM roles and policies
- A listener and listener rules
- A CloudWatch log group
- Security groups
- A target group
- A task definition
- An ALB if one is not detected

Once again, launching a Fargate service requires a
lot of fiddling with AWS resources! Getting all of the plumbing
installed and working requires a lot of what and how knowledge.

## Adding or Changing Resources

Adding or updating resources for an existing application should also
be easy. Updating the infrastructure should just be a matter of
updating the configuration and re-running the framework's script. When
you update the configuration the `App::FargateStack` will detect the
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

See `app-Fargate help configuration` for more information about
resources and options.

## Configuration as State

The framework attempts to be as transparent as possible regarding what
it is doing, how long it takes, what the result was and most
importantly _what defaults were used during resource
provisioning_. Every time the framework is run, the configuration file
is updated based on any new resources provisioned or configured.  For
example, if you did not specify subnets, they are inferred by
inspecting your VPC and automatically added to the configuration file.

This gives you a single view into your Fargate application

[Back to Table of Contents](#table-of-contents)

# CLI OPTION DEFAULTS

When enabled, `App::FargateStack` automatically remembers the most recently
used values for several CLI options between runs. This feature helps streamline
repetitive workflows by eliminating the need to re-specify common arguments
such as the AWS profile, region, or config file.

The following options are tracked and persisted:

- `--profile`
- `--region`
- `--config`
- `--route53-profile`
- `--max-events`

These values are stored in `.fargatestack/defaults.json` within your current
project directory. If you omit any of these options on subsequent runs, the
most recently used value will be reused.

Typically, you would create a dedicated project directory for your
stack and place your configuration file there. Once you invoke a
command that includes any of the tracked CLI options, the
`.fargatestack/defaults.json` file will be created
automatically. Future commands run from that directory can then omit
those options. A typical workflow to create a new stack with a
scheduled job might look like this:

    mkdir my-project
    cd my-project
    app-FargateStack create-stack foo task:my-cron image:my-project 'schedule:cron(0 10 * * * *)'
    app-FargateStack plan
    app-FargateStack apply

That's it...you just created a scheduled job that will run at 10 AM every day!

## Disabling and Resetting

Use the `--no-history` option to temporarily disable this feature for a single
run. This allows you to override stored values without modifying or deleting
them.

To clear all saved defaults entirely, use the `reset-history` command. This
removes all of the tracked values from the `.fargatestack/defaults.json` file,
but preserves the file itself.

## Notes

Only explicitly provided CLI options are tracked. Values derived from
environment variables or configuration files are not saved.

This feature is enabled by default.

[Back to Table of Contents](#table-of-contents)

# COMMAND LIST

The basic syntax of the framework's CLI is:

    app-FargateStack command --config fargate-stack.yml [options] command-args

You must provide at least a command.

## Configuration File Naming

Your configuration file can be named anything, but by convention your
configuration file should have a `.yml` extension. If you don't
provide a configuration filename the default configuration file
`fargate-stack.yml` will be used. You can also set the
`FARGATE_STACK_CONFIG` environment variable to the name of your
configuration file.

## Command Logging

- Commands will generally produce log output at the default level
(`info`). You can see what AWS commands are being executed using the
`debug` level. If you'd like see the results of the AWS CLI commands use the
`trace` level.
- Commands that are expected to produce informational output
(e.g. `status`, `logs`, `list-tasks`, `list-zone`, etc) will log
at the `error` level which will eliminate log noise on the console.
- Logs are written to STDERR.
- The default is to colorize log
messages. Use `--no-color` if you don't like color.

## Command Descriptions

### help

    help [subject]

Displays basic usage or help on a particular subject. To see a list of
help subject use `help help`. The script will attemp to do a regexp
match if you do provide the exact help topic, so you can cheat and use
shortened versions of the topic.

    help cloudwatch

### add-autoscaling-policy

### add-scaling-policy

This command will add a scaling policy to an HTTP, HTTPS or
daemon task. In order to apply the policy you must run `plan` &
`apply`. You provide the following arguments in order:

    [task-name] metric-type metric-value [min-capacity max-capacity [scale-out-cooldown scale-in-cooldown]]

Example:

    app-FargateStack add-scaling-policy cpu 60 1 3

- task-name

    The task in your configuration that will contain the new scaling
    policy. This is optional if you only have 1 scalable task.

- metric-type (required)

    One of `cpu` or `requests`

- metric-value (required)

    The metric value. For `cpu` it should be an integer between 1 and
    100\. For `requests` it should be a count representing the number of
    requests your ALB receives per minute.

- min-capacity

    The minimum number of tasks to maintain.

    default: 1

- max-capacity

    The maximum number of tasks to scale up.

    default: 2

- scale-out-cooldown

    The number of seconds to wait before scaling up another task.

    default: 60

- scale-in-cooldown

    The number of seconds to wait until scaling down a task.

    default: 300 (5 minutes)

### add-scheduled-action

This command will add a schedule scaling action to your
configuration. In order to activate the schedule you must run `plan`
and `apply`. You provide the following arguments in order:

    [task-name] action-name start-time end-time days scale-out-capacity scale-in-capacity

- task-name (optional)

    The task in your configuration that will contain the new scheduled action configuration.
    This is optional if you only have 1 scalable task.

- action-name

    `action-name` is a name for your schedule. It must be
    unique within your entire configuration.

- start-time

    The starting time of the scheduled action as MM::HH (UTC).

        Example: 00:18

- end-time

    The time to scale back in. Same format as `start-time`.

- days

    The the day or days of the week for the scheduled action.

    _Note: Days should be one of MON,TUE,WED,THU,FRI,SAT or 1-7_

    Example 1:

    Scale out to 4 tasks at 10pm (EDT) for 30 minutes to run a batch job
    on Friday night.

        00:02 30:02 SAT 4/1 4/1

    _Note that the cron specification is in UTC, hence we run at 2am for
    30 minutes on Saturday morning in UTC._

- scale-out-capacity
- scale-in-capacity

    These options represent the scale out and scale in capacities.

    Each value should be a tuple separated by '/', ',', ':' or '-'. The
    first value represents the minimum or maximum capacity for scaling out
    or in at the specified starting time of schedule action. The second
    value represents the minimum or maximum capacity for scaling in or out
    at the ending time of the action.

    **Example 1:**

    To scale out to 2 tasks during business hours of 8:30am and 5:30pm and
    scale in to 1 task during non-business hours (with no metric based
    scaling policy):

        app-FargateStack add-scheduled-action business_hours 30:12 30:21 2/1 2/1

    _Note that without a scaling policy your minimum and maximum
    capacities for scaling in and out must be equal._

    **Example 2:**

    If your task includes a scaling policy, your scaling policy's `max_capacity`
    must be greater than or equal to the largest maximum capacity of your
    scheduled action.

        app-FargateStack add-scheduled-action business_hours 30:12 30:21 2/1 3/1

    In this case, your scaling policy `max_capacity` value must be at least
    4\. You `autoscaling:` section will look like this:

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

**Note:**

_Scheduled actions are only for HTTP, HTTPS and daemon tasks. If you
need to run a one-shot job at a particular time use a [scheduled
task](#scheduled-jobs)._

### apply

Reads the configuration file and determines what actions to perform
and what resources will be built.  Builds resources incrementally and
updates configuration file with resource details.

### create-stack

    create-stack app-name service-clauses...

Parses a compact, positional CLI grammar and emits a ready-to-edit YAML
configuration for your Fargate framework. The command **does not** create any
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

#### Service clause grammar

Each service is introduced by `<type>:<name>` followed by its required
key:value pairs. You may specify multiple services in one command.

_Note: You must start each task definition set with a task type (one of
daemon, task, scheduled, http or https)._

Valid `type` values and minimum keys:

- `environment`

        environment:RUN_ONCE=1

    Sets an environment variable in the task. You can use `env:` as an
    abbreviation for `environment:`.

- `task`

        task:<name> image:<repo[:tag]>

    Non-daemon task that can be run on demand.

- `http`

        http:<name> image:<repo[:tag]> domain:<fqdn>

    ALB-backed HTTP service.

- `https`

        https:<name> image:<repo[:tag]> domain:<fqdn>

    ALB-backed HTTPS service (certificate discovery/validation is out of scope for
    this command; see the env checker).

- `scheduled`

        scheduled:<name> image:<repo[:tag]> schedule:<expr>

    EventBridge-scheduled task. `schedule` must be a valid `cron(...)` or
    `rate(...`) expression. Quote it in the shell, for example:
    `'schedule:cron(0 10 * * * *)'`.

    _Note: You can use `task:` or `scheduled:` to indicate a scheduled task
    as long as you include a `schedule:` term._

- `daemon`

        daemon:<name>

    Long-running service without a load balancer.

- `image`

        image:<repo[:tag]>

    If `image` is given as `repo[:tag]` without a registry host:

    - The command _assumes_ the image lives in the current account's ECR and will
    format the Docker reference as:

            <account_id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>

    - If ECR lookup does not find the repository+tag, the tool emits a warning and
    leaves the image string as-is (allowing public registries like Docker Hub to
    work). This preserves convenience while making the fallback explicit.
    - Fully-qualified images (e.g., `public.ecr.aws/namespace/image:tag`,
    `docker.io/library/nginx:1.27`) are accepted as-is.

- `autoscaling`

        autoscaling:cpu|request[=value]

    For services of type `https`, `http`, or `daemon`, you can enable
    and configure autoscaling directly from the command line. This provides a
    quick-start method to make your service elastic from the moment it's created.

    The `autoscaling:` keyword accepts a metric and an optional target value:

    - **Enable with a specific target value:**

            autoscaling:requests=500
            autoscaling:cpu=60

        This will enable autoscaling and set the target for either ALB requests per
        task or average CPU utilization.

    - **Enable with default target value:**

            autoscaling:requests
            autoscaling:cpu

        If you omit the target value, a sensible default will be used (e.g.,
        `500` for requests, `60` for CPU).

    When the `create-stack` command sees the `autoscaling:` keyword, it
    will generate a complete `autoscaling` block in your configuration
    file. This block will be populated with safe defaults (`min_capacity: 1`,
    `max_capacity: 2`), the specified metric, and all other necessary fields,
    making it easy to review and customize later. See ["AUTOSCALING"](#autoscaling) for
    a full list of configuration options.

- `waf`

        waf:true|enabled|default|rule...

    For `https` services, you can enable and configure an AWS Web
    Application Firewall (WAF) directly from the command line. This
    provides a powerful shortcut to bootstrapping a secure,
    production-ready WAF with minimal configuration.

    The `waf:` keyword is highly flexible and accepts several forms:

    - **Enable with defaults:**

            waf:true
            waf:enabled
            waf:default

        Any of these will enable WAF and apply the `default` managed rule
        bundle, which provides a strong security baseline including
        protections against the OWASP Top 10 and SQL injection.

    - **Enable with specific rule sets:**

        You can specify a comma-separated list of rule set keywords. This
        allows you to tailor the protection to your application's specific
        needs from the very first command.

            waf:base,php,admin

    - **Enable with bundles and subtractive syntax:**

        For more complex configurations, you can use pre-configured bundles
        and the subtractive syntax (prefixing a keyword with a `-`) to remove
        unwanted rule sets.

            waf:all,-windows,-php

    When the `create-stack` command sees the `waf:` keyword, it will
    automatically generate the corresponding `waf` block in your
    `fargate-stack.yml` file, including `enabled: true` and the
    specified `managed_rules`. See ["Configuring Managed Rules"](#configuring-managed-rules) for a
    full list of available keywords and bundles.

    For more information see ["AWS WAF Support"](#aws-waf-support).

#### Output

Emits YAML to STDOUT that includes:

- `account`, `profile`, `region`
- `app.name` set from the first positional `<app-name>`
- Optional `domain` (for HTTP/HTTPS stacks)
- `tasks` map keyed by service `<name>` with fields such as `type`,
`image`, and `schedule` (when applicable)

#### Options

- **--route53-profile** _STR_

    AWS profile to use when performing Route 53 API calls. Many environments
    use a separate account for DNS management; this option lets you target
    that account. If not provided, the tool uses **--profile**.

    This option is only consulted when the command needs Route 53 (for example,
    HTTP/HTTPS stacks that require hosted zone lookups or record creation).

- **--dns-profile** _STR_

    Alias for **--route53-profile**.

- **--region** _STR_

    AWS region used when expanding ECR shorthand.

- **--out** _FILE_

    Write YAML to a file instead of STDOUT.

- **--force**

    Proceed even if some validations warn (for example, missing ECR repo).

#### Exit Status

    0 on success
    non-zero on argument or validation errors

#### NOTES

- This command generates config; it does not deploy. Run your normal "plan/apply"
flow after reviewing the YAML.
- For HTTP/HTTPS, `domain:` is required at creation time in this shorthand.
- Always quote `schedule:...` to avoid shell interpretation of parentheses.

### deploy-service

    deploy-service service-name

When you provision an HTTP, HTTPS, or daemon service, the framework
sets up all the necessary infrastructure components -- but it **does not**
automatically create and start the ECS service.

Use this command to start the service:

    app-FargateTask deploy-service service-name

If you want to start multiple tasks for the service, you can include a
count argument:

    app-FargateTask deploy-service service-name 2

### delete-daemon

    delete-daemon task-name

Deletes the AWS resources associated with a task of type
`daemon`. Consider removing the service
(["remove-service"](#remove-service)) or stopping the service
(["stop-service"](#stop-service)) if you do not want to delete the actual
resources.

See ["Notes on Deletion of Resources"](#notes-on-deletion-of-resources) for additional details.

### delete-scheduled-task

    delete-scheduled-task task-name

Deletes the AWS resources associated with a task of type `task` that
includes a `schedule:` key.

See ["Notes on Deletion of Resources"](#notes-on-deletion-of-resources) for additional details.

### delete-task

    delete-task task-name

Deletes the AWS resources associated with a task of type `task`.

See ["Notes on Deletion of Resources"](#notes-on-deletion-of-resources) for additional details.

### delete-http-service

Deletes the AWS resources associated with a task of type `http` or `https`.

If the Application Load Balancer (ALB) used by the service was
provisioned by `App::FargateStack`, it will be automatically
deleted. However, if the ALB was discovered but not created by
`App::FargateStack`, it will be preserved. In that case, only the listener
rules provisioned by `App::FargateStack` will be removed.

This command will also not delete any ACM certificate that was
provisioned by `App::FargateStack`.

See ["Notes on Deletion of Resources"](#notes-on-deletion-of-resources) for additional details.

### destroy

Removes all resources provisioned by App::FargateStack. This command
will confirm deletion before removing any resources. Use `--force` to
prevent confirmation.  Use `--confirm-all` to confirm deletion of
every resource.

After this command is executed a skeleton of the tasks will
remain. You can run `--plan` again and then `--apply` to reprovision
the stack.

### disable-scheduled-task

    disable-scheduled-task task-name

Use this command to disable a scheduled task.

If you omit `task-name`, the command will attempt to determine the
target task selecting the task of type `task` with a defined
`schedule:` key but only if exactly one such task is defined in
your configuration file.

### enable-scheduled-task

    enable-scheduled-task task-name

Use this command to enable a scheduled task.

If you omit `task-name`, the command will attempt to determine the
target task selecting the task of type `task` with a defined
`schedule:` key but only if exactly one such task is defined in
your configuration file.

### list-tasks

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

### list-zones

    list-zones domain-name

This command will list the hosted zones for a specific domain. The
framework automatically detects the appropriate hosted zone for your
domain if the `zone_id:` key is missing from your configuration when
you have an HTTP or HTTPS task defined.

Example:

    app-FargateStack list-zones --profile prod

### logs

    logs start-time end-time

To view your log streams use the `logs` command. This command will
display the logs for the most recent log stream in the log group. By
default the start time is the time of the first event.

- Use `--log-wait` to continuously poll the log stream.
- Use `--no-log-time` if your logs already have timestamps and do
not want to see CloudWatch timestamps. This is useful when you are
logging time in your time zone and do not want to be confused seeing
times that don't line up.
- `start-time` can be a "Nh", "Nm", "Nd" where N is an integer
and h=hours ago, m=minutes ago and d=days ago.
- `start-time` and `end-time` can be "mm/dd/yyyy hh:mm:ss" or just "mm/dd/yyyy"
- `end-time` must always be a date-time string.

### plan              

Reads the configuration file and determines what actions to perform
and what resources will be built. Only updates configuration file with
resource details but DOES NOT build them.

### redeploy

    redeploy service-name

Forces a new deployment of the specified ECS service without registering a new
task definition. This triggers ECS to stop the currently running task and
launch a new one using the same task definition revision.

If you omit `service-name`, the command will attempt to determine the
target service by selecting the task of type `daemon`, `http`, or
`https`, but only if exactly one such service is defined in your
configuration file.

If the task definition references an image by tag (such as `:latest`), this
command ensures ECS re-pulls the image from ECR at deployment time. This allows
you to deploy a newly pushed image without needing to create a new revision of
the task definition.

This command is especially useful when:

- You have pushed a new version of an image using the same tag (e.g. `:latest`)
- You want to roll the service without changing other configuration
- You want to confirm ECS tasks are using the most up-to-date image tag from ECR

Note that if your task definition references an image by digest
(e.g. `@sha256:...`), ECS will continue to use that exact image. In that case,
you must register a new task definition to update the image.

For best results, use this command as a shortcut to avoid
`register-task`, `update-service` steps and only when your service's
task definition uses an image tag that can be re-resolved, such as
`:latest` or a CI-generated version tag.

### register-task-definition

    register-task-definition task-name

Creates a new task definition revision in ECS for the specified task.

Under normal circumstances, you should not need to run this command
manually. Task definitions are automatically registered when you
execute `plan` or `apply`.

This command is provided for exceptional cases where you need to force
a new revision using a previously generated task definition file.

**Warning:** You should not manually modify the generated file
(`taskdef-{task-name}.json`), as doing so may cause
`App::FargateStack` to lose track of your task's configuration.

### remove-service

    remove-service service-name

Deletes a running ECS service without removing any of the underlying
AWS resources.

If you simply want to stop the service temporarily, use the
`stop-service` command instead.

This command does not delete associated infrastructure such as the
target group, security group, or load balancer listener rules. To
delete those resources, see ["delete-daemon"](#delete-daemon) or
["delete-http-service"](#delete-http-service), depending on the task type.

### run-task

    run-task task-name

Launches a one-shot Fargate task. By default, the command waits for the
task to complete and streams the task's logs to STDERR. Use the `--no-wait`
option to launch the task and return immediately.

When you register a task definition, ECS records the image digest of the
image specified in your configuration file. If you later push a new image
tagged with the same name (e.g., `latest`) without updating the task
definition, ECS will continue to use the original image digest.

To detect this kind of drift, `app-FargateStack` records the image digest
at the time of task registration and compares it to the current digest
associated with the tag (typically `latest`) at runtime.

If the digests do not match, the default behavior is to abort execution
and warn you about the mismatch. To override this safety check and proceed
anyway, use the `--force` option.

### state

    state config-name

You can use this command to switch the default configuration that
`app-FargateStack` will use when run without arguments.

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

### status

    status service-name

Displays the status of a running service and its most recent event messages
in tabular form.

If you omit `service-name`, the command will attempt to determine the
target service by selecting the task of type `daemon`, `http`, or
`https`, but only if exactly one such service is defined in your
configuration file.

Use the `--max-events` option to control how many recent events are shown.
The default is 5.

### stop-task

    stop-task task-arn|task-id

Stops a running task. To get the task id, use the `list-tasks`
command.

### stop-service

    stop-service service-name

Stops a running service by setting its desire count to 0.

If you omit `service-name`, the command will attempt to determine the
target service by selecting the task of type `daemon`, `http`, or
`https`, but only if exactly one such service is defined in your
configuration file.

### start-service

    start-service service-name [count]

Start a service. `count` is the desired count of tasks. The default
count is 1.

If you omit `service-name`, the command will attempt to determine the
target service by selecting the task of type `daemon`, `http`, or
`https`, but only if exactly one such service is defined in your
configuration file.

### tasks

Displays a table that summarizes your stack resources.

### update-policy

    update-policy

Forces the framework to re-evaluate resources and align the
policy. Will not apply changes in `--dryrun` mode. Under normal
circumstances you should not need to run this command, however if you
find that your Fargate policy lacks permissions for resources you have
configure, this will make sure that all configured resources are
included in your policy.

If `update-policy` identifies a need to update your role policy, you
can view the changes before they are applied by running the `plan`
command at the `trace` log level.

    app-Fargate --log-level trace plan

### update-service

update-service \[service-name\]

Updates an ECS service's configuration to use the latest registered
task definition. This is the primary command for deploying any changes
to your application, including new container images, environment
variables, or resource allocations.

When an ECS service is launched, it is "pinned" to a specific revision
of a task definition (e.g., my-task:9). If you later push a new
container image or change the task's configuration in your
configuration file, the running service **will not** automatically pick up
those changes.

This command is the essential final step in the deployment process.

- If the service is running, this command will trigger a rolling
deployment to replace the existing tasks with new ones based on the
new task definition.
- If the service is stopped, this command updates its
configuration. The next time you run start-service, it will launch
tasks using the new task definition.

**When to use `update-service` vs. `redeploy`**

While both commands can result in a new deployment, they serve
different purposes:

Use `update-service` when you have made any change to your
configuration file that affect the task definition. This is the
correct command for deploying a new image, adding environment
variables, injecting secrets, changing CPU/memory, or adding EFS mount
points. The workflow is:

Update your configuration file.

Run `app-FargateStack register-task-definition task-name`

Run `app-FargateStack update-service task-name`

Use `redeploy` as a shortcut only when you have pushed a new image using
the same tag (e.g., :latest) and have made no other configuration
changes. redeploy forces a new deployment using the existing task
definition, which is simpler but will not apply any other updates.

The status command can help you detect drift by showing if the running
task definition is out of sync with your latest configuration.

### update-target

    update-target task-name

Updates an EventBridge rule and rule target. For tasks of type "task"
(typically scheduled jobs) when you change the schedule the rule must
be deleted, re-created and associated with the target task. This
command will detect the drift in your configuration and apply the
changes if not in `--dryrun` mode.

### version              

Outputs the current version of `App::FargateStack`.

## Notes on Deletion of Resources

- You will be prompted to confirm the operation before any task is
deleted.
- If the specified task is the only one defined in your configuration
file, its configuration will not be fully removed. Instead, the task's
provisioned resource ARNs and names will be deleted, leaving behind a
minimal configuration skeleton. This allows you to re-provision the
task later by running `plan` against the skeleton, avoiding the need
to recreate it from scratch.
- `App::FargateStack` does not delete ECR images associated with tasks.
- ACM certificates provisioned by `App::FargateStack` will not be
deleted.

[Back to Table of Contents](#table-of-contents)

# DEPLOYMENT WORKFLOW GUIDE

One of the most common questions when managing a stack is, "I changed
X, what command(s) do I need to run now?" This guide provides a
quick-reference matrix to help you choose the correct workflow for the
most common changes.

## How to Use This Matrix

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

## Notes on the Workflow

- `plan` is Your Best Friend: Before running apply or any command that
makes changes, it is always a good practice to run app-FargateStack
plan first. This will give you a dry-run preview of the changes and
help you catch any configuration errors.
- Why apply is Sometimes Needed: Changes that affect AWS
resources beyond the ECS task definition itself -- like IAM
permissions for a new secret, EventBridge rules for a new schedule, or
provisioning a new S3 bucket -- require running apply to create or
update that infrastructure.
- redeploy is a Shortcut: The redeploy command is a special
case. It's a convenient shortcut for the common scenario where you've
pushed a new image to the :latest tag and need to force a deployment
without changing the task definition itself. For all other changes,
the register-task and update-service workflow is the correct and safer
path.

[Back to Table of Contents](#table-of-contents)

# CLOUDWATCH LOG GROUPS

A CloudWatch log group is automatically provisioned for each
application stack. By default, the log group name is
/ecs/&lt;application-name>, and log streams are created per task.

For example, given the following configuration:

    app:
      name: my-stack
    ...
    tasks:
      apache:
        type: https

The framework will:

- ...create a log group named /ecs/my-stack
- ...configure the apache task to write log streams with a prefix
like my-stack/apache/\*

By default, the log group is set to retain logs for 14 days if
`retention_days` is not specified. You can override this by
specifying a custom retention period using the `retention_days` key
in the task's log\_group section:

    log_group:
      retention_days: 30

## Log Group Notes

- The log group is reused if it already exists.
- Only numeric values accepted by CloudWatch are valid for
retention\_days (e.g., 1, 3, 5, 7, 14, 30, 60, 90, etc.).
- You can customize the log group name by setting the name in
the `log_group:` section (not recommended).

        log_group:
          retention_days: 14
          name: /ecs/my-stack

- You can change the retention period by updating the
configuration file and re-running `apply`.
- To retain logs indefinitely, remove the `retention_days`
entry in your configuration file.

[Back to Table of Contents](#table-of-contents)

# IAM PERMISSIONS

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
`role:` key in the configuration. The task role is found under the
`task_role:` key. Role names and role policy names are automatically
fabricated for you from the name you specified under the `app:` key.

## Task Execution Role vs. Task Role

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

[Back to Table of Contents](#table-of-contents)

# SECURITY GROUPS

A security group is automatically provisioned for your Fargate
cluster.  If you define a task of type `http` or `https`, the
security group attached to your Application Load Balancer (ALB) is
automatically authorized for ingress to your Fargate task. This is a
rule allowing ALB-to-Fargate traffic.

[Back to Table of Contents](#table-of-contents)

# FILESYSTEM SUPPORT

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

Acceptable values for `readonly` are "true" and "false".

## Field Descriptions

- id:

    The ID of an existing EFS filesystem. The framework does not provision
    the EFS, but will validate its existence in the current AWS account
    and region.

- mount\_point:

    The container path to which the EFS volume will be mounted.

- path:

    The path on the EFS filesystem to map to your container's mount point.

- readonly:

    Optional. Set to `true` to mount the EFS as read-only. Defaults to
    `false`.

## Additional Notes

- The ECS role's policy for your task is automatically modified
to allow read/write EFS access. Set `readonly:` in your task's
`efs:` section to "true" if only want read support.
- Your EFS security group must allow access from private subnets
where the Fargate tasks are placed.
- No changes are made to the EFS security group; the framework
assumes access is already configured
- Only one EFS volume is currently supported per task configuration.
- EFS volumes are task-scoped and reused only where explicitly configured.
- The framework does not automatically provision an EFS
filesystem for you. The framework does however validate that the
filesystem exists in the current account and region.

[Back to Table of Contents](#table-of-contents)

# CONFIGURATION

The `App::FargateStack` framework defines your application stack
using a YAML configuration file. This file describes your
application's services, their resource needs, and how they should be
deployed. Then configuration is updated whenever your run `plan` or
`apply`.

## GETTING STARTED

The fastest way to get up and running with `App::FargateStack` is to
use the `create-stack` command to generate a configuration file,
inspect the deployment plan, and then apply it.

### Step 1: Create a Configuration Stub

First, generate a minimal YAML configuration file. The `create-stack`
command provides a shorthand syntax to do this. You only need to
provide an overall application name, a service type, a service name,
and the container image to use.

This command will create a file named `my-stack.yml` in your current
directory. Make sure you have your AWS profile configured in your
environment or pass it using the `--profile` option.

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

### Step 2: Plan the Deployment (Dry Run)

Next, run the `plan` command. This is a crucial step that acts as a
dry run. The framework will:

- Read your minimal configuration file.
- Intelligently discover resources in your AWS account (like your VPC and subnets).
- Determine what new resources need to be created (like IAM roles, a security group, an ECS cluster and a CloudWatch log group).
- Report a full plan of action without making any actual changes.
- Update your configuration file with the discovered values and
sensible defaults.

    app-FargateStack plan

After this command completes, your `my-stack.yml` file will be fully
populated with all the information needed to provision your stack.

### Step 3: Apply the Plan

Once you have reviewed the plan and are satisfied with the proposed
changes, run the `apply` command. This will execute the plan and
create all the necessary AWS resources.

    app-FargateStack apply

### Step 4: Deploy and Start the Service

The `apply` command creates all the necessary **infrastructure**, but
it does not start your service. This separation allows you to manage
your infrastructure and your application's runtime state
independently.

To create the ECS service and start your container, use the
`deploy-service` command.

    app-FargateStack deploy-service my-stack-daemon

By default, this will start one instance of your task. To check its
status, use the `status` command:

    app-FargateStack status my-stack-daemon

And to stop the service, simply run:

    app-FargateStack stop-service my-stack-daemon

To restart a stopped service, run:

    app-FargateStack start-service my-stack-daemon

## VPC AND SUBNET DISCOVERY

If you do not specify a `vpc_id` in your configuration, the framework will attempt
to locate a usable VPC automatically.

A VPC is considered usable if it meets the following criteria:

- It is attached to an Internet Gateway (IGW)
- It has at least one available NAT Gateway

If no eligible VPCs are found, the process will fail with an error. If multiple
eligible VPCs are found, the framework will abort and list the candidate VPC IDs.
You must then explicitly set the `vpc_id:` in your configuration to resolve
the ambiguity.

If exactly one eligible VPC is found, it will be used automatically,
and a warning will be logged to indicate that the selection was
inferred.

## SUBNET SELECTION

If no subnets are specified in the configuration, the framework will query all
subnets in the selected VPC and categorize them as either public or private.

The task will be placed in a private subnet by default. For this to succeed,
your VPC must have at least one private subnet with a route to a NAT Gateway,
or have appropriate VPC endpoints configured for ECR, S3, STS, CloudWatch Logs,
and any other services your task needs.

If subnets are explicitly specified in your configuration, the
framework will validate them and warn if they are not reachable or are
not usable for Fargate tasks.

### Task placement and Availability Zones

The framework places each task's ENI into exactly one subnet, which fixes
that task in a single AZ. A service can span multiple AZs by listing
subnets from at least two AZs.

What the framework does:

- Prefers private subnets

    If private subnets are defined in the configuration, tasks are placed
    there. If no private subnets are defined, the framework falls back to
    public subnets.

- Aligns ALB AZs with task placement

    When a load balancer is used, the framework enables the ALB in the same
    AZ set it selects for tasks (best practice). This is for resilience and
    to avoid unnecessary cross-AZ hops; it is not a hard technical requirement.

- Requires two subnets

    The configuration must specify at least two subnets in different AZs.
    If subnets are not specified, the framework attempts to discover them,
    but still requires at least two usable subnets (either both private or
    both public). If fewer than two are available, it errors with guidance.

Notes on internet access and ALBs:

- Internet-facing ALB

    An internet-facing ALB must be created in public subnets. Tasks may (and
    usually should) remain in private subnets behind it.

- Egress from private subnets

    For image pulls and outbound calls, use either a NAT Gateway in each AZ
    or VPC endpoints for ECR (api and dkr) and S3.

- Egress from public subnets

    If tasks are placed in public subnets without endpoints or NAT, they
    require `assignPublicIp=ENABLED` to reach ECR/S3.

## REQUIRED SECTIONS

At minimum, your configuration must include the following:

    app:
      name: my-stack

    tasks:
      my-task:
        image: my-image
        type: daemon | task | http | https

For task types `http` or `https`, you must also specify a domain name:

    domain: example.com

## FULL SCHEMA OVERVIEW

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

[Back to Table of Contents](#table-of-contents)

# TASK SIZE

To simplify task configuration, the framework supports a shorthand key called
`size` that maps to common CPU and memory combinations supported by Fargate.

If specified, the `size` parameter should be one of the following profile names:

    tiny     => 256 CPU, 512 MB memory
    small    => 512 CPU, 1 GB memory
    medium   => 1024 CPU, 2 GB memory
    large    => 2048 CPU, 4 GB memory
    xlarge   => 4096 CPU, 8 GB memory
    2xlarge  => 8192 CPU, 16 GB memory

When a `size` is provided, the framework will automatically populate the
corresponding `cpu` and `memory` values in the task definition. If you
manually specify `cpu` or `memory` alongside `size`, those manual values
will take precedence and override the defaults from the profile.

**Important:** If you change the `size` after an initial deployment, you should
remove any manually defined `cpu` and `memory` keys in your configuration.
This ensures that the framework can correctly apply the new profile values
without conflict.

If neither `size`, `cpu`, nor `memory` are provided, the framework will infer
a sensible default size based on the task type. For example:

    - "http" or "https" => "medium"
    - "task"            => "small"
    - "task" + schedule => "medium"
    - "daemon"          => "medium"

This behavior helps minimize configuration boilerplate while still providing
sane defaults.

[Back to Table of Contents](#table-of-contents)

# ENVIRONMENT VARIABLES

The Fargate stack framework allows you to define environment variables for each
task. These variables are included in the ECS task definition and made available
to your container at runtime.

Environment variables are specified under the `environment:` key within the task
configuration.

## BASIC USAGE

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
`secrets:` block for sensitive data.

This mechanism is ideal for non-sensitive configuration such as
runtime flags, environment names, or log levels.

## SECURITY NOTE

Avoid placing secrets (such as passwords, tokens, or private keys) directly in the
`environment:` section. That mechanism is intended for non-sensitive configuration
data.

To securely inject secrets into the task environment, use the `secrets:` section
of your task configuration. This integrates with AWS Secrets Manager and ensures
secrets are passed securely to your container.

## INJECTING SECRETS FROM SECRETS MANAGER

To inject secrets into your ECS task from AWS Secrets Manager, define a `secrets:`
block in the task configuration. Each entry in this list maps a Secrets Manager
secret path to an environment variable name using the following format:

    /secret/path:ENV_VAR_NAME

Example:

    task:
      apache:
        secrets:
          - /my-stack/mysql-password:DB_PASSWORD

This configuration retrieves the secret value from `/my-stack/mysql-password`
and injects it into the container environment as `DB_PASSWORD`.

Secrets are referenced via their ARN using ECS's native secrets mechanism,
which securely injects them without placing plaintext values in the task definition.

## BEST PRACTICES

Avoid placing secrets in the `environment:` block. That block is for non-sensitive
configuration values and exposes data in plaintext.

Use clear, descriptive environment variable names (e.g., `DB_PASSWORD`, `API_KEY`)
and organize your Secrets Manager paths consistently with your stack naming.

[Back to Table of Contents](#table-of-contents)

# SQS QUEUES

The Fargate stack framework supports configuring and provisioning a
single AWS SQS queue, including an optional dead letter queue (DLQs).

A queue is defined at the stack level and is accessible to all tasks
and services within the same stack. IAM permissions are automatically
scoped to include only the explicitly configured queue and its
associated DLQ (if any).

_Only one queue and one optional DLQ may be configured per stack._

## BASIC CONFIGURATION

At minimum, a queue requires a name:

    queue:
      name: fu-man-q

If you define `max_receive_count` in the queue configuration, a DLQ
will be created automatically. You can optionally override its name
and attributes using the top-level `dlq` key:

    queue:
      name: fu-man-q
      max_receive_count: 5

    dlq:
      name: custom-dlq-name

If you do not specify a `dlq.name`, the framework defaults to appending `-dlq` to
the main queue name (e.g., `fu-man-q-dlq`).

## DEFAULT QUEUE ATTRIBUTES

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

## DLQ DESIGN NOTE

A dead letter queue is not a special type - it is simply another queue used
to receive messages that have been unsuccessfully processed. It is modeled
as a standalone queue and defined at the top level of the stack configuration.

The `dlq` block is defined at the same level as `queue`, not nested within it.
If no overrides are provided, DLQ attributes default to AWS attribute defaults.

## IAM POLICY UPDATES

Adding a new queue to an existing stack will not only create the queue, but
also update the IAM policy associated with your stack to include permissions
for the newly defined queue and DLQ (if applicable).

[Back to Table of Contents](#table-of-contents)

# SCHEDULED JOBS

The Fargate stack framework allows you to schedule container-based jobs
using AWS EventBridge. This is useful for recurring tasks like report generation,
batch processing, database maintenance, and other periodic workflows.

A scheduled job is defined like any other task, using `type: task`, and
adding a `schedule:` key in AWS EventBridge cron format.

## SCHEDULING A JOB

To schedule a job, add a `schedule:` key to your task definition. The
value must be a valid AWS cron expression, such as:

    cron(0 2 * * ? *)   # every day at 2:00 AM UTC

Example:

    tasks:
      daily-report:
        type: task
        image: report-runner:latest
        schedule: cron(0 2 * * ? *)

_Note: All cron expressions are interpreted in UTC._

The framework will automatically create an EventBridge rule tied to
the task definition. When triggered, it will launch a one-off Fargate
task based on the configuration. The EventBridge rule is named using
the pattern "&lt;task>-schedule".

All scheduled tasks support environment variables, secrets, and other
standard task features.

## RUNNING AN ADHOC JOB

You can run a scheduled (or unscheduled) task manually at any time using:

    app-FargateStack run-task task-name

By default, this will:

- Launch the task using the defined image and configuration
- Wait for the task to complete (unless `--no-wait` is passed)
- Retrieve and print the logs from CloudWatch when the task exits

This is ideal for debugging, re-running failed jobs, or triggering
occasional maintenance tasks on demand.

## SERVICES VS TASKS

A task of type `daemon` is launched as a long-running ECS service
and benefits from restart policies and availability guarantees.

A task of type `task` is run using `run-task` and may run once,
forever, or periodically - but it will not be automatically restarted
if it fails.

[Back to Table of Contents](#table-of-contents)

# S3 BUCKETS

The Fargate stack framework supports creating a new S3 bucket or
using an existing one. The bucket can be used by your ECS tasks
and services, and the framework will configure the necessary IAM
permissions for access.

By default, full read/write access is granted unless you specify
restrictions (e.g., read-only or path-level constraints). In this model,
no bucket policy is required or modified.

_Note: Full access includes s3:GetObject, s3:PutObject, s3:DeleteObject, and
s3:ListBucket.  Readonly access is limited to s3:GetObject and
s3:ListBucket._

## BASIC CONFIGURATION

You define a bucket in your configuration like this:

    bucket:
      name: my-app-bucket

By default, this grants full read/write access to the entire bucket via the
IAM role attached to your ECS task definition.

## RESTRICTED ACCESS

You can limit access to a subset of the bucket using the `readonly:` and
`paths:` keys:

    bucket:
      name: my-app-bucket
      readonly: true
      paths:
        - public/*
        - logs/*

This will:

- Grant only `s3:GetObject` and `s3:ListBucket` permissions
- Limit access to the specified path prefixes

The `paths:` values are interpreted as S3 key prefixes and inserted
directly into the role policy.

If you specify `readonly: true` but omit `paths:`, read-only access will
apply to the entire bucket. If you omit both keys, full read/write access
is granted.

## IAM-BASED ENFORCEMENT

Bucket access is enforced exclusively through IAM role permissions. The
framework does not modify or require an S3 bucket policy. This keeps your
configuration simpler and avoids potential conflicts with externally
managed bucket policies.

## USING EXISTING BUCKETS

If you reference an existing bucket not created by the framework, be aware
that the bucket's own policy may still restrict access.

In particular:

- The IAM role created by the framework may permit access to a path
- But a bucket policy with an explicit `Deny` will override that and block access
- This restriction will only be discovered at runtime when your task attempts access

To avoid surprises, ensure that any bucket policy on an external bucket
permits access from the IAM role you're configuring.

[Back to Table of Contents](#table-of-contents)

# HTTP SERVICES

## Overview

To create a Fargate HTTP service set the `type:` key in your task's
configuration section to "http" or "https".

The task type ("http" or "https") determines:

- the **type of load balancer** that will be used or created
- whether or not a **certificate will be used or created**
- what **default port** will be configured in your ALB's listener
rule

## Key Assumptions When Creating HTTP Services

- Your domain is managed in Route 53 and your profile can create
Route 53 record sets.

    _Note: If your domain is managed in a different AWS account, set a
    separate `profile:` value in the `route53:` section of the
    configuration file.  Your profile should have sufficient permissions
    to manage Route 53 recordsets._

- Your Fargate task will be deployed in a private subnet and
will listen on port 80.
- No certificate will be provisioned for internal facing
applications. Traffic by default to internal facing applications
(those that use an internal ALB) will be insecure. _This may become
an option in the future._

## Architecture

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

## Behavior by Task Type

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

_NOTE: You must provide a domain name for both an internal and
external facing HTTP service. This also implies you must have a
both a **private** and **public** hosted zone for your domain._

Your task type will also determine which type of subnet is required
and where to search for an existing ALB to use. If you want to prevent
re-use of an existing ALB and force the creation of a new one use the
`--create-alb` option when you run your first plan.

In your initial configuration you do not need to specify the subnets
or the hosted zone id.  The framework will discover those and report
if any required resources are unavailable. If the task type is
"https", the script looks for a public zone, public subnets and an
internet-facing ALB otherwise it looks for a private zone, private
subnets and an internal ALB.

## ACM Certificate Management

If the task type is "https" and no ACM certificate currently exists
for your domain, the framework will automatically provision one. The
certificate will be created in the same region as the ALB and issued
via AWS Certificate Manager. If the certificate is validated  via DNS
and subsequently attached to the listener on port 443.

## Port and Listener Rules

For external-facing apps, a separate listener on port 80 is
created. It forwards traffic to port 443 using a default redirect rule
(301). If you do not want a redirect rule, set the `redirect_80:` in
the `alb:` section to "false".

If you want your internal application to listen on a port other than
80, set the `port:` key in the `alb:` section to a new port
value.

## Example Minimal Configuration

    app:
      name: http-test
    domain: http-test.example.com
    task:
      apache:
        type: http
        image: http-test:latest

Based on this minimal configuration `app-FargateStack` will enrich
the configuration with appropriate defaults and proceed to provision
your HTTP service.

To do that, the framework attempts to discover the resources required
for your service. If your environment is not compatible with creating
the service, the framework will report the missing resources and
abort the process.

Given this minimal configuration for an internal ("http") or
external ("https") HTTP service, discovery entails:

- ...determining your VPC's ID
- ...identifying the private subnet IDs
- ...determining if there is and existing load balancer with the
correct scheme
- ...finding your load balancer's security group (if an ALB exists)
- ...looking for a listener rule on port 80 (and 443 if type is
"https"), including a default forwarding redirect rule
- ...validating that you have a private or public hosted zone
in Route 53 that supports your domain
- ...setting other defaults for additional resources to be built (log
groups, cluster, target group, etc)
- ...determining if an ACM certificate exists for your domain
(if type is "https")

_Note: Discovery of these resources is only done when they are
missing from your configuration. If you have multiple VPCs for example
you can should explicitly set `vpc_id:` in the configuration to
identify the target VPC.  Likewise you can explicitly set other
resource configurations (subnets, ALBs, Route 53, etc)._

Resources are provisioned and your configuration file is updated
incrementally as `app-FargateStack` compares your environment to the
environment required for your stack. When either plan or
apply complete your configuration is updated giving you complete
insight into what resources were found and what resources will be
provisioned. See [CONFIGURATION](https://metacpan.org/pod/CONFIGURATION) for complete details on resource
configurations.>

Your environment will be validated against the criteria described
below.

- You have at least 2 private subnets available for deployment

    Technically you can launch a task with only 1 subnet but for services
    behind an ALB Fargate requires 2 subnets.

    _When you create a service with a load balancer, you must specify
    two or more subnets in different Availability Zones. - AWS Docs_

- You have a hosted zone for your domain of the appropriate type
(private for type "http", public for type "https")

As discovery progresses, existing and required resources are logged
and your configuration file is updated. If you are **NOT** running in
dryrun mode, resources will be created immediately as they are
discovered to be missing from your environment.

## Application Load Balancer

When you provision an HTTP service, whether or not it is secure, the
service will placed behind an application load balancer. Your Fargate
service is created in private subnets, so your VPC must contain at
least two private subnets.  Your load balancer can either be
_internally_ or _externally facing_.

By default, the framework looks for and will reuse a load balancer
with the correct scheme (internal or internet-facing), in a subnet
aligned with your task type. The ALB will be placed in public subnets
if it is internet-facing. You can override that behavior by either
explicitly setting the ALB arn in the `alb:` section of the
configuration or pass `--create-alb` when you run our plan and apply.

If no ALB is found or you passed the `--create-alb` option, a new ALB
is provisioned. When creating a new ALB, `app-FargateStack` will also
create the necessary listeners and listener rules for the ports you
have configured.

### Why Does the Framework Force the Use of a Load Balancer?

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

## AWS WAF Support

For external-facing HTTPS services, `App::FargateStack` can automate
the creation and association of an AWS Web Application Firewall (WAF)
to provide an essential layer of security. This protects your
application from common web exploits and bots that could affect
availability or compromise security.

The framework follows a "Hybrid Management Model" for WAF, designed to
provide a secure, sensible baseline out-of-the-box while giving you
full control over fine-grained rule customization.

### Enabling WAF Protection

To enable WAF, simply add a `waf` block with `enabled: true` to your
`alb` configuration:

    alb:
      # ... existing alb configuration ...
      waf:
        enabled: true

### Configuring Managed Rules

To simplify configuration, `App::FargateStack` uses a keyword-based
system for enabling AWS Managed Rule Groups. You can specify a list of
keywords under the `managed_rules` key in your `waf` configuration.

If the `managed_rules` key is omitted, the framework will apply the
`default` bundle, which provides a strong and cost-effective security
baseline.

    waf:
      enabled: true
      managed_rules: [linux-app, admin, -php]

The framework supports both individual rule sets and pre-configured
"bundles" for common application types. It also supports a subtractive
syntax (prefixing a keyword with a `-`) to remove rule sets from a
bundle.

#### Rule Set Keywords

- **base**: A strong baseline including `AWSManagedRulesCommonRuleSet`, `AWSManagedRulesAmazonIpReputationList`, and `AWSManagedRulesKnownBadInputsRuleSet`.
- **admin**: Protects exposed administrative pages (`AWSManagedRulesAdminProtectionRuleSet`).
- **sql**: Protects against SQL injection attacks (`AWSManagedRulesSQLiRuleSet`).
- **linux**: Includes rules for Linux and Unix-like environments.
- **php**: Includes rules for applications running on PHP.
- **wordpress**: Includes rules specific to WordPress sites.
- **windows**: Includes rules for Windows Server environments.
- **anonymous**: **Use with caution.** Blocks traffic from anonymous sources like VPNs and proxies, which may block legitimate users.
- **ddos**: Mitigates application-layer (Layer 7) DDoS attacks like HTTP floods.
- **premium**: **Warning: Extra Cost.** Enables advanced, paid protections for bot control and account takeover prevention.

#### Rule Bundles

- **default**: Includes `base` and `sql`. This is the recommended starting point for most applications.
- **linux-app**: Includes `default` and `linux`.
- **wordpress-app**: Includes `default`, `linux`, and `wordpress`.
- **windows-app**: Includes `default` and `windows`.
- **all**: Includes all standard, non-premium rule sets. **Warning:** This will likely exceed the default WCU quota and may incur additional costs.

### The Bootstrap Process (First Run)

On the first `apply` run with WAF enabled, the framework will perform
a one-time bootstrap:

1. It generates a default `web-acl.json` file in your project
directory. This file contains the complete definition of your Web ACL,
including the rules generated from your `managed_rules` keywords.
2. It calls `aws wafv2 create-web-acl` to create a new Web ACL.
3. It calls `aws wafv2 associate-web-acl` to link the new Web ACL to
your Application Load Balancer.
4. It updates your configuration file with the state of the new
WAF resources, including its Name, ID, ARN, LockToken, and a checksum
of the `web-acl.json` file.
5. The `waf` block in your `fargate-stack.yml` is updated to reflect
the bootstrapped state. If the `managed_rules` key was not present,
it will be added with the default value of `[default]`.

### Ongoing Management (Subsequent Runs)

After the initial creation, you take full control of the rules. To
add, remove, or modify rules, you simply edit the `web-acl.json` file
directly.

On subsequent runs of `apply`, `App::FargateStack` will:

- Calculate a checksum of your `web-acl.json` file.
- If the checksum has changed, it will safely update the remote Web ACL
with your new rule set.
- If the checksum has not changed, it will skip the update to avoid
unnecessary API calls.

This model gives you the best of both worlds: the "minimal
configuration, maximum results" of a secure default, and the full
"transparent box" control to customize your security posture as your
application's needs evolve.

### Conflict and Drift Management

The framework includes robust safety checks to prevent accidental data
loss. If it detects that the Web ACL has been modified in the AWS
Console _and_ you have also modified your local `web-acl.json` file,
it will detect the state conflict, refuse to make any changes, and
provide a clear error message with instructions on how to resolve it.

### Estimated Cost

The default WAF configuration is designed to provide a strong security
baseline while remaining cost-effective. When you enable WAF without
specifying any `managed_rules`, the framework applies the `default`
bundle, which includes the `base` and `sql` rule sets.

The approximate monthly cost for this default configuration is
**~$9.00 per month**, plus per-request charges.

The cost is broken down as follows:

- **$5.00 / month** for the Web ACL itself.
- **$4.00 / month** for the four AWS Managed Rule Groups included
in the `default` bundle (3 in 'base', 1 in 'sql').
- **$0.60 / per 1 million requests** processed by the Web ACL.

**Warning:** Enabling the `premium` rule set will incur significant
additional monthly and per-request fees for services like Bot Control
and Account Takeover Prevention. Always review the [AWS WAF
pricing](https://aws.amazon.com/waf/pricing/) page before enabling
premium features.

## Roadmap for HTTP Services

- path based routing on ALB listeners

[Back to Table of Contents](#table-of-contents)

# AUTOSCALING

## Overview

For services that experience variable load, such as HTTP applications or
background job processors, `App::FargateStack` can automate the process of
scaling the number of running tasks up or down to meet demand. This ensures
high availability during traffic spikes and saves costs during quiet periods.

The framework integrates with AWS Application Auto Scaling to provide target
tracking scaling policies. This allows you to define a target metric - such as
average CPU utilization or the number of requests per minute - and the framework
will automatically manage the number of Fargate tasks to keep that metric at
your desired level.

## Enabling Autoscaling

To enable autoscaling for a service, add an `autoscaling` block to its task
configuration in your .yml configuration file.

tasks:
  my-service:
    # ... other task settings ...
    autoscaling:
      min\_capacity: 1
      max\_capacity: 10
      cpu: 60

## Configuration Parameters

The `autoscaling` block accepts the following keys:

- **min\_capacity** (Required)

    The minimum number of tasks to keep running at all times. The service will
    never scale in below this number.

- **max\_capacity** (Required)

    The maximum number of tasks that the service can scale out to. This acts as
    a safeguard to control costs.

- **cpu** OR **requests** (Required, mutually exclusive)

    You must specify exactly one scaling metric.

    - `cpu`: The target average CPU utilization percentage across all tasks in
    the service. Valid values are between 1 and 100.
    - `requests`: The target number of requests per minute for each task. This
    is only valid for tasks of type `http` or `https` that are behind an
    Application Load Balancer.

- **scale\_in\_cooldown** (Optional)

    The amount of time, in seconds, to wait after a scale-in activity before
    another scale-in activity can start. This prevents the service from scaling
    in too aggressively.

    Default: `300`

- **scale\_out\_cooldown** (Optional)

    The amount of time, in seconds, to wait after a scale-out activity before
    another scale-out activity can start. This allows new tasks time to warm up
    and start accepting traffic before the service decides to scale out again.

    Default: `60`

- **policy\_name** (Managed by CApp::FargateStack)

    This is a unique name for the scaling policy generated by the framework. It
    is written to your configuration file and used to detect drift between your
    configuration and the live environment in AWS. You should not modify this
    value.

## Example: Scaling on CPU Utilization

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

## Example: Scaling on ALB Requests

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

## Scheduled Scaling Configuration

To configure predictive, time-based scaling, add a `scheduled` block
inside the main `autoscaling` configuration. This allows you to
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

_Note: **start\_time** and **end\_time** are UTC_

- **scheduled** (Optional)

    A hash where each key is a unique, descriptive name for the schedule
    group (e.g., `business_hours`). Each group defines a time window and
    the capacity changes for that window.

    - **start\_time** (Required): The time to scale up, in HH:MM
    format (24-hour clock, UTC).
    - **end\_time** (Required): The time to scale down, in HH:MM
    format (24-hour clock, UTC).
    - **days** (Required): The days of the week for the schedule. Can
    be a range (e.g., `MON-FRI`) or comma-separated values.
    - **min\_capacity** (Optional): The minimum capacity during and
    outside the window. The two values should be separated by a slash,
    comma, colon, hyphen, or space (e.g., `2/1` or `2,1`).
    - **max\_capacity** (Optional): The maximum capacity during and
    outside the window, using the same `in/out` format as
    `min_capacity`.

The parser will generate two scheduled actions from this block: one to
apply the "in" capacity at the `start_time` and one to apply the
"out" capacity at the `end_time`.

## Example: Combined Metric and Scheduled Scaling

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

## Drift Detection and Management

CApp::FargateStack treats your YAML configuration as the single source of
truth. On every `plan` or `apply` run, it will compare the `autoscaling`
configuration in your file with the live scaling policy in AWS.

If it detects any differences (e.g., someone manually changed the max capacity
in the AWS Console), it will report the drift and will not apply any changes.
To overwrite the live settings and enforce the configuration from your file,
you must re-run the `apply` command with the `--force` flag. This provides a
critical safety check against accidental configuration changes.

### The `autoscaling` keyword

For any service type (`https`, `http`, `daemon`, or `task`), you can enable
and configure autoscaling directly from the command line. This provides a
quick-start method to make your service elastic from the moment it's created.

The Cautoscaling: keyword accepts a metric and an optional target value:

- **Enable with a specific target value:**

    autoscaling:requests=500
    autoscaling:cpu=60

    This will enable autoscaling and set the target for either ALB requests per
    task or average CPU utilization.

- **Enable with default target value:**

    autoscaling:requests
    autoscaling:cpu

    If you omit the target value, a sensible default will be used (e.g.,
    `500` for requests, `60` for CPU).

When the `create-stack` command sees the Cautoscaling: keyword, it
will generate a complete `autoscaling` block in your `fargate-stack.yml`
file. This block will be populated with safe defaults (`min_capacity: 1`,
`max_capacity: 2`), the specified metric, and all other necessary fields,
making it easy to review and customize later. See ["AUTOSCALING"](#autoscaling) for
a full list of configuration options.

[Back to Table of Contents](#table-of-contents)

# CURRENT LIMITATIONS

- Stacks may contain multiple daemon services, but only one task
may be exposed as an HTTP/HTTPS service via an ALB.
- Limited configuration options for some resources such as
advanced load balancer listener rules, custom CloudWatch metrics, or
task health check tuning.
- Some out of band infrastructure changes may break the ability
to re-run `app-FargateStack` without manually updating the
configuration
- Support for only 1 EFS filesystem per task
- This framework assumes that the
[operatingSystemFamily](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters_ec2.html#runtime-platform_ec2)
is "LINUX" and the `cpuArchitecture` is "X86\_64" LINUX. This is
unlikely to change.

[Back to Table of Contents](#table-of-contents)

# TROUBLESHOOTING

## Warning: task placed in a public subnet

When running a task you may see:

    [2025/08/05 03:40:58] run-task: subnet-id: [subnet-7c160c37] is in a public subnet...consider running your jobs in a private subnet

This means the task is being scheduled in a subnet that has a
0.0.0.0/0 route to an Internet Gateway (a public subnet).

While not fatal, placing tasks in public subnets is discouraged unless
you have a specific need.

### Why this matters

Running tasks in public subnets can introduce risk and operational
surprises:

- Accidental exposure

    If the task is assigned a public IP and the security group allows
    inbound access, it may be reachable from the internet.

- Unintended dependency

    Public-subnet egress typically relies on a public IP and the Internet
    Gateway. That can bypass intended egress controls, logging, or central
    inspection.

- Narrow security margin

    Safety depends entirely on security groups and NACLs. A small
    misconfiguration can expose services or data.

### Recommended pattern

Use private subnets for most Fargate workloads. Private subnets do not
route directly to the internet.

If the task needs outbound access (for example, to pull images from
ECR or call external APIs), use one of:

- A NAT Gateway (private subnet egress to the internet)
- VPC interface endpoints for ECR (ecr.api and ecr.dkr) and a
gateway endpoint for S3, so image pulls stay inside the VPC with no
public IPs

For public-facing applications, the common pattern is: tasks in
private subnets, fronted by a public Application Load Balancer in
public subnets.

### When is a public subnet acceptable?

Use a public subnet only when the task itself must have a public IP
and terminate client connections directly (uncommon). If you do:

- Set assignPublicIp=ENABLED so the task can reach the internet
via the Internet Gateway
- Keep security groups locked down and monitor egress on TCP 443

### Note on image pulls

To pull from ECR, the task needs a path to ECR API, ECR DKR, and S3:

- Public subnet: requires a public IP (assignPublicIp=ENABLED),
unless you provision VPC endpoints
- Private subnet: works via a NAT Gateway, or entirely private
via VPC endpoints (no public IPs)

## My task fails with this message:

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

### Common causes

- The task was placed in a public subnet but was not assigned a
public IP.
- The task was placed in a private subnet without access to a
NAT gateway or VPC endpoints.

Even though the subnet may have a route to an Internet Gateway (i.e.,
it is technically a "public" subnet), if the task does not receive a
public IP, it cannot use that route to reach external services like
ECR or Secrets Manager.

### How to fix it

- If using public subnets, ensure the task is assigned a public
IP.
- If using private subnets, ensure a NAT gateway is available
and the subnet has a route to it.
- Alternatively, configure VPC endpoints for ECR, Secrets
Manager, and related services to avoid needing internet access
altogether.

### Note on Subnet Selection

`App::FargateStack` attempts to prevent this situation by analyzing
your VPC configuration during planning. It categorizes subnets as
private or public and evaluates whether they provide the necessary
network access to launch a Fargate task successfully. The framework
warns if you attempt to use a subnet that lacks internet or endpoint
access.

## My task failed to start and the reason is unclear

This is one of the most common and frustrating scenarios when working
with Fargate. You run `start-service` or `run-task`, the command
seems to succeed, but then the task quickly stops. The `status`
command shows the desired count is 1 but the running count is 0, and
the logs are empty.

This often happens due to a **resource initialization error**. The
problem isn't with your container image itself, but with the
infrastructure Fargate is trying to set up for it.

Common causes include:

- **Networking Issues**: The task is in a subnet that can't pull the
image from ECR (e.g., no NAT Gateway or VPC endpoints).
- **Permissions Errors**: The task's IAM role is missing a required
permission.
- **EFS Mount Failures**: The task cannot mount an EFS volume, often due
to a misconfigured security group or incorrectly specified path.

These errors are opaque because they happen deep inside the
AWS-managed environment. The high-level ECS API only reports a generic
failure, and since it's not an API call error, it won't appear in
CloudTrail.

### The Solution: Finding the `stoppedReason`

To solve this, `App-FargateStack` provides an optional argument to
the `list-tasks` command. By default, this command only shows
`RUNNING` tasks. However, if you add the `stopped` argument, it will
show recently stopped tasks and, most importantly, the reason they
stopped.

**The Command:**

    app-FargateStack list-tasks stopped

This will display a table of stopped tasks, including a `Stopped
Reason` column. This column often contains the detailed, multi-line
error message from the underlying AWS service that caused the failure,
giving you the exact information you need to debug the problem.

For example, if an EFS mount failed, the `stoppedReason` might
contain:

    ResourceInitializationError: failed to invoke EFS utils
    commands... mount.nfs4: mounting failed, reason given by server: No
    such file or directory

This tells you immediately that the problem is with the EFS path, not
a generic "task failed" message.

## Why is my task or service still using an old image?

This is one of the most common points of confusion when working with
ECS and Fargate.

You may have just built and pushed a new image to ECR using the same
tag (e.g. `latest`), but when you launch a task or deploy a service,
ECS appears to continue using the old image.  Here's why.

### One-off tasks: `run-task` uses a fixed image digest

When you run a task using:

    app-FargateStack run-task my-task

ECS uses the exact task definition revision as registered. If the
image was specified using a tag like `:latest`, ECS resolves that tag
once -- at the time the task starts -- and stores the resolved digest
(e.g. `sha256:...`).

This means:

- Tasks launched this way will continue to run the old image, even if
the `latest` tag in ECR now points to a newer image.
- The only way to run a task with the new image is to register a new
task definition that references the updated image. You can force a new
task definition by registering the definition.

        app-FargateStack register my-task

### Services: `create-service` and `update-service` use frozen images too

When you create or update a service, ECS also resolves any image tags
to their current digest and stores that in the registered task
definition.

This means that ECS services are also tied to the image that existed
at the time of task definition registration.

If you push a new image to ECR using the same tag (e.g. `:latest`),
the service will not automatically use it.  ECS does not re-resolve
the tag unless you explicitly tell it to.

### `--force-new-deployment` re-pulls image tags (if not pinned by digest)

If your task definition references the image by tag
(e.g. `http-service:latest`), and not by digest, then running:

    app-FargateStack redeploy my-service

will cause ECS to:

- Stop the currently running tasks
- Start new tasks using the same task definition revision
- Re-resolve and pull the image tag from ECR

This allows your service to pick up a newly pushed image without
registering a new task definition, as long as the task definition used
a tag (not a digest).

### Confirm what your task definition is using

To see whether your task definition uses a tag or a digest, run:

    aws ecs describe-task-definition --task-definition my-task:42

Look at the `image` field under `containerDefinitions`. It will either be:

    image: http-service:latest     # tag -- will be re-resolved by --force-new-deployment
    image: http-service@sha256:... # digest -- frozen, cannot be re-resolved

### Best practices

- Avoid using `:latest` in production. Use immutable tags
(e.g. `:v1.2.3`) or digests.
- If you want to deploy a new image, the safest and most deterministic approach is to:

        - Build and push the image using a new tag or digest
        - Register a new task definition revision referencing that tag or digest
        - Update your service to use the new task definition

- Use `--force-new-deployment` only if your task definition uses a tag
and you want to re-resolve it without changing the task definition
itself.

[Back to Table of Contents](#table-of-contents)

# ROADMAP

- Scaling configuration
- Service Connect, including certificates for internal HTTP services
- Multiple HTTP services
- Path based routing

[Back to Table of Contents](#table-of-contents)

# SEE ALSO

[IPC::Run](https://metacpan.org/pod/IPC%3A%3ARun), [App::Command](https://metacpan.org/pod/App%3A%3ACommand), [App::AWS](https://metacpan.org/pod/App%3A%3AAWS), [CLI::Simple](https://metacpan.org/pod/CLI%3A%3ASimple)

[Back to Table of Contents](#table-of-contents)

# AUTHOR

Rob Lauer - rclauer@gmail.com

[Back to Table of Contents](#table-of-contents)

# LICENSE

This script is released under the same terms as Perl itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 373:

    Expected '=item \*'

- Around line 376:

    Expected '=item \*'

- Around line 390:

    Expected '=item \*'

- Around line 392:

    Expected '=item \*'

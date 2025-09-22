package App::FargateStack::CreateStack;

use strict;
use warnings;

use App::FargateStack::Builder::Utils qw(log_die dmp);
use App::FargateStack::Constants;
use Carp;
use CLI::Simple::Constants qw(:booleans :chars);
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename qw(basename);
use YAML qw(Dump DumpFile);

use Role::Tiny;

########################################################################
sub cmd_create_stack {
########################################################################
  my ($self) = @_;

  my ( $app_name, @args ) = $self->get_args;

  if ( lc $app_name !~ /\A[[:lower:]\d_-]+\z/xsm ) {
    if ( $app_name =~ /^(?:daemon|https?|scheduled|task):(.*?)$/xsm ) {
      unshift @args, $app_name;
      $app_name = $1;
      carp sprintf "WARNING: no app name provided...using the task name: [%s]\n", $app_name;
    }
    else {
      croak sprintf "ERROR: app names should only have a-z_-0-9 characters\n";
    }
  }

  my $config_name = $self->get_config_name // "$app_name.yml";
  $self->set_config_name($config_name);

  my $sts = $self->fetch_sts;

  my $account = $sts->get_caller_identity('Account');
  $sts->check_result( message => 'ERROR: could not determine account for profile: [%s]', $self->get_profile );

  my $config = {
    account => $account,
    profile => $self->get_profile,
    region  => $self->get_region,
    app     => { name => $app_name },
  };

  my %tasks;

  while ( my $tag = shift @args ) {

    if ( $tag =~ /^(daemon|task|scheduled|https?):/xsm ) {
      $tasks{$tag} = [];

      while ( my $next_tag = shift @args ) {
        if ( $next_tag =~ /^(?:daemon|task|scheduled|https?):/xsm ) {
          unshift @args, $next_tag;
          last;
        }
        push @{ $tasks{$tag} }, $next_tag;
      }
    }
    elsif ( !keys %tasks ) {
      croak "ERROR: start your task definition with daemon|task|scheduled|http|https\n";
    }
  }

  foreach my $t ( keys %tasks ) {
    my ( $type, $name ) = split /[:]/xsm, $t;
    $self->log_info( 'create-stack: configuring: %s %s', $type, $name );

    my @options = @{ $tasks{$t} };

    my $task = { type => $type eq 'scheduled' ? 'task' : $type };
    $config->{tasks}->{$name} = $task;

    my ($image) = grep {/^image:/xsm} @options;

    croak sprintf "ERROR: task [%s] does not have an image...every task must have an image\n", $name
      if !$image;

    my ($image_name) = $image =~ /^image:(.*)$/xsm;

    # If the user omitted a tag, you can optionally default to :latest
    # $image_name .= ':latest' if $image_name !~ /:[^\/]+$/;

    my ( $repo, $tag ) = split /:/xsm, $image_name, 2;
    $tag //= 'latest';

    if ( $image_name !~ m{/}xsm ) {
      # ECR shorthand (repo[:tag]) in current account

      my $ecr    = $self->fetch_ecr;
      my $images = $ecr->describe_images( $repo, 'imageDetails' );

      if ( !$images || !@{$images} ) {
        $self->log_warn( 'create-stack: %s not found in ECR...assuming public image', $image );
        $task->{image} = "$image_name:$tag";  # leave as-is; ECS will try public registries
      }
      else {
        my $uri = sprintf '%s.dkr.ecr.%s.amazonaws.com/%s:%s', $account, $self->get_region, $image_name, $tag;
        $task->{image} = $uri;
      }
    }
    else {
      # Fully-qualified external or cross-account reference; accept as-is
      $task->{image} = "$repo:$tag";
    }

    my ($schedule) = grep {/^schedule:/xsm} @options;

    if ( $t =~ /^scheduled:/xsm || ( $t =~ /task:/sxm && $schedule ) ) {

      croak "ERROR: scheduled tasks must have a schedule\n"
        if !$schedule;

      $task->{schedule} = ( split /[:]/xsm, $schedule )[-1];
    }

    if ( $t =~ /^(https?):/xsm ) {
      my ($domain) = grep {/^domain:/xsm} @options;

      croak "ERROR: HTTP and HTTPS services must have a domain\n"
        if !$domain;

      $config->{domain} = ( split /[:]/xsm, $domain )[-1];
    }

    ####################################################################
    # Environment
    ####################################################################

    my @environment = grep {/^env(?:ironment)?:/xsm} @options;

    $self->parse_environment_option(
      config => $config,
      task   => $task,
      tag    => \@environment
    );
    ####################################################################
    # WAF
    ####################################################################
    my ($waf) = grep {/^waf:.*$/xsm} @options;

    if ($waf) {
      croak "ERROR: waf option is only available for https services:\n"
        if $t !~ /^https:/xsm;

      $self->parse_waf_option(
        task   => $task,
        config => $config,
        tag    => $waf
      );
    }

    ####################################################################
    # Autoscaling
    ####################################################################
    my ($autoscaling) = grep {/autoscaling:.*$/xsm} @options;

    if ($autoscaling) {
      croak "ERROR: autoscaling option is only available for http and daemon services:\n"
        if $t !~ /^(?:https?|daemon):/xsm;

      $self->parse_autoscaling_option(
        task   => $task,
        config => $config,
        tag    => $autoscaling
      );
    }

  }

  $self->fetch_option_defaults;

  print {*STDOUT} Dump($config);

  if ( $self->get_update ) {
    DumpFile( $config_name, $config );
  }

  return;
}

########################################################################
sub parse_environment_option {
########################################################################
  my ( $self, %args ) = @_;

  my ( $task, $environment ) = @args{qw(task tag)};

  foreach ( @{$environment} ) {
    my ( $key, $value ) = split /\s*=\s*/xsm, ( split /:/xsm )[-1];
    $task->{environment} = { $key => $value };
  }

  return;
}

########################################################################
sub parse_autoscaling_option {
########################################################################
  my ( $self, %args ) = @_;

  my ( $config, $task, $autoscaling ) = @args{qw(config task tag)};

  my $autoscaling_config = $task->{autoscaling} = {
    min_capacity       => $DEFAULT_AUTOSCALING_MIN_CAPACITY,
    max_capacity       => $DEFAULT_AUTOSCALING_MAX_CAPACITY,
    scale_out_cooldown => $DEFAULT_AUTOSCALING_SCALE_OUT_COOLDOWN,
    scale_in_cooldown  => $DEFAULT_AUTOSCALING_SCALE_IN_COOLDOWN,
  };

  my ($metric) = $autoscaling =~ /:([^=]+)/xsm;

  croak "ERROR: requests can only be used with http services\n"
    if $metric eq 'requests' && $task->{type} !~ /^http/xsm;

  croak "ERROR: metric must be cpu or requests\n"
    if $metric !~ /^cpu|requests/xsm;

  my ($metric_value) = $autoscaling =~ /=(.*)$/xsm;

  if ( !$metric_value ) {
    $metric_value = $metric eq 'cpu' ? $DEFAULT_CPU_SCALING_LEVEL : $DEFAULT_REQUESTS_SCALING_LEVEL;
  }

  # TBD: check for sane values
  $autoscaling_config->{$metric} = $metric_value;

  return;
}

########################################################################
sub parse_waf_option {
########################################################################
  my ( $self, %args ) = @_;

  my ( $config, $task, $waf ) = @args{qw(config task tag)};

  $config->{alb}->{waf} = { enabled => 'true' };

  my ($rule_list) = reverse split /:/xsm, $waf;

  my @rules;

  if ( $rule_list =~ /^(?:enabled|true|default)$/xsm ) {
    push @rules, 'default';
  }
  else {
    @rules = split /,/xsm, $rule_list;
  }

  if (@rules) {
    $config->{alb}->{waf}->{managed_rules} = \@rules;
  }

  return;
}

########################################################################
sub resolve_image_name {
########################################################################
  my ( $self, $image_name ) = @_;

  return $image_name
    if $image_name =~ m{/}xsm;

  # ECR shorthand (repo[:tag]) in current account
  my ( $repo, $tag ) = split /:/xsm, $image_name, 2;
  $tag //= 'latest';

  my $ecr    = $self->fetch_ecr;
  my $images = $ecr->describe_images( $repo, 'imageDetails' );

  return $image_name
    if !$images || !@{$images};

  return sprintf '%s.dkr.ecr.%s.amazonaws.com/%s:%s', $self->get_account, $self->get_region, $image_name, $tag;
}

1;

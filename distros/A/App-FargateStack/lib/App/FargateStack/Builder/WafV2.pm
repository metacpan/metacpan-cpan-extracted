package App::FargateStack::Builder::WafV2;

use strict;
use warnings;

use App::WafV2;
use App::FargateStack::Builder::Utils qw(dmp slurp_file log_die display_diffs);
use App::FargateStack::Constants;
use Carp;
use CLI::Simple::Constants qw(:booleans :chars);
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use English qw(no_match_vars);
use JSON;
use Storable qw(dclone);

use Role::Tiny;

########################################################################
sub managed_rules {
########################################################################
  my ( $self, $managed_rules ) = @_;

  my @remove_list;
  my @managed_rule_list;

  foreach my $rule_set ( @{$managed_rules} ) {
    if ( $rule_set =~ /^[\-](.*)$/xsmi ) {
      push @remove_list, $1;
      next;
    }

    if ( $WAF_MANAGED_RULE_BUNDLES{$rule_set} ) {
      foreach ( @{ $WAF_MANAGED_RULE_BUNDLES{$rule_set} } ) {
        push @managed_rule_list, @{ $WAF_MANAGED_RULES{$_} };
      }
    }
    elsif ( $WAF_MANAGED_RULES{$rule_set} ) {
      push @managed_rule_list, @{ $WAF_MANAGED_RULES{$rule_set} };
    }
    else {
      log_die( $self, 'ERROR: no such managed rule: %s', $rule_set );
    }
  }

  foreach my $rule (@remove_list) {
    @managed_rule_list = grep { $rule ne $_ } @managed_rule_list;
  }

  return \@managed_rule_list;
}

########################################################################
sub create_rule_list {
########################################################################
  my ( $self, $waf_config ) = @_;

  my @rule_list;

  my $priority = 1;

  my $rule_stub = decode_json($WAF_RULE_STUB);

  if ( !$waf_config->{managed_rules} ) {
    $waf_config->{managed_rules} = [qw(default)];
  }

  my $managed_rules = $self->managed_rules( $waf_config->{managed_rules} );

  foreach my $metric_name ( @{$managed_rules} ) {
    my $rule = dclone $rule_stub;

    $rule->{Name}                                           = $metric_name;
    $rule->{Statement}->{ManagedRuleGroupStatement}->{Name} = $metric_name;
    $rule->{VisibilityConfig}->{MetricName}                 = $metric_name;
    $rule->{Priority}                                       = $priority++;

    push @rule_list, $rule;
  }

  return \@rule_list;
}

########################################################################
sub build_waf {
########################################################################
  my ($self) = @_;

  ######################################################################
  ## init
  ######################################################################
  my $config = $self->get_config;

  my $dryrun = $self->get_dryrun;

  # if no alb or no waf section skip this build (avoid autovivification)
  return
    if !exists $config->{alb};

  my $alb = $config->{alb};

  return
    if !exists $alb->{waf};

  my $waf_config = $alb->{waf};

  return
    if !$waf_config->{enabled};

  log_die( $self, 'ERROR: no ALB ARN? you cannot have a WAF without an ALB' )
    if !$alb->{arn};

  $waf_config->{name} //= $self->create_default('web-acl-name');
  my $name = $waf_config->{name};

  my $waf = $self->fetch_wafv2;

  ######################################################################
  ## create or update web-acl
  ######################################################################
  my $web_acl = $waf->list_web_acls(
    scope => 'REGIONAL',
    query => sprintf 'WebACLs[?Name==`%s`]',
    $name
  );

  $waf->check_result( message => 'ERROR: could not list web acls' );

  if ( $web_acl && @{$web_acl} ) {
    my $web_acl_id = $web_acl->[0]->{Id};

    $web_acl = $waf->get_web_acl( name => $name, id => $web_acl_id );
    $waf->check_result( message => 'ERROR: could not get web-acl: [%s]', $name );

    my $web_acl_arn = $web_acl->{WebACL}->{ARN};

    # check to see if rules have been updated
    my $new_rules = $self->check_rules( waf => $waf, waf_config => $waf_config );

    # check to see if someone has mucked with web-acl.json
    my $needs_update = $self->check_web_acl_state(
      name       => $name,
      id         => $web_acl_id,
      waf_config => $waf_config,
      waf        => $waf,
      web_acl    => $web_acl,
      rules      => $new_rules,
    );

    # we would have died already if there was a conflict, so now we
    # have either FALSE = no update needed or TRUE = need to update web-acl
    if ($needs_update) {
      $self->log_warn( 'waf: web-acl: [%s] has changed...will be updated...%s', $name, $dryrun );

      if ( !$dryrun ) {
        $self->update_web_acl( $waf_config->{lock_token} );

        $self->save_web_acl(
          id         => $waf_config->{id},
          scope      => 'REGIONAL',
          name       => $name,
          waf_config => $waf_config,
          waf        => $waf,
        );
      }
    }
    else {
      $self->log_info( 'waf: web-acl: [%s] has not changed...skipping', $name );
      $self->inc_existing_resources( waf => $waf_config->{arn} );
    }

    my $arns = $waf->list_resources_for_web_acl( $web_acl_arn, 'ResourceArns' );
    $waf->check_result( message => 'ERROR: could not list resources for web acl: [%s]', $web_acl_arn );

    if ( !@{$arns} ) {
      $self->log_warn( 'waf: web-acl: [%s] not associated...will be associated with ALB: [%s]...%s',
        $name, $alb->{name}, $dryrun );

      if ( !$dryrun ) {
        $self->associate_web_acl(
          web_acl_arn  => $web_acl_arn,
          resource_arn => $alb->{arn},
          waf          => $waf,
          name         => $name
        );
      }
    }
  }
  else {
    $self->log_warn( 'waf: web-acl: [%s] does not exist...will be created...%s', $name, $dryrun );

    $self->inc_required_resources(
      waf => [
        sub {
          my ($dryrun) = @_;
          return $dryrun ? 'arn:???' : $waf_config->{arn};
        }
      ]
    );

    my $rules = $self->create_rule_list($waf_config);

    $self->log_warn( 'waf: rule list from: [%s]', join q{,}, @{ $waf_config->{managed_rules} } );
    $self->log_debug( "waf: managed rules: %s\n", join "\n", Dumper $rules );

    if ( !$dryrun ) {
      $self->create_web_acl(
        name       => $name,
        waf_config => $waf_config,
        waf        => $waf,
        rules      => $rules
      );
    }
  }

  return $SUCCESS;
}

########################################################################
sub check_rules {
########################################################################
  my ( $self, %args ) = @_;

  my ( $waf, $waf_config ) = @args{qw(waf waf_config web_acl)};

  my $web_acl = $self->fetch_web_acl;

  my $current_rules = $web_acl->{WebACL}->{Rules};

  my $rules = $self->create_rule_list($waf_config);

  return $rules
    if JSON->new->pretty->canonical->encode($rules) ne JSON->new->pretty->canonical->encode($current_rules);

  return;
}

########################################################################
sub check_web_acl_state {
########################################################################
  my ( $self, %args ) = @_;

  my ( $name, $id, $waf_config, $waf, $web_acl, $rules ) = @args{qw(name id waf_config waf web_acl rules)};

  my ( $aws_id, $aws_arn ) = @{ $web_acl->{WebACL} }{qw(Id ARN)};
  my $aws_lock_token = $web_acl->{LockToken};

  my $local_web_acl = $self->fetch_web_acl;

  if ($rules) {
    $self->log_warn('waf: rules have changed, updating web-acl.json');
    $local_web_acl->{WebACL}->{Rules} = $rules;
    $self->save_web_acl( name => $name, web_acl => $local_web_acl, waf => $waf, waf_config => $waf_config );
  }

  # determine if the web-acl has been modified "out-of-band"
  # and/or our local web-acl.json file has been modified

  my $md5 = $self->calculate_md5($web_acl);

  my $md5_match = $md5 eq $waf_config->{md5};

  if ( $md5 ne $waf_config->{md5} ) {
    $self->log_warn( 'waf: MD5 hashes do not match: [%s] != [%s]', $waf_config->{md5}, $md5 );
  }

  my $lock_token_match = $aws_lock_token eq $waf_config->{lock_token};

  return $FALSE  # no need to update, everything OK
    if $md5_match && $lock_token_match;

  return $TRUE   # update OK
    if !$md5_match && $lock_token_match;

  if ( $md5_match && !$lock_token_match ) {
    my $err_msg = <<'END_OF_ERR_MESSAGE';
WAF configuration appears to be in sync, but the remote resource has
abeen modified out-of-band. The local configuration file is being updated with
the latest LockToken. Please run 'plan' again to confirm.
END_OF_ERR_MESSAGE
    $waf_config->{id}         = $aws_id;
    $waf_config->{arn}        = $aws_arn;
    $waf_config->{lock_token} = $aws_lock_token;

    return $FALSE;  # no need to update, just update local state
  }

  # if we are here, then conflict !$md5_match && !$lock_token_match

  # rut-roh...conflict
  my $diff = $self->web_acl_diffs($web_acl);

  my $err_msg = <<'END_OF_ERR_MESSAGE';
ERROR: State conflict detected for Web ACL %s 

A change has been made to the local 'web-acl.json' file, but the
Web ACL has also been modified in AWS since the last run.

Applying local changes now would overwrite the remote modifications.

%s

To resolve this conflict:
1. Review the diff above to understand the remote changes.
2. Manually merge the desired remote changes into your local 'web-acl.json' file.
3. Once the local file represents the true desired state, run 'app-FargateStack plan' again.
END_OF_ERR_MESSAGE

  log_die( $self, $err_msg, $name, $diff, $name )
    if !$self->get_force;

  $waf_config->{lock_token} = $aws_lock_token;

  return $TRUE;
}

########################################################################
sub create_web_acl {
########################################################################
  my ( $self, %args ) = @_;

  my ( $name, $waf_config, $waf, $rule_list ) = @args{qw(name waf_config waf rules)};

  my $web_acl_summary = $waf->create_web_acl(
    name        => $name,
    rules       => $rule_list,
    query       => 'Summary',
    scope       => 'REGIONAL',
    metric_name => $self->get_config->{app}->{name},
  );

  $waf->check_result( message => 'ERROR: unable to create web-acl: [%s]', $name );

  @{$waf_config}{qw(id lock_token arn)} = @{$web_acl_summary}{qw(Id LockToken ARN)};

  my $web_acl = $self->save_web_acl(
    id         => $waf_config->{id},
    scope      => 'REGIONAL',
    name       => $name,
    waf_config => $waf_config,
    waf        => $waf,
  );

  $self->associate_web_acl(
    web_acl_arn  => $waf_config->{arn},
    resource_arn => $self->get_config->{alb}->{arn},
    name         => $name,
    waf          => $waf
  );

  return;
}

########################################################################
sub associate_web_acl {
########################################################################
  my ( $self, %args ) = @_;

  my ( $web_acl_arn, $resource_arn, $waf, $name ) = @args{qw(web_acl_arn resource_arn waf name)};

  my $timeout = $WAF_AVAILABILITY_TIMEOUT;

  # may need to wait for WAF to become available before associating...
  $self->log_warn('waf: associating WAF with ALB...');
  while ($TRUE) {
    $waf->associate_web_acl( $web_acl_arn, $resource_arn );

    $waf->check_result(
      message => 'ERROR: could not associate web-acl: [%s] with ALB',
      params  => [$name],
      regexp  => qr/WAFUnavailableEntityException/xmsi
    );

    $self->log_warn( 'waf: waiting for resource to become available...sleeping for %s seconds - %s until timeout',
      $WAF_AVAILABILITY_SLEEP_TIME, $timeout );

    sleep $WAF_AVAILABILITY_SLEEP_TIME;

    $timeout -= $WAF_AVAILABILITY_SLEEP_TIME;
    last if $timeout <= 0 || !$waf->get_error;
  }

  log_die( $self, 'ERROR: unable to associate web-acl to ALB: %s', $waf->get_error )
    if $waf->get_error;

  return;
}

########################################################################
sub calculate_md5 {
########################################################################
  my ( $self, $web_acl ) = @_;

  my $json = JSON->new->pretty->canonical->encode($web_acl);

  return md5_hex($json);
}

########################################################################
sub fetch_web_acl {
########################################################################
  my ($self) = @_;

  return slurp_file( 'web-acl.json', $TRUE );
}

########################################################################
sub save_web_acl {
########################################################################
  my ( $self, %args ) = @_;

  my ( $id, $name, $scope, $waf_config, $waf, $web_acl ) = @args{qw(id name scope waf_config waf web_acl)};

  $web_acl //= $waf->get_web_acl(
    scope => $scope,
    id    => $id,
    name  => $name,
  );

  $waf->check_result( message => 'ERROR: could not get web-acl: [%s]', $name );

  $waf_config->{md5} = $self->calculate_md5($web_acl);

  my $json = JSON->new->pretty->canonical->encode($web_acl);

  open my $fh, '>', 'web-acl.json'
    or croak "ERROR: could not open web-acl.json for writing\n";

  print {$fh} $json;

  close $fh;

  return;
}

# produce a diff between the stored web-acl and the current AWS web-acl
########################################################################
sub web_acl_diffs {
########################################################################
  my ( $self, $web_acl ) = @_;

  my $current_web_acl = slurp_file( 'web-acl.json', $TRUE );

  return $self->display_diffs( $current_web_acl, $web_acl );
}

########################################################################
sub update_web_acl {
########################################################################
  my ( $self, $lock_token ) = @_;

  my $web_acl = $self->fetch_web_acl;

  my ( $id, $visibility_config, $rules, $description, $default_action )
    = @{ $web_acl->{WebACL} }{qw(Id VisibilityConfig Rules Description DefaultAction)};

  my $scope = 'REGIONAL';

  my $name = $self->get_config->{alb}->{waf}->{name};

  my $waf = $self->fetch_wafv2;

  my $result = $waf->update_web_acl(
    scope             => $scope,
    name              => $name,
    visibility_config => encode_json($visibility_config),
    rules             => $rules,
    lock_token        => $lock_token,
    default_action    => encode_json($default_action),
    description       => $description,
    metric_name       => $self->get_config->{app}->{name},
    id                => $id,
  );

  $waf->check_result( message => 'ERROR: could not update web-acl: [%s]', $name );

  return;
}

1;

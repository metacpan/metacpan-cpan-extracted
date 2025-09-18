package App::WafV2;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use CLI::Simple::Constants qw(:booleans);

use JSON;
use Scalar::Util qw(reftype);

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(profile region scope));

########################################################################
sub list_web_acls {
########################################################################
  my ( $self, %args ) = @_;

  my ( $scope, $query ) = @args{qw(scope query)};

  $scope //= $self->get_scope // 'REGIONAL';

  return $self->command(
    'list-web-acls' => [
      '--scope' => $scope,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub list_regex_pattern_sets {
########################################################################
  my ( $self, %args ) = @_;

  my ( $scope, $name, $query ) = @args{qw(scope name query limit)};
  $scope //= $self->get_scope // 'REGIONAL';

  if ($name) {
    $query = sprintf '{RegexPatternSets: RegexPatternSets[?contains(Name, `%s`)], NextMarker: NextMarker}', $name;
  }

  my $next_marker;
  my @pattern_sets;

  while (
    my $result = $self->command(
      'list-regex-pattern-sets' => [
        '--scope' => $scope,
        $query       ? ( '--query'       => $query )       : (),
        $next_marker ? ( '--next-marker' => $next_marker ) : (),
      ]
    )
  ) {

    $self->check_result( message => 'ERROR: cannot list regex pattern set for: [%s]', $scope );

    last if !@{ $result->{RegexPatternSets} };
    push @pattern_sets, @{ $result->{RegexPatternSets} };
    $next_marker = $result->{NextMarker};
  }

  return \@pattern_sets;
}

########################################################################
sub get_regex_pattern_set {
########################################################################
  my ( $self, %args ) = @_;

  my ( $scope, $name, $id, $query ) = @args{qw(scope name id query)};

  $scope //= $self->get_scope // 'REGIONAL';

  return $self->command(
    'get-regex-pattern-set' => [
      '--name'  => $name,
      '--id'    => $id,
      '--scope' => $scope,
      $query ? ( '--query' => $query ) : ()
    ]
  );

}

########################################################################
sub update_regex_pattern_set {
########################################################################
  my ( $self, %args ) = @_;

  my ( $name, $id, $query, $patterns, $description, $scope ) = @args{qw(name id query patterns description scope)};

  $scope //= $self->get_scope // 'REGIONAL';

  die "usage: update_regex_pattern_set(name => name, scope => scope, id => id, patterns => patterns);\n"
    if !( $name && $scope && $id && $patterns );

  die "ERROR: patterns must be an arrray\n"
    if !( ref($patterns) && reftype($patterns) eq 'ARRAY' );

  my $pattern_set = $self->get_regex_pattern_set( name => $name, scope => $scope, id => $id );
  $self->check_result( message => 'ERROR: Could not retrieve regex pattern set for: [%s]', $name );

  my @current_list = @{ $pattern_set->{RegexPatternSet}->{RegularExpressionList} };
  push @current_list, map { { RegexString => $_ } } @{$patterns};

  $pattern_set->{RegexPatternSet}->{RegexExpressionList} = \@current_list;
  my $lock_token = $pattern_set->{LockToken};

  my $regex_list = $pattern_set->{RegexPatternSet}->{RegexExpressionList};

  return $self->command(
    'update-regex-pattern-set' => [
      '--name'       => $name,
      '--id'         => $id,
      '--scope'      => $scope,
      '--lock-token' => $lock_token,
      $description ? ( '--description' => $description ) : (),
      '--cli-input-json' => encode_json( { RegularExpressionList => $regex_list } ),
      $query ? ( '--query' => $query ) : (),
    ]
  );
}

########################################################################
sub check_rules {
########################################################################
  my ($rules) = @_;

  die "ERROR: no such file [%s]\n"
    if !ref $rules && !-s $rules;

  return $rules
    if !ref $rules;

  die sprintf "unknown rules object: %s\n", Dumper( [ rules => $rules ] )
    if reftype($rules) ne 'ARRAY';

  my ( $fh, $filename ) = tempfile( 'rulesXXXX', UNLINK => $ENV{NO_UNLINK} ? $FALSE : $TRUE );

  print {$fh} JSON->new->pretty->encode($rules);

  close $fh;

  return $filename;
}

########################################################################
sub create_web_acl {
########################################################################
  my ( $self, %args ) = @_;

  my ( $scope, $name, $rules, $default_action, $visibility_config, $description, $query, $metric_name )
    = @args{qw(scope name rules default_action visibility_config description query metric_name)};

  $scope          //= 'REGIONAL';
  $default_action //= 'Allow={}';

  my $rules_file = check_rules($rules);

  $description //= sprintf 'Web acl %s', $name;
  $metric_name //= 'app-FargateStack';

  $visibility_config //= sprintf 'SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=%s', $metric_name;

  return $self->command(
    'create-web-acl' => [
      $query ? ( '--query' => $query ) : (),
      '--name'              => $name,
      '--scope'             => $scope,
      '--default-action'    => $default_action,
      '--visibility-config' => $visibility_config,
      '--description'       => $description,
      '--rules'             => sprintf( 'file://%s', $rules_file ),
    ]
  );
}

# TBD: refactor to use guts of create_web_acl
########################################################################
sub update_web_acl {
########################################################################
  my ( $self, %args ) = @_;

  my ( $id, $scope, $name, $rules, $default_action, $visibility_config, $description, $lock_token, $query, $metric_name )
    = @args{qw(id scope name rules default_action visibility_config description lock_token query metric_name)};

  $scope          //= 'REGIONAL';
  $default_action //= 'Allow={}';

  my $rules_file = check_rules($rules);

  $description //= sprintf 'Web acl %s', $name;
  $metric_name //= 'app-FargateStack';

  $visibility_config //= sprintf 'SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=%s', $metric_name;

  return $self->command(
    'update-web-acl' => [
      $query ? ( '--query' => $query ) : (),
      '--name'              => $name,
      '--id'                => $id,
      '--scope'             => $scope,
      '--default-action'    => $default_action,
      '--visibility-config' => $visibility_config,
      '--description'       => $description,
      '--lock-token'        => $lock_token,
      '--rules'             => sprintf( 'file://%s', $rules_file ),
    ]
  );
}

########################################################################
sub get_web_acl {
########################################################################
  my ( $self, %args ) = @_;

  my ( $scope, $name, $id, $query ) = @args{qw(scope name id query)};

  $scope //= 'REGIONAL';

  return $self->command(
    'get-web-acl' => [
      $query ? ( '--query' => $query ) : (),
      '--id'    => $id,
      '--name'  => $name,
      '--scope' => $scope,
    ]
  );
}

########################################################################
sub associate_web_acl {
########################################################################
  my ( $self, $web_acl_arn, $resource_arn ) = @_;

  return $self->command(
    'associate-web-acl' => [
      '--web-acl-arn'  => $web_acl_arn,
      '--resource-arn' => $resource_arn,
    ]
  );
}

########################################################################
sub list_resources_for_web_acl {
########################################################################
  my ( $self, $web_acl_arn, $query ) = @_;

  return $self->command(
    'list-resources-for-web-acl' => [
      '--web-acl-arn' => $web_acl_arn,
      $query ? ( '--query' => $query ) : (),
    ]
  );
}

1;

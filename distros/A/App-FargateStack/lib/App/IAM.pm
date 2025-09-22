package App::IAM;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use JSON;
use English qw(-no_match_vars);
use File::Temp qw(tempfile);

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    policy_document
    policy_name
    profile
    region
    role_name
    unlink
  )
);

########################################################################
sub policy_exists {
########################################################################
  my ($self) = @_;

  my $name = $self->get_policy_name;

  return $self->command(
    'list-policies' => [
      '--scope'  => 'Local',
      '--query'  => "Policies[?PolicyName=='$name'].Arn",
      '--output' => 'text',
    ]
  );
}

########################################################################
sub delete_role_policy {
########################################################################
  my ( $self, $role_name, $policy_name ) = @_;

  return $self->command(
    'delete-role-policy' => [
      '--role-name'   => $role_name,
      '--policy-name' => $policy_name,
    ]
  );
}

########################################################################
sub delete_role {
########################################################################
  my ( $self, $role_name, $policy_name ) = @_;

  return $self->command( 'delete-role' => [ '--role-name' => $role_name, ] );
}

########################################################################
sub create_policy {
########################################################################
  my ($self) = @_;

  return $self->policy_exists
    if $self->policy_exists;

  my $name = $self->get_policy_name;
  my $doc  = $self->get_policy_document;

  my ( $json_path, $fh ) = tempfile( 'policy-XXXXX', UNLINK => $self->get_unlink, SUFFIX => '.json' );

  print {$fh} encode_json($doc);

  close $fh;

  my @cmd = (
    'aws', 'iam', 'create-policy',
    '--policy-name'     => $name,
    '--policy-document' => "file://$json_path",
    '--profile'         => $self->profile,
  );

  return $self->execute(@cmd);
}

########################################################################
sub is_policy_attached {
########################################################################
  my ( $self, $role_name, $policy_arn ) = @_;

  my $output = $self->command(
    'list-attached-role-policies' => [
      '--role-name' => $role_name,
      '--query'     => sprintf 'AttachedPolicies[?PolicyArn==`%s`].PolicyArn',
      $policy_arn,
      '--output' => 'text',
    ]
  );

  return $output;
}

########################################################################
sub role_exists {
########################################################################
  my ( $self, $role_name, $query ) = @_;

  $role_name //= $self->get_role_name;

  my $result = $self->command(
    'get-role' => [
      '--role-name' => $role_name,
      $query ? ( '--query' => $query ) : ()
    ]
  );

  return $result;
}

########################################################################
sub get_role_policy {
########################################################################
  my ( $self, $role_name, $policy_name ) = @_;

  return $self->command(
    'get-role-policy' => [
      '--role-name'   => $role_name,
      '--policy-name' => $policy_name,
      '--query'       => 'PolicyDocument'
    ]
  );
}

########################################################################
sub put_role_policy {
########################################################################
  my ( $self, $role_name, $policy_name, $policy ) = @_;

  $role_name //= $self->get_role_name;

  my ( $fh, $json_path ) = tempfile( 'policy-XXXXX', UNLINK => $self->get_unlink, SUFFIX => '.json' );
  print {$fh} encode_json($policy);
  close $fh;

  return $self->command(
    'put-role-policy' => [
      '--role-name'       => $role_name,
      '--policy-name'     => $policy_name,
      '--policy-document' => 'file://' . $json_path,
    ]
  );
}

########################################################################
sub create_role {
########################################################################
  my ( $self, $role_name, $trust_policy ) = @_;

  $role_name //= $self->get_role_name;

  my $result = $self->role_exists($role_name);

  return $result
    if $result;

  my ( $fh, $json_path ) = tempfile( 'role-XXXXX', UNLINK => $self->get_unlink, SUFFIX => '.json' );

  print {$fh} encode_json($trust_policy);

  close $fh;

  return $self->command(
    'create-role' => [
      '--role-name'                   => $role_name,
      '--assume-role-policy-document' => "file://$json_path",
      '--query'                       => 'Role.Arn',
      '--output'                      => 'text'
    ]
  );
}

1;

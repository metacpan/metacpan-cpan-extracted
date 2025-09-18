package App::S3Api;

use strict;
use warnings;

use File::Temp qw(tempfile);
use Data::Dumper;

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(region profile name policy));

########################################################################
sub bucket_exists {
########################################################################
  my ($self) = @_;

  my $bucket_name = $self->get_name;

  return $self->command( 'head-bucket' => [ '--bucket' => $bucket_name, ] );
}

########################################################################
sub create_bucket {
########################################################################
  my ( $self, $bucket_name ) = @_;

  $bucket_name //= $self->get_name;

  my $region = $self->region;

  my @location_constraint
    = $region && $region ne 'us-east-1'
    ? ( '--create-bucket-configuration' => sprintf 'LocationConstraint=%s', $region )
    : ();

  my $result = $self->command(
    'create-bucket' => [
      '--bucket' => $bucket_name,
      @location_constraint
    ]
  );

  die $self->get_error
    if $self->get_error;

  return $result;
}

########################################################################
sub put_bucket_policy {
########################################################################
  my ( $self, $policy ) = @_;

  my $bucket_name = $self->get_name;
  $policy //= $self->get_policy;

  return
    if !$policy || !$bucket_name;

  if ( $policy =~ /[.]json$/xms && -s $policy ) {
    $policy = '--cli-input-json ' . $policy;
  }
  elsif ( $policy =~ /\s*{/xsm && eval { decode_json($policy) } ) {
    $policy = '--policy ' . $policy;
  }
  else {
    die sprintf "ERROR: policy [%s] is not found or invalid\n", $policy;
  }

  return $self->command( 'put-bucket-policy' => [ '--bucket' => $bucket_name, ] );
}

########################################################################
sub policy_exists {
########################################################################
  my ($self) = @_;

  my $bucket_name = $self->get_name;

  return $self->command( 'get-bucket-policy' => [ '--bucket' => $bucket_name, ] );
}

1;

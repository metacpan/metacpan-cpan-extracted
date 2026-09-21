package AWS::Signature::V4::Credentials;
use v5.24;
use Moo;
use AWS::Signature::V4::Error qw< fail shown >;
use Digest::SHA qw< hmac_sha256 hmac_sha256_hex >;
use experimental qw< signatures >;
use namespace::clean;

# The credentials-based variant (AWS4-HMAC-SHA256). The options are the ones
# of the "credentials" option of AWS::Signature::V4.
has [qw< access_key_id secret_access_key session_token >] => (is => 'ro');

sub BUILD ($self, $args) {
   if (my ($name) = sort(grep { !m{\A(?:access_key_id|secret_access_key|session_token)\z} } keys $args->%*)) {
      fail 400, 'unknown option "' . shown($name) . '" in credentials';
   }
   for my $name (qw< access_key_id secret_access_key >) {
      my $value = $self->$name;    # empty is like missing, AWS would refuse it
      defined $value && length $value or fail 400, "missing credentials/$name";
   }
   return;
}

# ---- what AWS::Signature::V4 wants from a variant --------------------------

sub algorithm ($self) { 'AWS4-HMAC-SHA256' }

# identifies who signs, in the Credential part of the authorization
sub credential_id ($self) { $self->access_key_id }

# the key derived from the secret, for a scope like "20150830/us-east-1/iam/aws4_request"
sub signing_key ($self, $scope) {
   my ($date, $region, $service, $terminator) = split m{/}, $scope, 4;
   my $key = 'AWS4' . $self->secret_access_key;
   $key = hmac_sha256($_, $key) for $date, $region, $service, $terminator;
   return $key;
}

# hex signature of the string to sign
sub signature ($self, $scope, $string_to_sign) {
   return hmac_sha256_hex($string_to_sign, $self->signing_key($scope));
}

# what goes with the request besides the signature, as (name => value) pairs
sub extra_fields ($self) {
   my $token = $self->session_token;    # empty, e.g. from an empty variable: none
   return defined $token && length $token ? ('X-Amz-Security-Token' => $token) : ();
}

# signed chunks need the derived key
sub can_sign_chunks ($self) { 1 }

1;

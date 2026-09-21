#!/usr/bin/env perl
# The X.509 variant: instead of a secret key, the request is signed with
# the private key of a certificate, as IAM Roles Anywhere wants, to get
# temporary credentials.
#
#    CERT_FILE=cert.pem KEY_FILE=key.pem KEY_TYPE=RSA \
#    TRUST_ANCHOR_ARN=... PROFILE_ARN=... ROLE_ARN=... ./07-rolesanywhere-x509.pl
#
# Optional: CHAIN_FILE (PEM bundle of intermediate CAs), KEY_PASSWORD (for
# encrypted keys), AWS_REGION. KEY_TYPE is RSA (default) or ECDSA.
#
# The session goes on the standard output and nothing else does, so that
# it can be piped into jq or saved for later use. It holds temporary
# credentials: a file it is saved in deserves the same care as a key.
#
# NOTE: check the shape of the CreateSession request (path, body) against
# the current IAM Roles Anywhere API reference before relying on it.
use v5.24;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use HTTP::Tiny;
use JSON::PP qw< encode_json >;

my $region = $ENV{AWS_REGION} // 'us-east-1';

# the region goes in the host name below, so a "/" in it moves the host
# elsewhere: "evil.example.com/x" makes the URL
# https://rolesanywhere.evil.example.com/x.amazonaws.com/sessions, whose
# host is rolesanywhere.evil.example.com. The request carries the
# certificate and its signature, and whatever answered would be written
# out as if it were a session
die "invalid region: letters, digits and dashes only\n"
   unless $region =~ m{\A[a-z0-9-]+\z};

my $signer = AWS::Signature::V4->new(
   service => 'rolesanywhere',
   region  => $region,
   x509    => {
      key_type         => $ENV{KEY_TYPE} // 'RSA',
      certificate_file => $ENV{CERT_FILE} // die("CERT_FILE?\n"),
      private_key_file => $ENV{KEY_FILE}  // die("KEY_FILE?\n"),
      (defined $ENV{CHAIN_FILE}   ? (chain_files          => $ENV{CHAIN_FILE})   : ()),
      (defined $ENV{KEY_PASSWORD} ? (private_key_password => $ENV{KEY_PASSWORD}) : ()),
   },
);
say {*STDERR} 'algorithm: ', $signer->algorithm;

# the ARNs are required; only a dry run, which sends nothing, makes do
# with a placeholder just to show the shape of the request
sub arn {
   my ($name, $placeholder) = @_;
   return $ENV{$name} if defined $ENV{$name} && length $ENV{$name};
   die "$name?\n" unless $ENV{DRY_RUN};
   return $placeholder;
}

my $url  = "https://rolesanywhere.$region.amazonaws.com/sessions";
my $body = encode_json({
   trustAnchorArn  => arn(TRUST_ANCHOR_ARN => 'arn:aws:rolesanywhere:...:trust-anchor/...'),
   profileArn      => arn(PROFILE_ARN      => 'arn:aws:rolesanywhere:...:profile/...'),
   roleArn         => arn(ROLE_ARN         => 'arn:aws:iam::...:role/...'),
   durationSeconds => 3600,
});
my $r = $signer->sign(
   method  => 'POST',
   url     => $url,
   headers => {'Content-Type' => 'application/json'},
   body    => $body,
);
# beside Authorization, the headers now include X-Amz-X509 (the
# certificate) and, if there is one, X-Amz-X509-Chain

# HTTP::Tiny adds the Host header itself, from the URL, and refuses to be
# given one: it is signed all the same, and it will have the same value
my %headers = $r->{headers}->%*;
delete $headers{host};

if ($ENV{DRY_RUN}) {
   # on the standard error like everything that is not a session: a dry
   # run obtains none, so "> session.json" must come out empty rather
   # than hold a dump of the request that was never sent
   say {*STDERR} "POST $url";
   for my $name (sort keys $r->{headers}->%*) {
      my $value = $r->{headers}{$name};
      $value = substr($value, 0, 40) . '...' if length($value) > 60;
      say {*STDERR} "$name: $value";
   }
   say {*STDERR} "\n$body";
   exit 0;
}
my $response = HTTP::Tiny->new(verify_SSL => 1)->request(POST => $url,
   {headers => \%headers, content => $body});
say {*STDERR} "$response->{status} $response->{reason}";
# only a session reaches the standard output, so that "> session.json" or
# a pipe into jq gets JSON and nothing else. An error body is often not
# JSON at all: when the request never got to AWS the status is 599 and
# that field holds the reason as plain text ("Could not connect to ...").
# Saved in the place of a session, it would be a failure kept as if it
# were credentials, and read back as such much later
if (!$response->{success}) {
   say {*STDERR} $response->{content};    # this says what went wrong
   die "the request failed\n";
}
say {*STDOUT} $response->{content};

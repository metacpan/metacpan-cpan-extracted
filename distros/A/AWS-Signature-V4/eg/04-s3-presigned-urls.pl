#!/usr/bin/env perl
# Presigned URLs: the signature travels in the query string, so anyone
# holding the URL can use it until it expires, with any client at all.
#
#    ./04-s3-presigned-urls.pl BUCKET KEY [EXPIRES_SECONDS]
#
# Keys must be given as they appear in the URL: ASCII, percent-encoded
# (a space is %20, a percent sign %25, and so on), because they go in the
# URL as they are written.
use v5.24;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;

my ($bucket, $key, $expires) = @ARGV;
die "usage: $0 BUCKET KEY [EXPIRES_SECONDS]\n" unless defined $key;
my $region = $ENV{AWS_REGION} // 'us-east-1';

# both go in the host name below, so a "/" in either moves the host
# elsewhere: a bucket of "evil.example.com/x" makes the URL
# https://evil.example.com/x.s3... and the URLs printed here, which are
# meant to be handed out and used, would point there instead
die "invalid bucket name: 3 to 63 letters, digits, dots or dashes\n"
   unless $bucket =~ m{\A[A-Za-z0-9][A-Za-z0-9.-]{1,61}[A-Za-z0-9]\z};
die "invalid region: letters, digits and dashes only\n"
   unless $region =~ m{\A[a-z0-9-]+\z};

my $signer = AWS::Signature::V4->new(
   service     => 's3',
   region      => $region,
   credentials => {
      access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
      secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
      session_token     => $ENV{AWS_SESSION_TOKEN},
   },
);

my $url = "https://$bucket.s3.$region.amazonaws.com/$key";
for my $method (qw< GET PUT >) {
   my $p = $signer->presign(
      method  => $method,
      url     => $url,
      expires => $expires // 3600,    # seconds, up to 7 days
   );
   say "$method:\n$p->{url}\n";
}
say 'Try:  curl -o object.bin "<GET url>"';
# -T (--upload-file) streams the file and adds no Content-Type of its own;
# --data-binary would read it all in memory and make S3 store the object as
# application/x-www-form-urlencoded
say 'Try:  curl -T file "<PUT url>"';

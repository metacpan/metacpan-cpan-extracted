#!/usr/bin/env perl
# Upload a file to S3 without loading it in memory: the payload hash is
# computed from a filehandle (body_fh), and HTTP::Tiny reads the same file
# a piece at a time when sending.
#
#    ./03-s3-put-object-from-file.pl FILE BUCKET KEY
#
# Keys must be given as they appear in the URL: ASCII, percent-encoded
# (a space is %20, a percent sign %25, and so on), because they go in the
# URL as they are written.
use v5.24;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use HTTP::Tiny;

my ($file, $bucket, $key) = @ARGV;
die "usage: $0 FILE BUCKET KEY\n" unless defined $key;
my $region = $ENV{AWS_REGION} // 'us-east-1';

# both go in the host name below, so a "/" in either moves the host
# elsewhere: a bucket of "evil.example.com/x" makes the URL
# https://evil.example.com/x.s3... and the signed request, session token
# and the file being uploaded included, is sent there
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

open my $fh, '<:raw', $file or die "open('$file'): $!\n";
my $url = "https://$bucket.s3.$region.amazonaws.com/$key";
my $r = $signer->sign(
   method  => 'PUT',
   url     => $url,
   headers => {
      'Content-Type'   => 'application/octet-stream',
      'Content-Length' => -s $file,    # needed when the body comes from a callback
   },
   body_fh => $fh,    # hashed here, then rewound to where it was
);

# HTTP::Tiny adds the Host header itself, from the URL, and refuses to be
# given one: it is signed all the same, and it will have the same value
my %headers = $r->{headers}->%*;
delete $headers{host};

if ($ENV{DRY_RUN}) {
   say "PUT $url";
   say "$_: $r->{headers}{$_}" for sort keys $r->{headers}->%*;
   exit 0;
}
my $response = HTTP::Tiny->new(verify_SSL => 1)->request(
   PUT => $url,
   {
      headers => \%headers,
      content => sub {
         my $n = read($fh, my $buf, 64 * 1024);
         return $n ? $buf : undef;
      },
   }
);
die "$response->{status} $response->{reason}\n$response->{content}\n"
   unless $response->{success};
say "uploaded $file to s3://$bucket/$key";

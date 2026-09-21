#!/usr/bin/env perl
# Streaming upload to S3 ("aws-chunked"): the body is sent in signed
# chunks, so the whole payload never needs to be hashed in advance, nor
# held in memory. The total size must be known, though.
#
#    ./05-s3-chunked-upload.pl FILE BUCKET KEY
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

my $chunk_size = 64 * 1024;    # S3 wants at least 8 KiB, but the last one
my $size       = -s $file;
open my $fh, '<:raw', $file or die "open('$file'): $!\n";

# set this to (checksum => 'crc32c') for a trailing checksum, see the docs.
# The same options must reach both encoded_length and sign, otherwise the
# announced Content-Length would not count the trailer and the upload would
# fail halfway through
my @checksum = ();

my $url = "https://$bucket.s3.$region.amazonaws.com/$key";
my $r = $signer->sign(
   method  => 'PUT',
   url     => $url,
   headers => {
      # length of the *encoded* body: data plus the per-chunk signatures
      'Content-Length' =>
        AWS::Signature::V4->encoded_length($size, $chunk_size, @checksum),
   },
   streaming              => 1,
   decoded_content_length => $size,
   @checksum,
);
my $chunker = $r->{chunker};

# HTTP::Tiny adds the Host header itself, from the URL, and refuses to be
# given one: it is signed all the same, and it will have the same value
my %headers = $r->{headers}->%*;
delete $headers{host};

if ($ENV{DRY_RUN}) {
   say "PUT $url";
   say "$_: $r->{headers}{$_}" for sort keys $r->{headers}->%*;
   my $sent = 0;
   while (read($fh, my $buf, $chunk_size)) { $sent += length $chunker->chunk($buf) }
   $sent += length $chunker->finish;
   say "\nbody: $sent bytes (announced: $r->{headers}{'content-length'})";
   exit 0;
}
my $done;
my $response = HTTP::Tiny->new(verify_SSL => 1)->request(
   PUT => $url,
   {
      headers => \%headers,
      content => sub {
         return if $done;
         my $n = read($fh, my $buf, $chunk_size);
         return $chunker->chunk($buf) if $n;
         $done = 1;
         return $chunker->finish;    # last, empty chunk (dies if sizes disagree)
      },
   }
);
die "$response->{status} $response->{reason}\n$response->{content}\n"
   unless $response->{success};
say "uploaded $file to s3://$bucket/$key";

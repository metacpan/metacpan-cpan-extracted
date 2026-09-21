#!/usr/bin/env perl
# Download an S3 object. S3 is special (paths are not normalized nor
# double-encoded, the payload hash goes in a header): the module knows
# from the service name.
#
#    ./02-s3-get-object.pl BUCKET KEY [FILE]     # default: print on stdout
#
# Keys must be given as they appear in the URL: ASCII, percent-encoded.
use v5.24;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use HTTP::Tiny;

my ($bucket, $key, $file) = @ARGV;
die "usage: $0 BUCKET KEY [FILE]\n" unless defined $key;
my $region = $ENV{AWS_REGION} // 'us-east-1';

# both go in the host name below, so a "/" in either moves the host
# elsewhere: a bucket of "evil.example.com/x" makes the URL
# https://evil.example.com/x.s3... and the signed request, session token
# included, is sent there
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

# virtual-hosted style: the bucket is part of the host name. A bucket whose
# name contains a dot does not match the *.s3.REGION.amazonaws.com
# certificate, so for those use the path-style URL instead (never turn TLS
# verification off): https://s3.$region.amazonaws.com/$bucket/$key
my $url = "https://$bucket.s3.$region.amazonaws.com/$key";
my $r = $signer->sign(method => 'GET', url => $url);

# HTTP::Tiny adds the Host header itself, from the URL, and refuses to be
# given one: it is signed all the same, and it will have the same value
my %headers = $r->{headers}->%*;
delete $headers{host};

if ($ENV{DRY_RUN}) {
   say "GET $url";
   say "$_: $r->{headers}{$_}" for sort keys $r->{headers}->%*;
   exit 0;
}
my $response = HTTP::Tiny->new(verify_SSL => 1)->get($url, {headers => \%headers});
die "$response->{status} $response->{reason}\n$response->{content}\n"
   unless $response->{success};
if (defined $file) {
   # the whole object is in memory here, because HTTP::Tiny->get was called
   # without a data_callback: for big ones, pass one and write each piece
   open my $fh, '>:raw', $file or die "open('$file'): $!\n";
   print {$fh} $response->{content} or die "print('$file'): $!\n";
   close $fh or die "close('$file'): $!\n";    # a full disk shows up here
}
else {
   binmode STDOUT;
   print $response->{content};
}

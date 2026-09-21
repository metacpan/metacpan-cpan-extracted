#!/usr/bin/env perl
# A JSON API: the operation is chosen by a header, which is signed like
# all the others.
#
#    ./06-dynamodb-json-api.pl [REGION]
use v5.24;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use HTTP::Tiny;
use JSON::PP qw< encode_json decode_json >;

my $region = shift // $ENV{AWS_REGION} // 'us-east-1';
my $signer = AWS::Signature::V4->new(
   service     => 'dynamodb',
   region      => $region,
   credentials => {
      access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
      secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
      session_token     => $ENV{AWS_SESSION_TOKEN},
   },
);

my $url  = "https://dynamodb.$region.amazonaws.com/";
my $body = encode_json({Limit => 10});    # JSON::PP gives bytes, as required
my $r = $signer->sign(
   method  => 'POST',
   url     => $url,
   headers => {
      'Content-Type' => 'application/x-amz-json-1.0',
      'X-Amz-Target' => 'DynamoDB_20120810.ListTables',
   },
   body => $body,
);

# HTTP::Tiny adds the Host header itself, from the URL, and refuses to be
# given one: it is signed all the same, and it will have the same value
my %headers = $r->{headers}->%*;
delete $headers{host};

if ($ENV{DRY_RUN}) {
   say "POST $url";
   say "$_: $r->{headers}{$_}" for sort keys $r->{headers}->%*;
   say "\n$body";
   exit 0;
}
my $response = HTTP::Tiny->new(verify_SSL => 1)->request(POST => $url,
   {headers => \%headers, content => $body});
die "$response->{status} $response->{reason}\n$response->{content}\n"
   unless $response->{success};
say "table: $_" for decode_json($response->{content})->{TableNames}->@*;

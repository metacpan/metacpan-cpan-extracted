#!/usr/bin/env perl
# The simplest case: a signed POST with credentials taken from the
# environment, sent with HTTP::Tiny (any other user agent would do).
#
#    AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... ./01-sts-get-caller-identity.pl
#
# Set DRY_RUN=1 to see the signed request instead of sending it.
use v5.24;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use HTTP::Tiny;

my $signer = AWS::Signature::V4->new(
   service     => 'sts',
   region      => 'us-east-1',
   credentials => {
      access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
      secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
      session_token     => $ENV{AWS_SESSION_TOKEN},    # optional
   },
);

my $url  = 'https://sts.amazonaws.com/';
my $body = 'Action=GetCallerIdentity&Version=2011-06-15';
my $r    = $signer->sign(
   method  => 'POST',
   url     => $url,
   headers => {'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'},
   body    => $body,
);

# HTTP::Tiny adds the Host header itself, from the URL, and refuses to be
# given one: it is signed all the same, and it will have the same value
my %headers = $r->{headers}->%*;
delete $headers{host};

# $r->{headers} is everything to put on the request, signature included
if ($ENV{DRY_RUN}) {
   say "POST $url";
   say "$_: $r->{headers}{$_}" for sort keys $r->{headers}->%*;
   say "\n$body";
   exit 0;
}
my $response = HTTP::Tiny->new(verify_SSL => 1)->request(POST => $url,
   {headers => \%headers, content => $body});
say "$response->{status} $response->{reason}";
say $response->{content};
# the body above explains what went wrong; exit non-zero all the same, so
# that `./01-sts-get-caller-identity.pl && something-else` does the right
# thing when the credentials are not good
die "the request failed\n" unless $response->{success};

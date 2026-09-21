#!/usr/bin/env perl
# No network, no secrets: reproduce the example of the AWS documentation
# and look at all the intermediate values, which is what helps when AWS
# answers "SignatureDoesNotMatch". Fixing the time makes it repeatable.
#
#    ./09-inspect-a-signature.pl
use v5.24;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;

my $signer = AWS::Signature::V4->new(
   service     => 'iam',
   region      => 'us-east-1',
   credentials => {
      access_key_id     => 'AKIDEXAMPLE',
      secret_access_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
   },
);
my $r = $signer->sign(
   method  => 'GET',
   url     => 'https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08',
   headers => {'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'},
   time    => 1440938160,    # 2015-08-30T12:36:00Z
);

say "--- canonical request\n$r->{canonical_request}";
say "\n--- string to sign\n$r->{string_to_sign}";
say "\n--- authorization\n$r->{authorization}";

my $expected = '5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7';
say "\nsignature ", ($r->{signature} eq $expected ? 'matches' : 'DIFFERS FROM'),
   ' the one in the AWS documentation';

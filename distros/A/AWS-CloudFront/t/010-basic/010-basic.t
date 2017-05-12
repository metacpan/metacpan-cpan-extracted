#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('AWS::CloudFront');

unless( $ENV{AWS_ACCESS_KEY_ID} && $ENV{AWS_SECRET_ACCESS_KEY} )
{
  warn '$ENV{AWS_ACCESS_KEY_ID} && $ENV{AWS_SECRET_ACCESS_KEY} must both be defined to run these tests.', "\n";
  exit(0);
}# end unless()

my $cf = AWS::CloudFront->new(
  access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
  secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
);

ok( $cf, 'got a new cloudfront object' );

use_ok('AWS::S3');

my $s3 = AWS::S3->new(
  access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
  secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
);

ok( $s3, 'got an s3 object too');

my @dists = $cf->distributions();

foreach my $dist ( @dists )
{
  is $dist->Id, $cf->distribution(Id => $dist->Id)->Id, 'Ids match up';
}# end foreach()


my $dist = $cf->add_distribution(
  Origin  => AWS::CloudFront::S3Origin->new(
    DNSName => 'aws-s3-test-12344.s3.amazonaws.com',
  ),
);

warn "New Dist ID: " . $dist->Id;

my $ident = $dist->create_origin_access_identity( Comment => 'testing only' );
use Data::Dumper;
warn Dumper( $ident );

while( 1 )
{
  warn "Checking status of ", $dist->Id, "\n";
  last if $cf->distribution(Id => $dist->Id)->Status eq 'Deployed';
  sleep(2);
}# end while()

$dist->Enabled(0);
$dist->update;
$dist->delete;



#!/usr/bin/perl

use strict;
use Test::More;
use AnyEvent::EC2::Tiny;
use Data::Dumper;
use Carp;

BEGIN { 
    if (! $ENV{AWS_ACCESS_KEY} || ! $ENV{AWS_SECRET_KEY} ) {
        plan skip_all => "Set AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables to run this test.";
    }
    else {
        plan tests => 9;
    }
};

my $cv  = AE::cv;
my $ec2 = AnyEvent::EC2::Tiny->new(
    AWSAccessKey => $ENV{AWS_ACCESS_KEY},
    AWSSecretKey => $ENV{AWS_SECRET_KEY},
);

isa_ok($ec2, 'AnyEvent::EC2::Tiny');

is($ec2->region, 'us-east-1', 'Region default correct');
is($ec2->version, '2012-07-20', 'API version default correct');
is($ec2->base_url, 'https://ec2.us-east-1.amazonaws.com', 'Default base url correct');

my $count = 0;
my $xml   = $ec2->send(
    Action         => 'DescribeRegions',
    'RegionName.1' => 'us-east-1',
    'RegionName.2' => 'eu-west-1',

    success_cb => sub {
        my $xml = shift;
        diag Dumper $xml;

        is(scalar @{$xml->{regionInfo}->{item}}, 2, '2 regions retrieved');
        is($xml->{regionInfo}->{item}->[0]->{regionName}, 'us-east-1', '1st regionName correct');
        is($xml->{regionInfo}->{item}->[1]->{regionName}, 'eu-west-1', '2nd regionName correct');
        $count++;
        $cv->send;
    },

    fail_cb => sub {
        my $error = shift;
        diag Dumper $error;
        $cv->send;
    },
);

cmp_ok( $count, '==', 0, 'No request made yet' );
$cv->recv;
cmp_ok( $count, '==', 1, 'Request done' );


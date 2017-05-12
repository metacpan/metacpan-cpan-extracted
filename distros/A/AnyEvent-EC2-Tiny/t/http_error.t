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
        plan tests => 15;
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
    Action         => 'SomeActionThatIsntSupported',
    'RegionName.1' => 'us-east-1',
    'RegionName.2' => 'eu-west-1',

    success_cb => sub {
        my $xml = shift;
        diag Dumper $xml;
        $cv->send;
    },

    fail_cb => sub {
        my $error = shift;
        isa_ok( $error, 'HASH', 'Got correct error hashref' );
        ok( exists $error->{'text'}, 'Got error text' );
        ok( exists $error->{'type'}, 'Got error type' );
        ok( exists $error->{'data'}, 'Got error data' );
        is( $error->{'type'}, 'HTTP', 'Error type is HTTP' );
        ok( exists $error->{'data'}{'body'}, 'Got body in data' );
        ok( exists $error->{'data'}{'headers'}, 'Got headers in data' );
        is( $error->{'data'}{'headers'}{'Reason'}, 'Bad Request', 'Bad req' );
        like( $error->{'text'}, qr/400 Bad Request/, 'Correct text' );
        $count++;
        diag Dumper $error;
        $cv->send;
    },
);

cmp_ok( $count, '==', 0, 'No request made yet' );
$cv->recv;
cmp_ok( $count, '==', 1, 'Request done' );


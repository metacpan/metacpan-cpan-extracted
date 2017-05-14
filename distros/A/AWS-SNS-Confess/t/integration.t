#!/usr/bin/perl -w

# Test with a real AWS account

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Test::Exception;

use lib "../lib";
BEGIN {
 use_ok('AWS::SNS::Confess', qw/confess/);
}

SKIP: {
  skip "no environment variables", 1 unless ( $ENV{AWS_ACCESS_KEY_ID} && $ENV{AWS_SECRET_ACCESS_KEY} && $ENV{AWS_TOPIC} );
  ok(AWS::SNS::Confess::setup(
    access_key_id => $ENV{AWS_ACCESS_KEY_ID},
    secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
    topic => $ENV{AWS_TOPIC},
  ), "setup went okay");
  dies_ok { confess "this should show up in the topic's feed"  } "sending confess died";

  print "check manually if the SNS message was sent\n";

};

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok('Amazon::SQS::Config');

our $DATA_POSITION = tell *DATA;

########################################################################
subtest 'read config' => sub {
########################################################################
  my $fh = *DATA;
  seek $fh, $DATA_POSITION, 0;

  my $config = Amazon::SQS::Config->new(file => $fh);

  isa_ok($config, 'Amazon::SQS::Config');

  my @sections = $config->get_config->Sections;

  foreach my $section (@sections) {
    foreach ( $config->get_config->Parameters($section) ) {
      my $name = $section eq 'main' ? "get_$_" : "get_${section}_$_";
      ok($config->can($name),  "can $name");
    }
  }
};

done_testing;

1;

__DATA__
# AWS Settings
handler = MyHandler

[queue]
interval = 2 
max_wait = 20 
visibility_timeout = 60

[aws]
access_key_id = <Your Access Key ID>
secret_access_key = <Your Secret Access Key>
queue_url = https://queue.amazonaws.com/<your-account-number>/<your-queue-name>

[log]
stdout = /tmp/amazon_sqs.log
stderr = /tmp/amazon_sqs.log


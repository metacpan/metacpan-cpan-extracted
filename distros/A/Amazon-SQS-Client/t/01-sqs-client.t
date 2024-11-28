#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(any);

my $client;

plan skip_all => 'no service set'
  if !$ENV{SERVICE_URL};

########################################################################
subtest 'create client' => sub {
########################################################################
  use_ok('Amazon::SQS::Client');

  local $ENV{AWS_ACCESS_KEY_ID}     = 'TEST';
  local $ENV{AWS_SECRET_ACCESS_KEY} = 'TEST';

  $client = Amazon::SQS::Client->new( undef, undef, { ServiceURL => $ENV{SERVICE_URL} } );

  isa_ok( $client, 'Amazon::SQS::Client' )
    or BAIL_OUT('could not create client');
};

my $queueUrl;

########################################################################
subtest 'create queue' => sub {
########################################################################
  my $rsp = $client->createQueue( { QueueName => 'fooManQueue' } );

  my $result = $rsp->getCreateQueueResult();

  isa_ok( $result, 'Amazon::SQS::Model::CreateQueueResult')
    or BAIL_OUT('could not create queue');

  $queueUrl = $result->getQueueUrl;

  like( $queueUrl, qr/http.*\/fooManQueue/xsm )
    or diag( Dumper( [ result => $result ] ) );
};

########################################################################
subtest 'create queue' => sub {
########################################################################
  my $rsp = $client->listQueues();

  my $result = $rsp->getListQueuesResult();
  isa_ok($result, 'Amazon::SQS::Model::ListQueuesResult')
    or BAIL_OUT('could not list queues');

  my $queueUrls = $result->getQueueUrl();
  isa_ok( $queueUrls, 'ARRAY' );

  ok( any { $_ =~ /fooManQueue/xsm } @{$queueUrls} );
};

########################################################################
subtest 'send message' => sub {
########################################################################
  my $rsp = $client->sendMessage({ QueueUrl => $queueUrl,
                                   MessageBody => 'test message'
                                 }
                                 );

  my $result = $rsp->getSendMessageResult();
  isa_ok($result, 'Amazon::SQS::Model::SendMessageResult');

  my $messageId = $result->getMessageId();
  ok($messageId, 'got a messageId ' . $messageId);
};

########################################################################
subtest 'read message' => sub {
########################################################################
  my $rsp = $client->receiveMessage( { QueueUrl => $queueUrl, } );

  my $result = $rsp->getReceiveMessageResult();
  isa_ok($result, 'Amazon::SQS::Model::ReceiveMessageResult');

  my $messageList = $result->getMessage();
  isa_ok($messageList, 'ARRAY');

  my $message = $messageList->[0];
  isa_ok($message, 'Amazon::SQS::Model::Message');

  ok($message, 'got a message');

  ok($message->getMessageId(), 'got a message id ' . $message->getMessageId());

  is($message->getBody(), 'test message', 'received the test message');

  $client->deleteMessage({ QueueUrl => $queueUrl, ReceiptHandle => $message->getReceiptHandle });

  sleep(2);

  $rsp = $client->receiveMessage({QueueUrl => $queueUrl});
  $result = $rsp->getReceiveMessageResult();
  $messageList = $result->getMessage();

  ok(@{$messageList} == 0, 'no more messages');
};

done_testing;

1;

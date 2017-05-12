use strict;
use warnings;

use AnyEvent;
use Amazon::SQS::Simple;
use Amazon::SQS::Simple::AnyEvent;
use Data::Dumper;

#--------------------------------------------------------------------
# This example fetches 10 message batches in parallel and dumps
# the messages in each batch to STDOUT when the batch arrives.
#--------------------------------------------------------------------

# Substitute these arguments with your own...
my $sqs   = Amazon::SQS::Simple->new("ACCESS_KEY", "SECRET_KEY");
my $queue = $sqs->GetQueue("QUEUE_NAME");

my $cv = AnyEvent->condvar;
my $cb = sub { print Dumper \@_; $cv->end };

for (1..10) {
    $cv->begin;
    $queue->ReceiveMessageBatch($cb);
}

$cv->recv;

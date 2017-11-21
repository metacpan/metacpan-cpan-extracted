use strict;
use warnings;
use AnyEvent;
use Argon;
use Argon::Log;
require Argon::Client;

$Argon::ALLOW_EVAL = 1;
log_level('trace');

my $conn = AE::cv;
my $run  = AE::cv;

my $client = Argon::Client->new(
  host    => 'localhost',
  port    => 8000,
  keyfile => 'scratch/key',
  opened  => sub { $conn->send },
);

$conn->recv;

$client->process(sub { exit 0;$_[0] }, [42], sub { my $reply = shift; printf "result: %s\n", $reply->result; $run->send });

$run->recv;

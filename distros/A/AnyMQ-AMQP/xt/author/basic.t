use Test::More;
use Time::HiRes 'time';
use strict;
use AnyEvent;
use AnyMQ;
use AnyEvent::RabbitMQ;

my $bus = AnyMQ->new_with_traits(traits => ['AMQP'],
                                 host   => 'localhost',
                                 port   => 5672,
                                 user   => 'guest',
                                 pass   => 'guest',
                                 vhost  => '/',
                                 exchange => 'foo',
                             );

my $bus2 = AnyMQ->new_with_traits(traits => ['AMQP'],
                                 host   => 'localhost',
                                 port   => 5672,
                                 user   => 'guest',
                                 pass   => 'guest',
                                 vhost  => '/',
                                 exchange => 'foo',
                             );

my $ext_channel = $bus2->_rf_channel;

is($bus->host, 'localhost');

#$cv->recv;
$bus->cv(AE::cv);
my $test = $bus->topic({ name => 'test_q', publisher_only => 0});
$bus->cv->recv;

my $q = AE::cv;
my $q2 = AE::cv;
my $c2 = AE::cv;
$c2->begin(sub { $q2->send([1])});
$c2->begin;

my $client = $bus->new_listener; $client->subscribe($test);
my $cnt = 0;
$client->poll( sub {
                   my $timestamp = shift->{time};
                   ++$cnt;
                   diag "client latency($cnt): ".(time() - $timestamp);
                   if ($cnt == 10) {
                       $q->send([1]);
                   }
                   elsif ($cnt > 10) {
                       $c2->end;
                   }
                   elsif ($cnt > 11) {
                       diag "something is wrong: ".$cnt;
                       $q2->send([0, 'extra message received.']);
                   }
               });

# messages coming to the exchange should be bound to our queue
$ext_channel->publish( routing_key => 'test_q',
                       exchange => 'foo',
                       body => JSON::to_json({ time => time() }),
                   ) for 1..10;

my $w; $w = AnyEvent->timer( after => 5,
                             cb => sub {
                                 $q->send([0, 'test timeout']);
                             } );
my ($ok, $msg) = @{$q->recv};
ok($ok, $msg);

$bus2->cv(AE::cv);
my $test2 = $bus2->topic({name => 'test_q', publisher_only => 0});
$bus2->cv->recv;

my $client2 = $bus2->new_listener; $client2->subscribe($test2);

$client2->poll( sub {
                    my $timestamp = shift->{time};
                    diag "client2 latency: ".(time() - $timestamp);
                    $c2->end;
                });

$test->publish({ time => time() });

$w = AnyEvent->timer( after => 5,
                      cb => sub {
                          $q2->send([0, 'test timeout']);
                      } );

($ok, $msg) = @{$q2->recv};
ok($ok, $msg);

undef $bus; undef $bus2;

done_testing;

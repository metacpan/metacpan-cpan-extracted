#!/usr/bin/env perl
use 5.12.1;
use Crixa;

my $mq = Crixa->connect( host => "localhost", );
my $exchange = $mq->exchange(
    name          => 'topic_logs',
    exchange_type => 'topic'
);

my $routing_key = @ARGV > 1 ? shift @ARGV : 'anonymous.info';
my $message = join( ' ', @ARGV ) || 'Hello World!';

$exchange->publish( { routing_key => $routing_key, body => $message } );

__END__

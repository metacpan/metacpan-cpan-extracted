#!/usr/bin/env perl
use 5.12.1;
use Crixa;

my $mq = Crixa->connect( host => "localhost", );
my $exchange = $mq->exchange(
    name          => 'direct_logs',
    exchange_type => 'direct'
);

my $severity = @ARGV > 1 ? shift @ARGV : 'info';
my $message = join( ' ', @ARGV ) || 'Hello World!';

$exchange->publish( { routing_key => $severity, body => $message } );

__END__

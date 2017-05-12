#!/usr/bin/env perl
use 5.12.1;
use Crixa;

my $mq = Crixa->connect( host => "localhost", );
my $exchange = $mq->exchange( name => 'logs', exchange_type => 'fanout' );

my $message = join( ' ', @ARGV ) || 'info: Hello World!';

$exchange->publish($message);

__END__

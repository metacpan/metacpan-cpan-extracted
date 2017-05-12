#!/usr/bin/env perl
use 5.12.1;
use Crixa;

my $mq       = Crixa->connect( host => "localhost", );
my $chan     = $mq->channel;
my $exchange = $chan->exchange( name => 'logs', exchange_type => 'fanout' );
my $q        = $exchange->queue( exclusive => 1 );

say ' [*] Waiting for logs. To exit press CTRL+C';
$q->handle_message( sub { say $_->{body} } );

__END__

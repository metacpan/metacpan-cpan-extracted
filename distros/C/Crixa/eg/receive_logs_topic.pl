#!/usr/bin/env perl
use 5.12.1;
use Crixa;

my $mq = Crixa->connect( host => "localhost", );
my $chan = $mq->channel;
my $exchange
    = $chan->exchange( name => 'topic_logs', exchange_type => 'topic' );

my @binding_keys = @ARGV;
die "Usage: $0 [info] [warning] [error]" unless @binding_keys;

my $q = $exchange->queue( exclusive => 1, bindings => \@binding_keys );

say ' [*] Waiting for logs. To exit press CTRL+C';
$q->handle_message( sub { say "$_->{routing_key} $_->{body}" } );

__END__

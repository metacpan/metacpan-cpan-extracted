#!/usr/bin/env perl
use 5.12.1;
use Crixa;

my $mq = Crixa->connect( host => "localhost", );
my $chan = $mq->channel;
my $exchange
    = $chan->exchange( name => 'direct_logs', exchange_type => 'direct' );

my @severities = @ARGV;
die "Usage: $0 [info] [warning] [error]" unless @severities;

my $q = $exchange->queue( exclusive => 1, bindings => \@severities );

say ' [*] Waiting for logs. To exit press CTRL+C';
$q->handle_message( sub { say "$_->{routing_key} $_->{body}" } );

__END__

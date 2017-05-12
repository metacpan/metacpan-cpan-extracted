#!/usr/bin/env perl
use 5.12.1;
use Crixa;

my $mq = Crixa->connect( host => "localhost", );
my $q = $mq->queue( name => 'task_queue', durable => 1, );

my $message = join( ' ', @ARGV ) || 'Hello World!';

$q->publish(
    {   body          => $message,
        delivery_mode => 2,          # make message persistent
    }
);

__END__

use strict;
use warnings;

use Async::Queue;
use AE;

sub some_processing {
    my $task = shift;
    return ($task + 2, $task * 2, $task * $task);
}

sub some_async_processing {
    my ($task, %options) = @_;
    my $w; $w = AE::idle sub {
        undef $w;
        $options{on_finish}->($task + 2, $task * 2, $task * $task);
    };
}

{
    my $q = Async::Queue->new(worker => sub {
        my ($task, $callback, $queue) = @_;
        my @results = some_processing($task);
        $callback->(@results);
    });
    $q->push(3, sub {
        my @results = @_;
        print join(", ", @results) . "\n";
    });
}

{
    my $cv = AE::cv;
    my $q = Async::Queue->new(worker => sub {
        my ($task, $callback, $queue) = @_;
        some_async_processing($task, on_finish => sub {
            my @results = @_;
            $callback->(@results);
        });
    });
    $q->push(3, sub {
        my @results = @_;
        print join(", ", @results) . "\n";
        $cv->send;
    });
    $cv->recv;
}



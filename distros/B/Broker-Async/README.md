# NAME

Broker::Async - broker tasks for multiple workers

<div>
    <a href="https://travis-ci.org/mark-5/p5-broker-async"><img src="https://travis-ci.org/mark-5/p5-broker-async.svg?branch=master"></a>
</div>

# SYNOPSIS

    my @workers;
    for my $uri (@uris) {
        my $client = SomeClient->new($uri);
        push @workers, sub { $client->request(@_) };
    }

    my $broker = Broker::Async->new(workers => \@workers);
    for my $future (map $broker->do($_), @requests) {
        my $result = $future->get;
        ...
    }

# DESCRIPTION

This module brokers tasks for multiple asynchronous workers. A worker can be any code reference that returns a [Future](https://metacpan.org/pod/Future), representing work awaiting completion.

Some common use cases include throttling asynchronous requests to a server, or delegating tasks to a limited number of processes.

# ATTRIBUTES

## workers

An array ref of workers used for handling tasks.
Can be a code reference, a hash ref of [Broker::Async::Worker](https://metacpan.org/pod/Broker::Async::Worker) arguments, or a [Broker::Async::Worker](https://metacpan.org/pod/Broker::Async::Worker) object.
Every invocation of a worker must return a [Future](https://metacpan.org/pod/Future) object.

Under the hood, code and hash references are simply used to instantiate a [Broker::Async::Worker](https://metacpan.org/pod/Broker::Async::Worker) object.
See [Broker::Async::Worker](https://metacpan.org/pod/Broker::Async::Worker) for more documentation about how these parameters are used.

# METHODS

## new

    my $broker = Broker::Async->new(
        workers => [ sub { ... }, ... ],
    );

## do

    my $future = $broker->do(@args);

Queue the invocation of a worker with @args.
@args can be any data structure, and is passed as is to a worker code ref.
Returns a [Future](https://metacpan.org/pod/Future) object that resolves when the work is done.

There is no guarantee when a worker will be called, that depends on when a worker becomes available.
However, calls are guaranteed to be invoked in the order they are seen by $broker->do.

# AUTHOR

Mark Flickinger <maf@cpan.org>

# LICENSE

This software is licensed under the same terms as Perl itself.

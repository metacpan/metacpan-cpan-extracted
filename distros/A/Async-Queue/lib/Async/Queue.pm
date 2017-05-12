package Async::Queue;

use 5.006;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(looks_like_number);

sub new {
    my ($class, %options) = @_;
    my $self = bless {
        concurrency => 1,
        worker => undef,
        drain => undef,
        empty => undef,
        saturated => undef,
        task_queue => [],
        running => 0,
    }, $class;
    $self->$_($options{$_}) foreach qw(concurrency worker drain empty saturated);
    return $self;
}

sub _define_hook_accessors {
    my ($name, %options) = @_;
    my $class = __PACKAGE__;
    my $fullname = "${class}::$name";
    no strict 'refs';
    *{$fullname} = sub {
        my ($self, $v) = @_;
        if(@_ > 1) {
            croak "$name must not be undef." if !defined($v) && !$options{allow_undef};
            croak "$name must be a coderef" if defined($v) && ref($v) ne 'CODE';
            croak "You cannot set $name while there is a running task." if $self->running > 0;
            $self->{$name} = $v;
        }
        return $self->{$name};
    };
}

sub running {
    my ($self) = @_;
    return $self->{running};
}

sub concurrency {
    my ($self, $conc) = @_;
    if(@_ > 1) {
        croak "You cannot set concurrency while there is a running task" if $self->running > 0;
        $conc = 1 if not defined($conc);
        croak "concurrency must be a number" if !looks_like_number($conc);
        $self->{concurrency} = int($conc);
    }
    return $self->{concurrency};
}

sub length {
    my ($self) = @_;
    return int(@{$self->{task_queue}});
}

*waiting = \&length;

_define_hook_accessors 'worker';
_define_hook_accessors $_, allow_undef => 1 foreach qw(drain empty saturated);

sub push {
    my ($self, $task, $cb) = @_;
    if(@_ < 2) {
        croak("You must specify something to push.");
    }
    if(defined($cb) && ref($cb) ne 'CODE') {
        croak("callback for a task must be a coderef");
    }
    push(@{$self->{task_queue}}, [$task, $cb]);
    $self->_shift_run(1);
    return $self;
}

sub _shift_run {
    my ($self, $from_push) = @_;
    return if $self->concurrency > 0 && $self->running >= $self->concurrency;
    my $args_ref = shift(@{$self->{task_queue}});
    return if !defined($args_ref);
    my ($task, $cb) = @$args_ref;
    $self->{running} += 1;
    if($self->running == $self->concurrency && $from_push && defined($self->saturated)) {
        $self->saturated->($self);
    }
    if(@{$self->{task_queue}} == 0 && defined($self->empty)) {
        $self->empty->($self);
    }
    my $sync = 1;
    my $sync_completed = 0;
    $self->worker->($task, sub {
        my (@worker_results) = @_;
        $cb->(@worker_results) if defined($cb);
        $self->{running} -= 1;
        if(@{$self->{task_queue}} == 0 && $self->running == 0 && defined($self->drain)) {
            $self->drain->($self);
        }
        if($sync) {
            $sync_completed = 1;
        }else {
            @_ = ($self);
            goto &_shift_run;
        }
    }, $self);
    $sync = 0;
    if($sync_completed) {
        @_ = ($self);
        goto &_shift_run;
    }
}


=head1 NAME

Async::Queue - control concurrency of asynchronous tasks

=head1 VERSION

Version 0.021

=cut

our $VERSION = '0.021';


=head1 SYNOPSIS


    use Async::Queue;
    
    ## create a queue object with concurrency 2
    my $q = Async::Queue->new(
        concurrency => 2, worker => sub {
            my ($task, $callback) = @_;
            print "hello $task->{name}\n";
            $callback->();
        }
    );
    
    ## assign a callback
    $q->drain(sub {
        print "all items have been processed\n";
    });
    
    ## add some items to the queue
    $q->push({name => 'foo'}, sub {
        print "finished processing foo\n";
    });
    $q->push({name => 'bar'}, sub {
        print "finished processing bar\n";
    });


=head1 DESCRIPTION

L<Async::Queue> is used to process tasks with the specified concurrency.
The tasks given to L<Async::Queue> are processed in parallel with its worker routine up to the concurrency level.
If more tasks arrive at the L<Async::Queue> object, those tasks will wait for currently running tasks to finish.
When a task is finished, one of the waiting tasks starts to be processed in first-in-first-out (FIFO) order.

In short, L<Async::Queue> is a Perl port of the C<queue> object of async.js (L<https://github.com/caolan/async#queue>).

The basic usage of L<Async::Queue> is as follows:

=over

=item 1.

Create L<Async::Queue> object with C<worker> attribute and optional C<concurrency> attribute.
C<worker> is a subroutine reference that processes tasks. C<concurrency> is the concurrency level.

=item 2.

Push tasks to the L<Async::Queue> object via C<push()> method with optional callback functions.

The tasks will be processed in FIFO order by the C<worker> subroutine.
When a task is finished, the callback function, if any, is called with the results.


=back


=head1 CLASS METHODS

=head2 $queue = Async::Queue->new(%attributes);

Creates an L<Async::Queue> object.

It takes named arguments to initialize attributes of the L<Async::Queue> object.
See L</ATTRIBUTES> for the list of the attributes.

C<worker> attribute is mandatory.


=head1 ATTRIBUTES

An L<Async::Queue> object has the following attributes.

You can initialize the attributes in C<new()> method.
You can get and set the attributes of an L<Async::Queue> object via their accessor methods (See L</"OBJECT METHODS">).

Note that you cannot set any attribute listed here while there is a task running in the L<Async::Queue> object.
This is because changing the attributes during task execution is very confusing and leads to unpredictable behavior.
So if you want to set an attribute, make sure there is no task running (C<running()> method can be useful).

=head2 worker (CODE($task, $callback, $queue), mandatory)

C<worker> attribute is a subroutine reference that processes a task. It must not be C<undef>.

C<worker> subroutine reference takes three arguments, C<$task>, C<$callback> and C<$queue>.

C<$task> is the task object the C<worker> is supposed to process.

C<$callback> is a callback subroutine reference that C<worker> must call when the task is finished.
C<$callback> can take any list of arguments, which will be passed to the C<$finish_callback> given to the C<push()> method
(See L</"OBJECT METHODS">).

C<$queue> is the L<Async::Queue> object that holds the worker.

So the C<worker> attribute is something like:

    my $q = Async::Queue->new(worker => sub {
        my ($task, $callback, $queue) = @_;
        my @results = some_processing($task);
        $callback->(@results);
    });

You can do asynchonous processing by deferring the call to C<$callback>:

    my $q = Async::Queue->new(worker => sub {
        my ($task, $callback, $queue) = @_;
        some_async_processing($task, on_finish => sub {
            my @results = @_;
            $callback->(@results);
        });
    });


=head2 concurrency (INT, optional, default = 1)

C<concurrency> attribute is the maximum number of tasks that can be processed at the same time.
It must be an integer number.

If C<concurrency> is set to 0 or any negative number, the concurrency level becomes infinite,
i.e. pushed tasks are immediately processed no matter how many are already running.

If C<concurrency> is set to C<undef> (or omitted in C<new()> method), it will be 1.


=head2 saturated (CODE($queue), optional, default = undef)

C<saturated> attribute is a subroutine reference that is called when the number of running tasks hits C<concurrency>.
This means further tasks will wait in the queue.

C<saturated> subroutine reference takes one argument (C<$queue>), which is the L<Async::Queue> object holding it.


=head2 empty (CODE($queue), optional, default = undef)

C<empty> attribute is a subroutine reference that is called when the last task from the queue is given to the worker.
This means there is no task waiting in the L<Async::Queue> object.

If the L<Async::Queue> object is not saturated, C<empty> subroutine is called every time a task is pushed.
This is because every pushed task goes into the queue first even if the L<Async::Queue> object can process the task immediately.

C<empty> subroutine reference takes one argument (C<$queue>), which is the L<Async::Queue> object holding it.

=head2 drain (CODE($queue), optional, default = undef)

C<drain> attribute is a subroutine reference that is called when the last task in the L<Async::Queue> object has finished.
This means there is no task running or waiting in the L<Async::Queue> object.

C<drain> subroutine reference takes one argument (C<$queue>), which is the C<Async::Queue> object holding it.

=head1 OBJECT METHODS

=head2 $queue->push($task, [$finish_callback->(@results)] );

Pushes a task into the L<Async::Queue> object.
The argument C<$task> is mandatory, while C<$finish_callback> is optional.

C<$task> is a task that the worker will process. It will be given as the C<$task> argument to the C<worker> subroutine.

C<$finish_callback> is a subroutine reference that will be called when the worker finishes processing the task.
The arguments for C<$finish_callback> (C<@results>) are the arguments for the C<$callback> subroutine reference in the C<worker> subroutine.

C<push()> method returns the L<Async::Queue> object.

=head2 $running_num = $queue->running();

Returns the number of currently running tasks in the L<Async::Queue> object.

=head2 $waiting_num = $queue->waiting();

Returns the number of waiting tasks in the L<Async::Queue> object.

=head2 $waiting_num = $queue->length();

Alias for C<waiting()> method. It returns the number of waiting tasks in the L<Async::Queue> object.

=head2 $worker = $queue->worker([$new_worker]);

Accessor for the C<worker> attribute.

=head2 $concurrency = $queue->concurrency([$new_concurrency]);

Accessor for the C<concurrency> attribute.

=head2 $saturated = $queue->saturated([$new_saturated]);

Accessor for the C<saturated> attribute.

=head2 $empty = $queue->empty([$new_empty]);

Accessor for the C<empty> attribute.

=head2 $drain = $queue->drain([$new_drain]);

Accessor for the C<drain> attribute.

=head1 EXAMPLE

=head2 Concurrent HTTP downloader

    use strict;
    use warnings;
    use AnyEvent;
    use AnyEvent::HTTP;
    use Async::Queue;
    
    my $q = Async::Queue->new(concurrency => 3, worker => sub {
        my ($url, $callback) = @_;
        print STDERR "Start $url\n";
        http_get $url, sub {
            my ($data, $headers) = @_;
            print STDERR "End $url\n";
            $callback->($data);
        };
    });
    
    my @urls = (
        'http://www.debian.org/',
        'http://www.ubuntu.com/',
        'http://fedoraproject.org/',
        'http://www.opensuse.org/',
        'http://www.centos.org/',
        'http://www.slackware.com/',
        'http://www.gentoo.org/',
        'http://www.archlinux.org/',
        'http://trisquel.info/',
    );
    
    my %results = ();
    my $cv = AnyEvent->condvar;
    foreach my $url (@urls) {
        $cv->begin();
        $q->push($url, sub {
            my ($data) = @_;
            $results{$url} = $data;
            $cv->end();
        });
    }
    $cv->recv;
    
    foreach my $key (keys %results) {
        print STDERR "$key: " . length($results{$key}) . "bytes\n";
    }

This example uses L<AnyEvent::HTTP> to send HTTP GET requests for multiple URLs simultaneously.
While simultaneous requests dramatically improve efficiency, it may overload the client host
and/or the network.

This is where L<Async::Queue> comes in handy. With L<Async::Queue> you can control the concurrency level
of the HTTP sessions (in this case, up to three).



=head1 SEE ALSO

=over

=item L<AnyEvent::FIFO>

The goal of L<AnyEvent::FIFO> is the same as that of L<Async::Queue>: to control concurrency level of asynchronous tasks.
The big difference is that L<AnyEvent::FIFO> is a queue of subroutines while L<Async::Queue> is a queue of tasks (data).
In L<Async::Queue>, worker subroutine is registered with the object in advance.
In L<AnyEvent::FIFO>, it is workers that are pushed to the queue.

You can emulate L<AnyEvent::FIFO> with L<Async::Queue> by pushing subroutine references to it as tasks.

=back


=head1 AUTHOR

Toshio Ito, C<< <debug.ito at gmail.com> >>

=head1 REPOSITORY

L<https://github.com/debug-ito/Async-Queue>

=head1 BUGS

Please report any bugs or feature requests to C<bug-async-queue at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Async-Queue>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Async::Queue


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Async-Queue>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Async-Queue>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Async-Queue>

=item * Search CPAN

L<http://search.cpan.org/dist/Async-Queue/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Async::Queue

package AnyEvent::Task;

use common::sense;

our $VERSION = '0.805';


1;


__END__

=encoding utf-8

=head1 NAME

AnyEvent::Task - Client/server-based asynchronous worker pool

=head1 SYNOPSIS 1: PASSWORD HASHING

=head2 Server

    use AnyEvent::Task::Server;
    use Authen::Passphrase::BlowfishCrypt;

    my $dev_urandom;
    my $server = AnyEvent::Task::Server->new(
                   name => 'passwd-hasher',
                   listen => ['unix/', '/tmp/anyevent-task.socket'],
                   setup => sub {
                     open($dev_urandom, "/dev/urandom") || die "open urandom: $!";
                   },
                   interface => {
                     hash => sub {
                       my ($plaintext) = @_;
                       read($dev_urandom, my $salt, 16) == 16 || die "bad read from urandom";
                       return Authen::Passphrase::BlowfishCrypt->new(cost => 10,
                                                                     salt => $salt,
                                                                     passphrase => $plaintext)
                                                               ->as_crypt;

                     },
                     verify => sub {
                       my ($crypted, $plaintext) = @_;
                       return Authen::Passphrase::BlowfishCrypt->from_crypt($crypted)
                                                               ->match($plaintext);
                     },
                   },
                 );

    $server->run; # or AE::cv->recv


=head2 Client

    use AnyEvent::Task::Client;

    my $client = AnyEvent::Task::Client->new(
                   connect => ['unix/', '/tmp/anyevent-task.socket'],
                 );

    my $checkout = $client->checkout( timeout => 5, );

    my $cv = AE::cv;

    $checkout->hash('secret',
      sub {
        my ($checkout, $crypted) = @_;

        print "Hashed password is $crypted\n";

        $checkout->verify($crypted, 'secret',
          sub {
            my ($checkout, $result) = @_;
            print "Verify result is $result\n";
            $cv->send;
          });
      });

    $cv->recv;

=head2 Output

    Hashed password is $2a$10$NwTOwxmTlG0Lk8YZMT29/uysC9RiZX4jtWCx.deBbb2evRjCq6ovi
    Verify result is 1




=head1 SYNOPSIS 2: DBI


=head2 Server

    use AnyEvent::Task::Server;
    use DBI;

    my $dbh;

    AnyEvent::Task::Server->new(
      name => 'dbi',
      listen => ['unix/', '/tmp/anyevent-task.socket'],
      setup => sub {
        $dbh = DBI->connect("dbi:SQLite:dbname=/tmp/junk.sqlite3","","",{ RaiseError => 1, });
      },
      interface => sub {
        my ($method, @args) = @_;
        $dbh->$method(@args);
      },
    )->run;

=head2 Client

    use AnyEvent::Task::Client;

    my $client = AnyEvent::Task::Client->new(
                   connect => ['unix/', '/tmp/anyevent-task.socket'],
                 );

    my $dbh = $client->checkout;

    my $cv = AE::cv;

    $dbh->do(q{ CREATE TABLE user(username TEXT PRIMARY KEY, email TEXT); },
      sub { });

    ## Requests will queue up on the checkout and execute in order:

    $dbh->do(q{ INSERT INTO user (username, email) VALUES (?, ?) },
             undef, 'jimmy',
                    'jimmy@example.com',
      sub { });

    $dbh->selectrow_hashref(q{ SELECT * FROM user }, sub {
      my ($dbh, $user) = @_;
      print "username: $user->{username}, email: $user->{email}\n";
      $cv->send;
    });

    $cv->recv;

=head2 Output

    username: jimmy, email: jimmy@example.com



=head1 DESCRIPTION

The synopses make this module look much more complicated than it actually is. In a nutshell, a synchronous worker process is forked off by a server whenever a client asks for one. The client keeps as many of these workers around as it wants and delegates tasks to them asynchronously. 

Another way of saying that is that L<AnyEvent::Task> is a pre-fork-on-demand server (L<AnyEvent::Task::Server>) combined with a persistent worker-pooled client (L<AnyEvent::Task::Client>).

The examples in the synopses are complete stand-alone programs. Run the server in one window and the client in another. The server will remain running but the client will exit after printing its output. Typically the "client" programs would be embedded in a server program such as a web-server.

Note that the client examples don't implement error checking (see the L<ERROR HANDLING> section).

A server is started with C<< AnyEvent::Task::Server->new >>. This constructor should be passed in at least the C<listen> and C<interface> arguments. Keep the returned server object around for as long as you want the server to be running. C<listen> is an array ref containing the host and service options to be passed to L<AnyEvent::Socket>'s C<tcp_server> function. C<interface> is the code that should handle each request. See the L<INTERFACE> section below for its specification. If a C<name> parameter is set, it will be used to set the process name so you can see which processes are which when you run C<ps>. A C<setup> coderef can be passed in to run some code after a new worker is forked. A C<checkout_done> coderef can be passed in to run some code whenever a checkout is released in order to perform any required clean-up.

A client is started with C<< AnyEvent::Task::Client->new >>. You only need to pass C<connect> to this constructor which is an array ref containing the host and service options to be passed to L<AnyEvent::Socket>'s C<tcp_connect>. Keep the returned client object around as long as you wish the client to be connected.

After the server and client are initialised, each process must enter AnyEvent's "main loop" in some way, possibly just C<< AE::cv->recv >>. The C<run> method on the server object is a convenient short-cut for this.

To acquire a worker process you call the C<checkout> method on the client object. The C<checkout> method doesn't need any arguments, but several optional ones such as C<timeout> are described below. As long as the checkout object is around, this checkout has exclusive access to the worker.

The checkout object is an object that proxies its method calls to a worker process or a function that does the same. The arguments to this method/function are the arguments you wish to send to the worker process followed by a callback to run when the operation completes. The callback will be passed two arguments: the original checkout object and the value returned by the worker process. The checkout object is passed into the callback as a convenience just in case you no longer have the original checkout available lexically.

In the event of an exception thrown by the worker process, a timeout, or some other unexpected condition, an error is raised in the dynamic context of the callback (see the L<ERROR HANDLING> section).




=head1 DESIGN

Both client and server are of course built with L<AnyEvent>. However, workers can't use AnyEvent (yet). I've never found a need to do event processing in the worker since if the library you wish to use is already AnyEvent-compatible you can simply use the library in the client process. If the client process is too over-loaded, it may make sense to run multiple client processes.

Each client maintains a "pool" of connections to worker processes. Every time a checkout is requested, the request is placed into a first-come, first-serve queue. Once a worker process becomes available, it is associated with that checkout until that checkout is garbage collected which in perl means as soon as it is no longer needed. Each checkout also maintains a queue of requested method-calls so that as soon as a worker process is allocated to a checkout, any queued method calls are filled in order.

C<timeout> can be passed as a keyword argument to C<checkout>. Once a request is queued up on that checkout, a timer of C<timout> seconds (default is 30, undef means infinity) is started. If the request completes during this timeframe, the timer is cancelled. If the timer expires, the worker connection is terminated and an exception is thrown in the dynamic context of the callback (see the L<ERROR HANDLING> section).

Note that since timeouts are associated with a checkout, checkouts can be created before the server is started. As long as the server is running within C<timeout> seconds, no error will be thrown and no requests will be lost. The client will continually try to acquire worker processes until a server is available, and once one is available it will attempt to allocate all queued checkouts.

Because of checkout queuing, the maximum number of worker processes a client will attempt to obtain can be limited with the C<max_workers> argument when creating a client object. If there are more live checkouts than C<max_workers>, the remaining checkouts will have to wait until one of the other workers becomes available. Because of timeouts, some checkouts may never be serviced if the system can't handle the load (the timeout error should be handled to indicate the service is temporarily unavailable).

The C<min_workers> argument determines how many "hot-standby" workers should be pre-forked when creating the client. The default is 2 though note that this may change to 0 in the future.





=head1 STARTING THE SERVER

Typically you will want to start the client and server as completely separate processes as shown in the synopses.

Running the server and the client in the same process is technically possible but is highly discouraged since the server will C<fork()> when the client demands a new worker process. In this case, all descriptors in use by the client are duped into the worker process and the worker ought to close these extra descriptors. Also, forking a busy client may be memory-inefficient (and dangerous if it uses threads).

Since it's more of a bother than it's worth to run the server and the client in the same process, there is an alternate server constructor, C<AnyEvent::Task::Server::fork_task_server> for when you'd like to fork a dedicated server process. It can be passed the same arguments as the regular C<new> constructor:

    ## my ($keepalive_pipe, $server_pid) =
    AnyEvent::Task::Server::fork_task_server(
      name => 'hello',
      listen => ['unix/', '/tmp/anyevent-task.socket'],
      interface => sub {
                         return "Hello from PID $$";
                       },
    );

The only differences between this and the regular constructor is that C<fork_task_server> will fork a process which becomes the server and will also install a "keep-alive" pipe between the server and the client. This keep-alive pipe will be used by the server to detect when its parent (the client process) exits.

If C<AnyEvent::Task::Server::fork_task_server> is called in a void context then the reference to this keep-alive pipe is pushed onto C<@AnyEvent::Task::Server::children_sockets>. Otherwise, the keep-alive pipe and the server's PID are returned. Closing the pipe will terminate the server gracefully. C<kill> the PID to terminate it immediately. Note that even when the server is shutdown, existing worker processes and checkouts may still be active in the client. The client object and all checkout objects should be destroyed if you wish to ensure all workers are shutdown.

Since the C<fork_task_server> constructor calls fork and requires using AnyEvent in both the parent and child processes, it is important that you not install any AnyEvent watchers before calling it. The usual caveats about forking AnyEvent processes apply (see the L<AnyEvent> docs).

You should also not call C<fork_task_server> after having started threads since, again, this function calls fork. Forking a threaded process is dangerous because the threads might have userspace data-structures in inconsistent states at the time of the fork.





=head1 INTERFACE

When creating a server, there are two possible formats for the C<interface> option. The first and most general is a coderef. This coderef will be passed the list of arguments that were sent when the checkout was called in the client process (without the trailing callback of course).

As described above, you can use a checkout object as a coderef or as an object with methods. If the checkout is invoked as an object, the method name is prepended to the arguments passed to C<interface>:

    interface => sub {
      my ($method, @args) = @_;
    },

If the checkout is invoked as a coderef, method is omitted:

    interface => sub {
      my (@args) = @_;
    },

The second format possible for C<interface> is a hash ref. This is a simple method dispatch feature where the method invoked on the checkout object is the key used to lookup which coderef to run in the worker:

    interface => {
      method1 => sub {
        my (@args) = @_;
      },
      method2 => sub {
        my (@args) = @_;
      },
    },

Note that since the protocol between the client and the worker process is currently JSON-based, all arguments and return values must be serializable to JSON. This includes most perl scalars like strings, a limited range of numerical types, and hash/list constructs with no cyclical references.

Because there isn't any way for the callback to indicate the context it desires, interface subs are always called in scalar context.

A future backwards compatible RPC protocol may use L<Sereal>. Although it's inefficient you can already serialise an object with Sereal manually, send the resulting string over the existing protocol, and then deserialise it in the worker.








=head1 LOGGING

Because workers run in a separate process, they can't directly use logging contexts in the client process. That is why this module is integrated with L<Log::Defer>.

A L<Log::Defer> object is created on demand in the worker process. Once the worker is done an operation, any messages in the object will be extracted and sent back to the client. The client then merges this into its main Log::Defer object that was passed in when creating the checkout.

In your server code, use L<AnyEvent::Task::Logger>. It exports the function C<logger> which returns a L<Log::Defer> object:

    use AnyEvent::Task::Server;
    use AnyEvent::Task::Logger;

    AnyEvent::Task::Server->new(
      name => 'sleeper',
      listen => ['unix/', '/tmp/anyevent-task.socket'],
      interface => sub {
        logger->info('about to compute some operation');
        {
          my $timer = logger->timer('computing some operation');
          select undef,undef,undef, 1; ## sleep for 1 second
        }
      },
    )->run;


Note: Portable server code should never call C<sleep> because on some systems it will interfere with the recoverable worker timeout feature implemented with C<SIGALRM>.


In your client code, pass a L<Log::Defer> object in when you create a checkout:

    use AnyEvent::Task::Client;
    use Log::Defer;

    my $client = AnyEvent::Task::Client->new(
                   connect => ['unix/', '/tmp/anyevent-task.socket'],
                 );

    my $log_defer_object = Log::Defer->new(sub {
                                             my $msg = shift;
                                             use Data::Dumper; ## or whatever
                                             print Dumper($msg);
                                           });

    $log_defer_object->info('going to compute some operation in a worker');

    my $checkout = $client->checkout(log_defer_object => $log_defer_object);

    my $cv = AE::cv;

    $checkout->(sub {
      $log_defer_object->info('finished some operation');
      $cv->send;
    });

    $cv->recv;


When run, the above client will print something like this:


    $VAR1 = {
          'start' => '1363232705.96839',
          'end' => '1.027309',
          'logs' => [
                      [
                        '0.000179',
                        30,
                        'going to compute some operation in a worker'
                      ],
                      [
                        '0.023881061050415',
                        30,
                        'about to compute some operation'
                      ],
                      [
                        '1.025965',
                        30,
                        'finished some operation'
                      ]
                    ],
          'timers' => {
                        'computing some operation' => [
                                                        '0.024089061050415',
                                                        '1.02470206105041'
                                                      ]
                      }
        };




=head1 ERROR HANDLING

In a synchronous program, if you expected some operation to throw an exception you might wrap it in C<eval> like this:

    my $crypted;

    eval {
      $crypted = hash('secret');
    };

    if ($@) {
      say "hash failed: $@";
    } else {
      say "hashed password is $crypted";
    }

But in an asynchronous program, typically C<hash> would initiate some kind of asynchronous operation and then return immediately, allowing the program to go about other tasks while waiting for the result. Since the error might come back at any time in the future, the program needs a way to map the exception that is thrown back to the original context.

AnyEvent::Task accomplishes this mapping with L<Callback::Frame>.

Callback::Frame lets you preserve error handlers (and C<local> variables) across asynchronous callbacks. Callback::Frame is not tied to AnyEvent::Task, AnyEvent or any other async framework and can be used with almost all callback-based libraries.

However, when using AnyEvent::Task, libraries that you use in the client must be L<AnyEvent> compatible. This restriction obviously does not apply to your server code, that being the main purpose of this module: accessing blocking resources from an asynchronous program. In your server code, when there is an error condition you should simply C<die> or C<croak> as in a synchronous program.

As an example usage of Callback::Frame, here is how we would handle errors thrown from a worker process running the C<hash> method in an asychronous client program:

    use Callback::Frame;

    frame(code => sub {

      $client->checkout->hash('secret', sub {
        my ($checkout, $crypted) = @_;
        say "Hashed password is $crypted";
      });

    }, catch => sub {

      my $back_trace = shift;
      say "Error is: $@";
      say "Full back-trace: $back_trace";

    })->(); ## <-- frame is created and then immediately executed

Of course if C<hash> is something like a bcrypt hash function it is unlikely to raise an exception so maybe that's a bad example. On the other hand, maybe it's a really good example: In addition to errors that occur while running your callbacks, L<AnyEvent::Task> uses L<Callback::Frame> to throw errors if the worker process times out, so if the bcrypt "cost" is really cranked up it might hit the default 30 second time limit.



=head2 Rationale for Callback::Frame

Why not just call the callback but set C<$@> and indicate an error has occurred? This is the approach taken with L<AnyEvent::DBI> for example. I believe the L<Callback::Frame> interface is superior to this method. In a synchronous program, exceptions are out-of-band messages and code doesn't need to locally handle them. It can let them "bubble up" the stack, perhaps to a top-level error handler. Invoking the callback when an error occurs forces exceptions to be handled in-band.

How about having AnyEvent::Task expose an error callback? This is the approach taken by L<AnyEvent::Handle> for example. I believe Callback::Frame is superior to this method also. Although separate callbacks are (sort of) out-of-band, you still have to write error handler callbacks and do something relevant locally instead of allowing the exception to bubble up to an error handler.

In servers, Callback::Frame helps you maintain the "dynamic state" (error handlers and dynamic variables) installed for a single connection. In other words, any errors that occur while servicing that connection will be able to be caught by an error handler specific to that connection. This lets you send an error response to the client and collect associated log messages in a L<Log::Defer> object specific to that connection.

Callback::Frame provides an error handler stack so you can have a top-level handler as well as nested handlers (similar to nested C<eval>s). This is useful when you wish to have a top-level "bail-out" error handler and also nested error handlers that know how to retry or recover from an error in an async sub-operation.

Callback::Frame is designed to be easily used with callback-based libraries that don't know about Callback::Frame. C<fub> is a shortcut for C<frame> with just the C<code> argument. Instead of passing C<sub { ... }> into libraries you can pass in C<fub { ... }>. When invoked, this wrapped callback will first re-establish any error handlers that you installed with C<frame> and then run your provided code. Libraries that force in-band error signalling can be handled with callbacks such as C<fub { die $@ if $@; ... }>. Separate error callbacks should simply be C<fub { die "failed becase ..." }>.

It's important that all callbacks be created with C<fub> (or C<frame>) even if you don't expect them to fail so that the dynamic context is preserved for nested callbacks that may. An exception is the callbacks provided to AnyEvent::Task checkouts: These are automatically wrapped in frames for you (although explicitly passing in fubs is fine too).

The L<Callback::Frame> documentation explains how this works in much more detail.



=head2 Reforking of workers after errors

If a worker throws an error, the client receives the error but the worker process stays running. As long as the client has a reference to the checkout (and as long as the exception wasn't "fatal" -- see below), it can still be used to communicate with that worker so you can access error states, rollback transactions, or do any sort of required clean-up.

However, once the checkout object is destroyed, by default the worker will be shutdown instead of returning to the client's worker pool as in the normal case where no errors were thrown. This is a "safe-by-default" behaviour that may help in the event that an exception thrown by a worker leaves the worker process in a broken/inconsistent state for some reason (for example a DBI connection died). This can be overridden by setting the C<dont_refork_after_error> option to C<1> in the client constructor. This will only matter if errors are being thrown frequently and your C<setup> routines take a long time (aside from the setup routine, creating new workers is quite fast since the server has already compiled all the application code and just has to fork).

There are cases where workers will never be returned to the worker pool: workers that have thrown fatal errors such as loss of worker connection or hung worker timeout errors. These errors are stored in the checkout and for as long as the checkout exists any methods on the checkout will immediately return the stored fatal error. Your client process can invoke this behaviour manually by calling the C<throw_fatal_error> method on a checkout object to cancel an operation and force-terminate a worker.

Another reason that a worker might not be returned to the worker pool is if it has been checked out C<max_checkouts> times. If C<max_checkouts> is specified as an argument to the Client constructor, then workers will be destroyed and reforked after being checked out this number of times. When not specified, workers are never re-forked for this reason. This parameter is useful for coping with libraries that leak memory or otherwise become slower/more resource-hungry over time.



=head1 COMPARISON WITH HTTP

Why a custom protocol, client, and server? Can't we just use something like HTTP?

It depends.

AnyEvent::Task clients send discrete messages and receive ordered replies from workers, much like HTTP. The AnyEvent::Task protocol can be extended in a backwards-compatible manner like HTTP. AnyEvent::Task communication can be pipelined and possibly in the future even compressed like HTTP.

The current AnyEvent::Task server obeys a very specific implementation policy: It is like a CGI server in that each process it forks is guaranteed to be handling only one connection at once so it can perform blocking operations without worrying about holding up other connections.

But since a single process can handle many requests in a row without exiting, they are more like persistent FastCGI processes. The difference however is that while a client holds a checkout it is guaranteed an exclusive lock on that process (useful for supporting DB transactions for example). With a FastCGI server it is assumed that requests are stateless so you can't necessarily be sure you'll get the same process for two consecutive requests. In fact, if an error is thrown in the FastCGI handler you may never get the same process back again, preventing you from being able to recover from the error, retry, or at least collect process state for logging reasons.

The fundamental difference between the AnyEvent::Task protocol and HTTP is that in AnyEvent::Task the client is the dominant protocol orchestrator whereas in HTTP it is the server.

In AnyEvent::Task, the client manages the worker pool and the client decides if/when worker processes should terminate. In the normal case, a client will just return the worker to its worker pool. A worker is supposed to accept commands for as long as possible until the client dismisses it.

The client decides the timeout for each checkout and different clients can have different timeouts while connecting to the same server.

Client processes can be started and checkouts can be obtained before the server is even started. The client will continue trying to connect to the server to obtain worker processes until either the server starts or the checkout's timeout period lapses. As well as freeing you from having to start your services in the "right" order, this also means servers can be restarted without throwing any errors (aka "zero-downtime restarts").

The client even decides how many minimum workers should be in the pool upon start-up and how many maximum workers to acquire before checkout creation requests are queued. The server is really just a dumb fork-on-demand server and most of the sophistication is in the asynchronous client.




=head1 SEE ALSO

L<The AnyEvent::Task github repo|https://github.com/hoytech/AnyEvent-Task>

In order to handle exceptions in a meaningful way with this module, you must use L<Callback::Frame>. In order to maintain seamless request logging across clients and workers, you should use L<Log::Defer>.

There are many modules on CPAN similar to L<AnyEvent::Task>.

This module is designed to be used in a non-blocking, process-based unix program. Depending on your exact requirements you might find something else useful: L<Parallel::ForkManager>, L<Thread::Pool>, or an HTTP server of some kind.

If you're into AnyEvent, L<AnyEvent::DBI> and L<AnyEvent::Worker> (based on AnyEvent::DBI), L<AnyEvent::ForkObject>, and L<AnyEvent::Fork::RPC> send and receive commands from worker processes similar to this module. L<AnyEvent::Worker::Pool> also has an implementation of a worker pool. L<AnyEvent::Gearman> can interface with Gearman services.

If you're into POE there is L<POE::Component::Pool::DBI>, L<POEx::WorkerPool>, L<POE::Component::ResourcePool>, L<POE::Component::PreforkDispatch>, L<Cantella::Worker>.



=head1 BUGS

Although this module's interface is now stable and has been in production use for some time, there are few remaining TODO items (see the bottom of Task.pm).




=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012-2017 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut




__END__




PROTOCOL

Normal request:
  client -> worker
    ['do', {META}, @ARGS]
         <-
    ['ok', {META}, $RESULT]
         OR
    ['er', {META}, $ERR_MSG]


Transaction done:
  client -> worker
    ['dn', {META}]







TODO

! max checkout queue size
  - start delivering fatal errors to some (at front of queue or back of queue though?)
  - write test for this

! docs: write good error handling examples

Make names more consistent between callback::frame backtraces and auto-generated log::defer timers

make server not use AnyEvent so don't have to worry about workers unlinking unix socket in dtors

In a graceful shutdown scenario, servers wait() on all their children before terminating.
  - Support relinquishing accept() socket during this period?

Document hung_worker_timeout and SIGALRM stuff

Wire protocol:
  - Support something other than JSON? Sereal?
  - Document the protocol?

need tests for the following features:
  - checkout_done signal sent to worker to issue rollback or whatever
  - recovering stuff off a worker after C<SIGALRM> timeout

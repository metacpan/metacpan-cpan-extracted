=head1 NAME

Coro::Multicore - make coro threads on multiple cores with specially supported modules

=head1 SYNOPSIS

 # when you DO control the main event loop, e.g. in the main program

 use Coro::Multicore; # enable by default

 Coro::Multicore::scoped_disable;
 AE::cv->recv; # or EV::run, AnyEvent::Loop::run, Event::loop, ...

 # when you DO NOT control the event loop, e.g. in a module on CPAN
 # do nothing (see HOW TO USE IT) or something like this:

 use Coro::Multicore (); # disable by default

 async {
    Coro::Multicore::scoped_enable;

    # blocking is safe in your own threads
    ...
 };

=head1 DESCRIPTION

While L<Coro> threads (unlike ithreads) provide real threads similar to
pthreads, python threads and so on, they do not run in parallel to each
other even on machines with multiple CPUs or multiple CPU cores.

This module lifts this restriction under two very specific but useful
conditions: firstly, the coro thread executes in XS code and does not
touch any perl data structures, and secondly, the XS code is specially
prepared to allow this.

This means that, when you call an XS function of a module prepared for it,
this XS function can execute in parallel to any other Coro threads. This
is useful for both CPU bound tasks (such as cryptography) as well as I/O
bound tasks (such as loading an image from disk). It can also be used
to do stuff in parallel via APIs that were not meant for this, such as
database accesses via DBI.

The mechanism to support this is easily added to existing modules
and is independent of L<Coro> or L<Coro::Multicore>, and therefore
could be used, without changes, with other, similar, modules, or even
the perl core, should it gain real thread support anytime soon. See
L<http://perlmulticore.schmorp.de/> for more info on how to prepare a
module to allow parallel execution. Preparing an existing module is easy,
doesn't add much overhead and no dependencies.

This module is an L<AnyEvent> user (and also, if not obvious, uses
L<Coro>).

=head1 HOW TO USE IT

Quick explanation: decide whether you control the main program/the event
loop and choose one of the two styles from the SYNOPSIS.

Longer explanation: There are two major modes this module can used in -
supported operations run asynchronously either by default, or only when
requested. The reason you might not want to enable this module for all
operations by default is compatibility with existing code:

Since this module integrates into an event loop and you must not normally
block and wait for something in an event loop callbacks. Now imagine
somebody patches your favourite module (e.g. Digest::MD5) to take
advantage of of the Perl Multicore API.

Then code that runs in an event loop callback and executes
Digest::MD5::md5 would work fine without C<Coro::Multicore> - it would
simply calculate the MD5 digest and block execution of anything else. But
with C<Coro::Multicore> enabled, the same operation would try to run other
threads. And when those wait for events, there is no event loop anymore,
as the event loop thread is busy doing the MD5 calculation, leading to a
deadlock.

=head2 USE IT IN THE MAIN PROGRAM

One way to avoid this is to not run perlmulticore enabled functions
in any callbacks. A simpler way to ensure it works is to disable
C<Coro::Multicore> thread switching in event loop callbacks, and enable it
everywhere else.

Therefore, if you control the event loop, as is usually the case when
you write I<program> and not a I<module>, then you can enable C<Coro::Multicore>
by default, and disable it in your event loop thread:

   # example 1, separate thread for event loop

   use EV;
   use Coro;
   use Coro::Multicore;

   async {
      Coro::Multicore::scoped_disable;
      EV::run;
   };

   # do something else

   # example 2, run event loop as main program

   use EV;
   use Coro;
   use Coro::Multicore;

   Coro::Multicore::scoped_disable;

   ... initialisation

   EV::run;

The latter form is usually better and more idiomatic - the main thread is
the best place to run the event loop.

Often you want to do some initialisation before running the event
loop. The most efficient way to do that is to put your intialisation code
(and main program) into its own thread and run the event loop in your main
program:

   use AnyEvent::Loop;
   use Coro::Multicore; # enable by default

   async {
      load_data;
      do_other_init;
      bind_socket;
      ...
   };

   Coro::Multicore::scoped_disable;
   AnyEvent::Loop::run;

This has the effect of running the event loop first, so the initialisation
code can block if it wants to.

If this is too cumbersome but you still want to make sure you can
call blocking functions before entering the event loop, you can keep
C<Coro::Multicore> disabled till you cna run the event loop:

   use AnyEvent::Loop;
   use Coro::Multicore (); # disable by default

   load_data;
   do_other_init;
   bind_socket;
   ...

   Coro::Multicore::scoped_disable; # disable for event loop
   Coro::Multicore::enable 1; # enable for the rest of the program
   AnyEvent::Loop::run;

=head2 USE IT IN A MODULE

When you I<do not> control the event loop, for example, because you want
to use this from a module you published on CPAN, then the previous method
doesn't work.

However, this is not normally a problem in practise - most modules only
do work at request of the caller. In that case, you might not care
whether it does block other threads or not, as this would be the callers
responsibility (or decision), and by extension, a decision for the main
program.

So unless you use XS and want your XS functions to run asynchronously,
you don't have to worry about C<Coro::Multicore> at all - if you
happen to call XS functions that are multicore-enabled and your
caller has configured things correctly, they will automatically run
asynchronously. Or in other words: nothing needs to be done at all, which
also means that this method works fine for existing pure-perl modules,
without having to change them at all.

Only if your module runs it's own L<Coro> threads could it be an
issue - maybe your module implements some kind of job pool and relies
on certain operations to run asynchronously. Then you can still use
C<Coro::Multicore> by not enabling it be default and only enabling it in
your own threads:

   use Coro;
   use Coro::Multicore (); # note the () to disable by default

   async {
      Coro::Multicore::scoped_enable;

      # do things asynchronously by calling perlmulticore-enabled functions
   };

=head2 EXPORTS

This module does not (at the moment) export any symbols. It does, however,
export "behaviour" - if you use the default import, then Coro::Multicore
will be enabled for all threads and all callers in the whole program:

   use Coro::Multicore;

In a module where you don't control what else might be loaded and run, you
might want to be more conservative, and not import anything. This has the
effect of not enabling the functionality by default, so you have to enable
it per scope:

   use Coro::Multicore ();

   sub myfunc {
      Coro::Multicore::scoped_enable;

      # from here to the end of this function, and in any functions
      # called from this function, tasks will be executed asynchronously.
   }

=head1 API FUNCTIONS

=over 4

=item $previous = Coro::Multicore::enable [$enable]

This function enables (if C<$enable> is true) or disables (if C<$enable>
is false) the multicore functionality globally. By default, it is enabled.

This can be used to effectively disable this module's functionality by
default, and enable it only for selected threads or scopes, by calling
C<Coro::Multicore::scoped_enable>.

Note that this setting nonly affects the I<global default> - it will not
reflect whether multicore functionality is enabled for the current thread.

The function returns the previous value of the enable flag.

=item Coro::Multicore::scoped_enable

This function instructs Coro::Multicore to handle all requests executed
in the current coro thread, from the call to the end of the current scope.

Calls to C<scoped_enable> and C<scoped_disable> don't nest very well at
the moment, so don't nest them.

=item Coro::Multicore::scoped_disable

The opposite of C<Coro::Multicore::scope_disable>: instructs Coro::Multicore to
I<not> handle the next multicore-enabled request.

=back

=cut

package Coro::Multicore;

use Coro ();

BEGIN {
   our $VERSION = '1.06';

   use XSLoader;
   XSLoader::load __PACKAGE__, $VERSION;
}


sub import {
   if (@_ > 1) {
      require Carp;
      Carp::croak ("Coro::Multicore does not export any symbols");
   }

   enable 1;
}

our $WATCHER;

# called when first thread is started, on first release. can
# be called manually, but is not currently a public interface.
sub init {
   require AnyEvent; # maybe load it unconditionally?
   $WATCHER ||= AE::io (fd, 0, \&poll);
}

=head1 THREAD SAFETY OF SUPPORTING XS MODULES

Just because an XS module supports perlmulticore might not immediately
make it reentrant. For example, while you can (try to) call C<execute>
on the same database handle for the patched C<DBD::mysql> (see the
L<registry|http://perlmulticore.schmorp.de/registry>), this will almost
certainly not work, despite C<DBD::mysql> and C<libmysqlclient> being
thread safe and reentrant - just not on the same database handle.

Many modules have limitations such as these - some can only be called
concurrently from a single thread as they use global variables, some
can only be called concurrently on different I<handles> (e.g. database
connections for DBD modules, or digest objects for Digest modules),
and some can be called at any time (such as the C<md5> function in
C<Digest::MD5>).

Generally, you only have to be careful with the very few modules that use
global variables or rely on C libraries that aren't thread-safe, which
should be documented clearly in the module documentation.

Most modules are either perfectly reentrant, or at least reentrant as long
as you give every thread it's own I<handle> object.

=head1 EXCEPTIONS AND THREAD CANCELLATION

L<Coro> allows you to cancel threads even when they execute within an XS
function (C<cancel> vs. C<cancel> methods). Similarly, L<Coro> allows you
to send exceptions (e.g. via the C<throw> method) to threads executing
inside an XS function.

While doing this is questionable and dangerous with normal Coro threads
already, they are both supported in this module, although with potentially
unwanted effects. The following describes the current implementation and
is subject to change. It is described primarily so you can understand what
went wrong, if things go wrong.

=over 4

=item EXCEPTIONS

When a thread that has currently released the perl interpreter (e.g.
because it is executing a perlmulticore enabled XS function) receives an exception, it will
at first continue normally.

After acquiring the perl interpreter again, it will throw the
exception it previously received. More specifically, when a thread
calls C<perlinterp_acquire ()> and has received an exception, then
C<perlinterp_acquire ()> will not return but instead C<die>.

Most code that has been updated for perlmulticore support will not expect
this, and might leave internal state corrupted to some extent.

=item CANCELLATION

Unsafe cancellation on a thread that has released the perl interpreter
frees its resources, but let's the XS code continue at first. This should
not lead to corruption on the perl level, as the code isn't allowed to
touch perl data structures until it reacquires the interpreter.

The call to C<perlinterp_acquire ()> will then block indefinitely, leaking
the (OS level) thread.

Safe cancellation will simply fail in this case, so is still "safe" to
call.

=back

=head1 INTERACTION WITH OTHER SOFTWARE

This module is very similar to other environments where perl interpreters
are moved between threads, such as mod_perl2, and the same caveats apply.

I want to spell out the most important ones:

=over 4

=item pthreads usage

Any creation of pthreads make it impossible to fork portably from a
perl program, as forking from within a threaded program will leave the
program in a state similar to a signal handler. While it might work on
some platforms (as an extension), this might also result in silent data
corruption. It also seems to work most of the time, so it's hard to test
for this.

I recommend using something like L<AnyEvent::Fork>, which can create
subprocesses safely (via L<Proc::FastSpawn>).

Similar issues exist for signal handlers, although this module works hard
to keep safe perl signals safe.

=item module support

This module moves the same perl interpreter between different
threads. Some modules might get confused by that (although this can
usually be considered a bug). This is a rare case though.

=item event loop reliance

To be able to wake up programs waiting for results, this module relies on
an active event loop (via L<AnyEvent>). This is used to notify the perl
interpreter when the asynchronous task is done.

Since event loops typically fail to work properly after a fork, this means
that some operations that were formerly working will now hang after fork.

A workaround is to call C<Coro::Multicore::enable 0> after a fork to
disable the module.

Future versions of this module might do this automatically.

=back

=head1 BUGS

=over 4

=item (OS-) threads are never released

At the moment, threads that were created once will never be freed. They
will be reused for asynchronous requests, though, so as long as you limit
the maximum number of concurrent asynchronous tasks, this will also limit
the maximum number of threads created.

The idle threads are not necessarily using a lot of resources: on
GNU/Linux + glibc, each thread takes about 8KiB of userspace memory +
whatever the kernel needs (probably less than 8KiB).

Future versions will likely lift this limitation.

=item AnyEvent is initalised at module load time

AnyEvent is initialised on module load, as opposed to at a later time.

Future versions will likely change this.

=back

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/AnyEvent-XSThreadPool.html

Additional thanks to Zsbán Ambrus, who gave considerable desing input for
this module and the perl multicore specification.

=cut

1


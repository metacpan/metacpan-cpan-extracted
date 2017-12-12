# NAME

AnyEvent::Filesys::Notify - An AnyEvent compatible module to monitor files/directories for changes

# VERSION

version 1.23

# STATUS

<div>
    <img src="https://travis-ci.org/mvgrimes/AnyEvent-Filesys-Notify.svg?branch=master" alt="Build Status">
    <a href="https://metacpan.org/pod/AnyEvent::Filesys::Notify"><img alt="CPAN version" src="https://badge.fury.io/pl/AnyEvent-Filesys-Notify.svg" /></a>
</div>

# SYNOPSIS

    use AnyEvent::Filesys::Notify;

    my $notifier = AnyEvent::Filesys::Notify->new(
        dirs     => [ qw( this_dir that_dir ) ],
        interval => 2.0,             # Optional depending on underlying watcher
        filter   => sub { shift !~ /\.(swp|tmp)$/ },
        cb       => sub {
            my (@events) = @_;
            # ... process @events ...
        },
        parse_events => 1,  # Improves efficiency on certain platforms
    );

    # enter an event loop, see AnyEvent documentation
    Event::loop();

# DESCRIPTION

This module provides a cross platform interface to monitor files and
directories within an [AnyEvent](https://metacpan.org/pod/AnyEvent) event loop. The heavy lifting is done by
[Linux::INotify2](https://metacpan.org/pod/Linux::INotify2) or [Mac::FSEvents](https://metacpan.org/pod/Mac::FSEvents) on their respective O/S. A fallback
which scans the directories at regular intervals is include for other systems.
See ["WATCHER IMPLEMENTATIONS"](#watcher-implementations) for more on the backends.

Events are passed to the callback (specified as a CodeRef to `cb` in the
constructor) in the form of [AnyEvent::Filesys::Notify::Event](https://metacpan.org/pod/AnyEvent::Filesys::Notify::Event)s.

# METHODS

## new()

A constructor for a new AnyEvent watcher that will monitor the files in the
given directories and execute a callback when a modification is detected. 
No action is take until a event loop is entered.

Arguments for new are:

- dirs 

        dirs => [ '/var/log', '/etc' ],

    An ArrayRef of directories to watch. Required.

- interval

        interval => 1.5,   # seconds

    Specifies the time in fractional seconds between file system checks for
    the [AnyEvent::Filesys::Notify::Role::Fallback](https://metacpan.org/pod/AnyEvent::Filesys::Notify::Role::Fallback) implementation.

    Specifies the latency for [Mac::FSEvents](https://metacpan.org/pod/Mac::FSEvents) for the
    `AnyEvent::Filesys::Notify::Role::FSEvents` implementation.

    Ignored for the `AnyEvent::Filesys::Notify::Role::Inotify2` implementation.

- filter

        filter => qr/\.(ya?ml|co?nf|jso?n)$/,
        filter => sub { shift !~ /\.(swp|tmp)$/,

    A CodeRef or Regexp which is used to filter wanted/unwanted events. If this
    is a Regexp, we attempt to match the absolute path name and filter out any
    that do not match. If a CodeRef, the absolute path name is passed as the
    only argument and the event is fired only if there sub returns a true value.

- cb

        cb  => sub { my @events = @_; ... },

    A CodeRef that is called when a modification to the monitored directory(ies) is
    detected. The callback is passed a list of
    [AnyEvent::Filesys::Notify::Event](https://metacpan.org/pod/AnyEvent::Filesys::Notify::Event)s. Required.

- backend

        backend => 'Fallback',
        backend => 'KQueue',
        backend => '+My::Filesys::Notify::Role::Backend',

    Force the use of the specified backend. The backend is assumed to have the
    `AnyEvent::Filesys::Notify::Role` prefix, but you can force a fully qualified
    name by prefixing it with a plus. Optional.

- no\_external

        no_external => 1,

    This is retained for backward compatibility. Using `backend =` 'Fallback'>
    is preferred. Force the use of the ["Fallback"](#fallback) watcher implementation. This is
    not encouraged as the ["Fallback"](#fallback) implement is very inefficient, but it does
    not require either [Linux::INotify2](https://metacpan.org/pod/Linux::INotify2) nor [Mac::FSEvents](https://metacpan.org/pod/Mac::FSEvents). Optional.

- parse\_events

        parse_events => 1,

    In backends that support it (currently INotify2), parse the events instead of
    rescanning file system for changed `stat()` information. Note, that this might
    cause slight changes in behavior. In particular, the Inotify2 backend will
    generate an additional 'modified' event when a file changes (once when opened
    for write, and once when modified).

- skip\_subdirs

        skip_subdirs => 1,

    Skips subdirectories and anything in them while building a list of files/dirs
    to watch. Optional.

# WATCHER IMPLEMENTATIONS

## INotify2 (Linux)

Uses [Linux::INotify2](https://metacpan.org/pod/Linux::INotify2) to monitor directories. Sets up an `AnyEvent->io`
watcher to monitor the `$inotify->fileno` filehandle.

## FSEvents (Mac)

Uses [Mac::FSEvents](https://metacpan.org/pod/Mac::FSEvents) to monitor directories. Sets up an `AnyEvent->io`
watcher to monitor the `$fsevent->watch` filehandle.

## KQueue (BSD/Mac)

Uses [IO::KQueue](https://metacpan.org/pod/IO::KQueue) to monitor directories. Sets up an `AnyEvent->io`
watcher to monitor the `IO::KQueue` object.

**WARNING** - [IO::KQueue](https://metacpan.org/pod/IO::KQueue) and the `kqueue()` system call require an open
filehandle for every directory and file that is being watched. This makes
it impossible to watch large directory structures (and inefficient to watch
moderately sized directories). The use of the KQueue backend is discouraged.

## Fallback

A simple scan of the watched directories at regular intervals. Sets up an
`AnyEvent->timer` watcher which is executed every `interval` seconds
(or fractions thereof). `interval` can be specified in the constructor to
[AnyEvent::Filesys::Notify](https://metacpan.org/pod/AnyEvent::Filesys::Notify) and defaults to 2.0 seconds.

This is a very inefficient implementation. Use one of the others if possible.

# Why Another Module For File System Notifications

At the time of writing there were several very nice modules that accomplish
the task of watching files or directories and providing notifications about
changes. Two of which offer a unified interface that work on any system:
[Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple) and [File::ChangeNotify](https://metacpan.org/pod/File::ChangeNotify).

[AnyEvent::Filesys::Notify](https://metacpan.org/pod/AnyEvent::Filesys::Notify) exists because I need a way to simply tie the
functionality those modules provide into an event framework. Neither of the
existing modules seem to work with well with an event loop.
[Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple) does not supply a non-blocking interface and
[File::ChangeNotify](https://metacpan.org/pod/File::ChangeNotify) requires you to poll an method for new events. You could
fork off a process to run [Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple) and use an event handler
to watch for notices from that child, or setup a timer to check
[File::ChangeNotify](https://metacpan.org/pod/File::ChangeNotify) at regular intervals, but both of those approaches seem
inefficient or overly complex. Particularly, since the underlying watcher
implementations ([Mac::FSEvents](https://metacpan.org/pod/Mac::FSEvents) and [Linux::INotify2](https://metacpan.org/pod/Linux::INotify2)) provide a filehandle
that you can use and IO event to watch.

This is not slight against the authors of those modules. Both are well 
respected, are certainly finer coders than I am, and built modules which 
are perfect for many situations. If one of their modules will work for you
by all means use it, but if you are already using an event loop, this
module may fit the bill.

# SEE ALSO

Modules used to implement this module [AnyEvent](https://metacpan.org/pod/AnyEvent), [Mac::FSEvents](https://metacpan.org/pod/Mac::FSEvents),
[Linux::INotify2](https://metacpan.org/pod/Linux::INotify2), [Moose](https://metacpan.org/pod/Moose).

Alternatives to this module [Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple), [File::ChangeNotify](https://metacpan.org/pod/File::ChangeNotify).

# AUTHOR

Mark Grimes, <mgrimes@cpan.org>

# CONTRIBUTORS

- Gasol Wu <gasol.wu@gmail.com> who contributed the BSD support for IO::KQueue
- Dave Hayes <dave@jetcafe.org>
- Carsten Wolff <carsten@wolffcarsten.de>
- Ettore Di Giacinto (@mudler)
- Martin Barth (@ufobat)

# SOURCE

Source repository is at [https://github.com/mvgrimes/AnyEvent-Filesys-Notify](https://github.com/mvgrimes/AnyEvent-Filesys-Notify).

# BUGS

Please report any bugs or feature requests on the bugtracker website [http://github.com/mvgrimes/AnyEvent-Filesys-Notify/issues](http://github.com/mvgrimes/AnyEvent-Filesys-Notify/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mark Grimes, <mgrimes@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

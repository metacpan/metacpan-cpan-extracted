package Cocoa::EventLoop;
use strict;
use XSLoader;

our $VERSION = '0.04';

BEGIN {
    XSLoader::load __PACKAGE__, $VERSION;
}

sub timer {
    my ($class, %arg) = @_;

    my $cb    = $arg{cb};
    my $ival  = $arg{interval} || 0;
    my $after = $arg{after} || 0;

    my $timer = bless {}, 'Cocoa::EventLoop::timer';
    __add_timer($timer, $after, $ival, $cb);

    $timer;
}

sub Cocoa::EventLoop::timer::DESTROY {
    __remove_timer($_[0]);
}

my %IO = ();
sub io {
    my ($class, %arg) = @_;

    my $fd = fileno($arg{fh});
    defined $fd or $fd = $arg{fh};

    my $mode = $arg{poll} eq 'r' ? 0 : 1;
    my $io   = $IO{$fd} ? $IO{$fd}[2] : bless({});

    __add_io($io, $fd, $mode, $arg{cb});

    if ($IO{$fd}) {
        $IO{$fd}[$mode]++;
    }
    else {
        $IO{$fd} = [$mode == 0, $mode == 1, $io];
    }

    bless [$mode, $io, $fd], 'Cocoa::EventLoop::io';
}

sub Cocoa::EventLoop::io::DESTROY {
    my ($mode, $io, $fd) = @{ $_[0] };

    if (--$IO{$fd}[$mode] == 0) {
        my $fd = __remove_io($io, $mode);
        delete $IO{$fd} if $fd;
    }
}

1;

__END__

=for stopwords io AnyEvent NSRunLoop cb fh

=head1 NAME

Cocoa::EventLoop - perl interface for Cocoa event loop.

=head1 SYNOPSIS

    use Cocoa::EventLoop;
    
    # on-shot timer
    my $timer = Cocoa::EventLoop->timer(
        after => 10,
        cb    => sub {
            # do something
        },
    );
    
    # repeatable timer
    my $timer = Cocoa::EventLoop->timer(
        after    => 10,
        interval => 10,
        cb       => sub {
            # do something
        },
    );
    
    # stop or cancel timers
    undef $timer;
    
    
    # I/O Watcher
    my $io = Cocoa::EventLoop->io(
        fh   => *STDIN,
        poll => 'r',
        cb   => sub {
            warn 'read: ', <STDIN>;
        },
    );
    
    
    # run main loop
    Cocoa::EventLoop->run;
    
    # run main loop for specified period.
    Cocoa::EventLoop->run_while($secs);


=head1 DESCRIPTION

This module provides perl interface for Cocoa's event loop, NSRunLoop. And also provides some timers and io watchers within the loop.

If you want to use or write some modules that depends Cocoa event loop, using this module is easiest way.
For example, L<Cocoa::Growl> is possible to handle click event when it runs with this module:

    use Cocoa::EventLoop;
    use Cocoa::Growl;
    
    my $done = 0;
    growl_notify(
        name        => 'Notification Name',
        title       => 'Hello',
        description => 'Cocoa World!',
        on_click    => sub {
            $done++;
        },
        on_timeout => sub {
            $done++;
        },
    );
    
    Cocoa::EventLoop->run_while(0.1) while !$done;

If you write more complicated script, consider using L<AnyEvent::Impl::NSRunLoop> instead of using this module directly.
L<AnyEvent::Impl::NSRunLoop> is a wrapper for L<Cocoa::EventLoop> and L<AnyEvent>.
If you use L<AnyEvent::Impl::NSRunLoop>, you can use any AnyEvent based modules in Cocoa's event loop.

=head1 CLASS METHODS

=head2 Cocoa::EventLoop->timer(%parameters)

    $timer = Cocoa::EventLoop->timer(after => <seconds>, cb => <callback>);
    
    $timer = Cocoa::EventLoop->timer(
        after    => <fractional_seconds>,
        interval => <fractional_seconds>,
        cb       => <callback>,
    );

Create one-shot or repeat timer.

Available parameters are:

=over 4

=item * after => 'Number'

How many seconds (fractional values are supported) the callback should be invoked.
When this value does not specified, use 0 by default.

=item * interval => 'Number'

Callback will be invoked regularly at this interval (in fractional seconds) after the first invocation.
If this value does not specified, use 0 by default (== act as non repeat, on-shot timer);

=item * cb => 'CodeRef'

Callbacks that will be invoked when timer is fire. This parameter is required.

=back

=head2 Cocoa::EventLoop->io(%parameters)

    $io = Cocoa::EventLoop->io(
        fh   => <filehandle_or_fileno>,
        poll => <"r" or "w">,
        cb   => <callback>,
    );

Create I/O watcher. Available parameters are:

=over 4

=item * fh => 'FileHandle' or fileno

Perl file handle (or a naked file descriptor) to watch for events. (Required)

=item * poll => 'r' or 'w'

Type for watching event. 'r' is for readable, 'w' is for writable. (Required)

=item * cb => 'CodeRef'

callback to invoke each time the file handle becomes ready. (Required)

=back

=head2 Cocoa::EventLoop->run

Start Cocoa main loop.

This method exits immediately when no input sources or timers are attached to the loop,
but Mac OS X can install and remove additional input sources as needed, and those sources could therefore prevent the run loop from exiting.

If you want the run loop to terminate, you shouldn't use this method. Instead, use one of the other run methods and also check other arbitrary conditions of your own, in a loop. A simple example would be:

    my $should_keep_running = 0; # global
    Cocoa::EventLoop->run_while(0.1) while $should_keep_running;

=head2 Cocoa::EventLoop->run_while($secs)

Run Cocoa main loop only while specified seconds.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

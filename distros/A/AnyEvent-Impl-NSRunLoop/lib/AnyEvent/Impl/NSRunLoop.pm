package AnyEvent::Impl::NSRunLoop;
use strict;
use warnings;

use AnyEvent;
use Cocoa::EventLoop;

our $VERSION = '0.04';

BEGIN {
    push @AnyEvent::REGISTRY, [AnyEvent::Impl::NSRunLoop:: => AnyEvent::Impl::NSRunLoop::];
}

sub io {
    my ($class, %arg) = @_;
    Cocoa::EventLoop->io(%arg);
}

sub timer {
    my ($class, %arg) = @_;
    Cocoa::EventLoop->timer(%arg);
}

sub loop {
    Cocoa::EventLoop->run;
}

sub one_event {
    # this actually is not one event, but it's unable to handle it correctly at Cocoa 
    Cocoa::EventLoop->run_while(0.1);
}

1;

__END__

=for stopwords API AnyEvent NSRunLoop github

=head1 NAME

AnyEvent::Impl::NSRunLoop - AnyEvent adaptor for Cocoa NSRunLoop

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Impl::NSRunLoop;
    
    # do something

=head1 DESCRIPTION

This module provides NSRunLoop support to AnyEvent.

NSRunLoop is an event loop for Cocoa application. 
By using this module, you can use Cocoa based API in your AnyEvent application.

For example, using this module with L<Cocoa::Growl>, you can handle growl click event.

    my $cv = AnyEvent->condvar;
    
    # show growl notification
    growl_notify(
        name        => 'Notification Test',
        title       => 'Hello!',
        description => 'Growl world!',
        on_click    => sub {
            warn 'clicked!';
            $cv->send;
        },
    );
    
    $cv->recv;

Please look at L<Cocoa::Growl> documentation for more detail.

=head1 NOTICE

This module is in early development phase.
The implementation is not completed and alpha quality. See also skipped test cases in test directory.

Patches and suggestions are always welcome, let me know by email or on github :)

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

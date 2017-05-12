package AnyEvent::Net::Curl::Queued::Multi;
# ABSTRACT: Net::Curl::Multi wrapped by Moo


use strict;
use utf8;
use warnings qw(all);

use AnyEvent;
use Carp qw(confess);
use Moo;
use MooX::Types::MooseLike::Base qw(
    AnyOf
    ArrayRef
    HashRef
    Int
    Num
    Object
    Ref
);
use Net::Curl::Multi;
use Scalar::Util qw(set_prototype);

# kill Net::Curl::Mulii prototypes as they wreck around/before/after method modifiers
set_prototype \&Net::Curl::Multi::new           => undef;
set_prototype \&Net::Curl::Multi::socket_action => undef;
set_prototype \&Net::Curl::Multi::add_handle    => undef;

extends 'Net::Curl::Multi';


has active      => (is => 'ro', isa => Int, default => sub { -1 }, writer => 'set_active');


has pool        => (is => 'ro', isa => HashRef[Ref], default => sub { {} });


has timer       => (is => 'ro', isa => AnyOf[ArrayRef, Object], writer => 'set_timer', clearer => 'clear_timer', predicate => 'has_timer', weak_ref => 0);


has max         => (is => 'ro', isa => Num, default => sub { 4 });


has timeout     => (is => 'ro', isa => Num, default => sub { 60.0 });

our $VERSION = '0.047'; # VERSION


sub BUILD {
    my ($self) = @_;

    $self->setopt(Net::Curl::Multi::CURLMOPT_MAXCONNECTS        => $self->max << 2);
    $self->setopt(Net::Curl::Multi::CURLMOPT_SOCKETFUNCTION     => \&_cb_socket);
    $self->setopt(Net::Curl::Multi::CURLMOPT_TIMERFUNCTION      => \&_cb_timer);

    return;
}

## no critic (RequireArgUnpacking)
sub BUILDARGS { return $_[-1] }

# socket callback: will be called by curl any time events on some
# socket must be updated
sub _cb_socket {
    my ($self, undef, $socket, $poll) = @_;

    # Right now $socket belongs to that $easy, but it can be
    # shared with another easy handle if server supports persistent
    # connections.
    # This is why we register socket events inside multi object
    # and not $easy.

    # AnyEvent does not support registering a socket for both
    # reading and writing. This is rarely used so there is no
    # harm in separating the events.

    my $keep = 0;

    # register read event
    if ($poll & Net::Curl::Multi::CURL_POLL_IN) {
        $self->pool->{"r$socket"} = AE::io $socket, 0, sub {
            $self->socket_action($socket, Net::Curl::Multi::CURL_CSELECT_IN);
        };
        ++$keep;
    }

    # register write event
    if ($poll & Net::Curl::Multi::CURL_POLL_OUT) {
        $self->pool->{"w$socket"} = AE::io $socket, 1, sub {
            $self->socket_action($socket, Net::Curl::Multi::CURL_CSELECT_OUT);
        };
        ++$keep;
    }

    # deregister old io events
    unless ($keep) {
        delete $self->pool->{"r$socket"};
        delete $self->pool->{"w$socket"};
    }

    return 0;
}

# timer callback: It triggers timeout update. Timeout value tells
# us how soon socket_action must be called if there were no actions
# on sockets. This will allow curl to trigger timeout events.
sub _cb_timer {
    my ($self, $timeout_ms) = @_;

    # deregister old timer
    $self->clear_timer;

    my $cb = sub {
        $self->socket_action(Net::Curl::Multi::CURL_SOCKET_TIMEOUT)
            #if $self->handles > 0;
    };

    if ($timeout_ms < 0) {
        # Negative timeout means there is no timeout at all.
        # Normally happens if there are no handles anymore.
        #
        # However, curl_multi_timeout(3) says:
        #
        # Note: if libcurl returns a -1 timeout here, it just means
        # that libcurl currently has no stored timeout value. You
        # must not wait too long (more than a few seconds perhaps)
        # before you call curl_multi_perform() again.

        $self->set_timer(AE::timer 1, 1, $cb);
    } elsif ($timeout_ms < 10) {
        # Short timeouts are just... Weird!
    } else {
        # This will trigger timeouts if there are any.
        $self->set_timer(AE::timer $timeout_ms / 1000, 0, $cb);
    }

    return 0;
}


around socket_action => sub {
    my $orig = shift;
    my $self = shift;

    my $active = $orig->($self => @_);

    my $i = 0;
    while (my (undef, $easy, $result) = $self->info_read) {
        $self->remove_handle($easy);
        $easy->_finish($result);
    } continue {
        ++$i;
    }

    return $self->set_active($active - $i);
};


around add_handle => sub {
    my $orig = shift;
    my $self = shift;
    my $easy = shift;

    my $r = $orig->($self => $easy);

    # Calling socket_action with default arguments will trigger
    # socket callback and register IO events.
    #
    # It _must_ be called _after_ add_handle(); AE will take care
    # of that.
    #
    # We are delaying the call because in some cases socket_action
    # may finish immediately (i.e. there was some error or we used
    # persistent connections and server returned data right away)
    # and it could confuse our application -- it would appear to
    # have finished before it started.
    AE::postpone {
        $self->socket_action;
    };

    return $r;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Net::Curl::Queued::Multi - Net::Curl::Multi wrapped by Moo

=head1 VERSION

version 0.047

=head1 SYNOPSIS

    use AnyEvent::Net::Curl::Queued::Multi;

    my $multi = AnyEvent::Net::Curl::Queued::Multi->new({
        max     => 10,
        timeout => 30,
    });

=head1 WARNING: GONE MOO!

This module isn't using L<Any::Moose> anymore due to the announced deprecation status of that module.
The switch to the L<Moo> is known to break modules that do C<extend 'AnyEvent::Net::Curl::Queued::Easy'> / C<extend 'YADA::Worker'>!
To keep the compatibility, make sure that you are using L<MooseX::NonMoose>:

    package YourSubclassingModule;
    use Moose;
    use MooseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or L<MouseX::NonMoose>:

    package YourSubclassingModule;
    use Mouse;
    use MouseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or the L<Any::Moose> equivalent:

    package YourSubclassingModule;
    use Any::Moose;
    use Any::Moose qw(X::NonMoose);
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

However, the recommended approach is to switch your subclassing module to L<Moo> altogether (you can use L<MooX::late> to smoothen the transition):

    package YourSubclassingModule;
    use Moo;
    use MooX::late;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

=head1 DESCRIPTION

This module extends the L<Net::Curl::Multi> class through L<Moo> and adds L<AnyEvent> handlers.

=head1 ATTRIBUTES

=head2 active

Currently active sockets.

=head2 pool

Sockets pool.

=head2 timer

L<AnyEvent> C<timer()> handler.

=head2 max

Maximum parallel connections limit (default: 4).

=head2 timeout

Timeout threshold, in seconds (default: 10).

=head1 METHODS

=head2 socket_action(...)

Wrapper around the C<socket_action()> from L<Net::Curl::Multi>.

=head2 add_handle(...)

Overrides the C<add_handle()> from L<Net::Curl::Multi>.
Add one handle and kickstart download.

=for Pod::Coverage BUILD
BUILDARGS
has_timer

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent>

=item *

L<AnyEvent::Net::Curl::Queued>

=item *

L<Moo>

=item *

L<Net::Curl::Multi>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package AnyEvent::Handle::ZeroMQ;

use 5.006;
use strict;
use warnings;

=head1 NAME

AnyEvent::Handle::ZeroMQ - Integrate AnyEvent and ZeroMQ with AnyEvent::Handle like ways.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

    use AnyEvent::Handle::ZeroMQ;
    use AE;
    use ZeroMQ;

    my $ctx = ZeroMQ::Context->new;
    my $socket = $ctx->socket(ZMQ_XREP);
    $socket->bind('tcp://0:8888');

    my $hdl = AnyEvent::Handle::ZeroMQ->new(
	socket => $socket,
	on_drain => sub { print "the write queue is empty\n" },
	on_error => sub { my($error_msg) = @_; ... },
	    # catch errors when occured in the reading callback
    );
    # or $hdl->on_drain( sub { ... } );
    # or $hdl->on_error( sub { ... } );
    $hdl->push_read( sub {
	my($hdl, $data) = @_;

	my @out;
	while( defined( my $msg = shift @$data ) ) {
	    push @out, $msg;
	    last if $msg->size == 0;
	}
	while( my $msg = shift @$data ) {
	    print "get: ",$msg->data,$/;
	}
	push @out, "get!";
	$hdl->push_write(\@out);
    } );

    AE::cv->recv;

=cut

use strict;
use warnings;

use AE;
use ZeroMQ qw(:all);
use Scalar::Util qw(weaken);

use base qw(Exporter);
our %EXPORT_TAGS = ( constant => [qw(SOCKET RQUEUE WQUEUE RWATCHER WWATCHER ON_DRAIN DEALER ROUTER)] );
our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

use constant {
    SOCKET => 0,
    RQUEUE => 1,
    WQUEUE => 2,
    WATCHER => 3,
    ON_DRAIN => 4,
    DEALER => 5,
    ROUTER => 6,
    ON_ERROR => 7,
};

=head1 METHODS

=head2 new( socket => $zmq_socket, on_drain(optional) => cb(hdl) )

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $socket = $args{socket};

    my $fd = $socket->getsockopt(ZMQ_FD);

    my($self, $wself);

    $self = $wself = bless [
	$socket,
	[],
	[],
	AE::io($fd, 0, sub { _consume_read_write($wself) }),
	undef,
    ], $class;

    weaken $wself;

    if( exists $args{on_drain} ) {
	on_drain($self, $args{on_drain});
    }
    if( exists $args{on_error} ) {
	on_error($self, $args{on_error});
    }

    return $self;
}

sub _consume_read_write {
    _consume_write(@_);
    _consume_read(@_);
}

=head2 push_read( cb(hdl, data (array_ref) ) )

=cut

sub _consume_read {
    my $self = shift;

    my $socket = $self->[SOCKET];
    my $rqueue = $self->[RQUEUE];

    while( $socket->getsockopt(ZMQ_EVENTS) & ZMQ_POLLIN && @$rqueue ) {
	my @msgs;
	{
	    push @msgs, $socket->recv;
	    redo if $socket->getsockopt(ZMQ_RCVMORE);
	}
	my $cb = shift @$rqueue;
	eval { $cb->($self, \@msgs) };
	if( $@ ) {
	    if( $self->[ON_ERROR] ) {
		$self->[ON_ERROR]($@);
	    }
	    else {
		warn $@;
	    }
	}
    }
}

sub push_read {
    my $self = shift;
    push @{$self->[RQUEUE]}, pop;
    _consume_read($self);
}

=head2 push_write( data (array_ref) )

=cut

sub _consume_write {
    my $self = shift;

    my $socket = $self->[SOCKET];
    my $wqueue = $self->[WQUEUE];

    my $write_something;
    while( $socket->getsockopt(ZMQ_EVENTS) & ZMQ_POLLOUT && @$wqueue ) {
	my $msgs = shift @$wqueue;
	while( defined( my $msg = shift @$msgs ) ) {
	    $socket->send($msg, @$msgs ? ZMQ_SNDMORE : 0);
	}

	$write_something = 1;
    }

    $self->[ON_DRAIN]($self) if( !@$wqueue && $write_something && $self->[ON_DRAIN] );
}

sub push_write {
    my $self = shift;
    push @{$self->[WQUEUE]}, shift;
    _consume_write($self);
}

if( !exists(&ZeroMQ::Socket::DESTROY) ) {
    *ZeroMQ::Socket::DESTROY = sub {
	my $self = shift;
	eval { $self->close };
    };
}

=head2 old_cb = on_drain( cb(hdl) )

=cut

sub on_drain {
    my $self = shift;
    my $cb = pop;

    $cb->($self) if( $cb && !@{$self->[WQUEUE]} );

    my $old_cb = $self->[ON_DRAIN];
    $self->[ON_DRAIN] = $cb;

    return $old_cb;
}

=head2 old_cb = on_error( cb(hdl) )

=cut

sub on_error {
    my $self = shift;
    my $cb = pop;

    my $old_cb = $self->[ON_ERROR];
    $self->[ON_ERROR] = $cb;

    return $old_cb;
}

=head1 DIFFERENCES

There is also a module called L<AnyEvent::ZeroMQ> in CPAN.

AnyEvent::ZeroMQ::* is a huge, heavy,
and full-functioned framework, but this module is a simple,
lightweight library with less dependency, and runs faster.

So this module is only occupy a smaller namespace
under AnyEvent::Handle::

This module and AnyEvent::ZeroMQ::* are not replacable to each other.

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-handle-zeromq at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-Handle-ZeroMQ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::Handle::ZeroMQ


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-Handle-ZeroMQ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-Handle-ZeroMQ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-Handle-ZeroMQ>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-Handle-ZeroMQ/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of AnyEvent::Handle::ZeroMQ

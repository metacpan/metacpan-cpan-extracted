package AnyEvent::Handle::ZeroMQ::Dealer;

use 5.006;
use strict;
use warnings;

use AnyEvent::Handle::ZeroMQ qw(:constant);
use base qw(AnyEvent::Handle::ZeroMQ);

our $VERSION = $AnyEvent::Handle::ZeroMQ::Version;

=head1 NAME

AnyEvent::Handle::ZeroMQ::Dealer - use AnyEvent::Handle::ZeroMQ as concurrent request-reply pattern

=head1 SYNOPSIS

    use AnyEvent::Handle::ZeroMQ::Dealer;
    use AE;
    use ZeroMQ;

    my $ctx = ZeroMQ::Context->new;
    my $socket = $ctx->socket(ZMQ_XREQ);
    $socket->bind('tcp://0:8888');

    my $hdl = AnyEvent::Handle::ZeroMQ::Dealer->new(
	socket => $socket,
	on_drain => sub { print "the write queue is empty\n" },
    );
    # or $hdl->on_drain( sub { ... } );
    my @request = ...;
    $hdl->push_write( \@request, sub {
	my($hdl, $reply) = @_;
	...
    } );

    AE::cv->recv;

=cut

use constant {
    SLOT => 0,
};

=head1 METHODS

=head2 new( socket => ..., on_drain => ... )

Get an AnyEvent::Handle::ZeroMQ::Dealer instance

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->[DEALER] = [];
    $self->[DEALER][SLOT] = [];
    return $self;
}

sub _dealer_read_cb {
    my($self, $msgs) = @_;

    my $n = unpack 'V', shift(@$msgs)->data;

    my $cb = delete $self->[DEALER][SLOT][$n];
    if( !$cb ) {
	$self->SUPER::push_read(\&_dealer_read_cb);
	return;
    }

    0 while( @$msgs && shift(@$msgs)->size );
    $cb->($self, $msgs);
}

=head2 push_write( request_data(array_ref), cb(hdl, reply_data(array_ref) )

=cut

sub push_write {
    my($self, $msgs, $cb) = @_;

    my $n = 0;
    ++$n while $self->[DEALER][SLOT][$n];
    $self->[DEALER][SLOT][$n] = $cb;

    unshift @$msgs, pack('V', $n), '';

    $self->SUPER::push_write($msgs);
    $self->SUPER::push_read(\&_dealer_read_cb);
}

=head2 push_read

Don't use this.

=cut

sub push_read {
    use Carp;
    warn __PACKAGE__."::push_read shouldn't be called.";
}

1;

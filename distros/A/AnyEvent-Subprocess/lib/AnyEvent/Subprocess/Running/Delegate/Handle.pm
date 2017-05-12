package AnyEvent::Subprocess::Running::Delegate::Handle;
BEGIN {
  $AnyEvent::Subprocess::Running::Delegate::Handle::VERSION = '1.102912';
}
# ABSTRACT: Running part of the Handle delegate
use AnyEvent::Subprocess::Handle;
use AnyEvent::Subprocess::Done::Delegate::Handle;

use MooseX::Types::Moose qw(Str);
use AnyEvent::Subprocess::Types qw(Direction);
use namespace::autoclean;

use Moose;
with 'AnyEvent::Subprocess::Running::Delegate';

has 'direction' => (
    is            => 'ro',
    isa           => Direction,
    required      => 1,
    documentation => 'r when parent reads a pipe, w when parent writes to a pipe, rw for a socket',
);

has 'handle' => (
    is       => 'ro',
    isa      => 'AnyEvent::Subprocess::Handle',
    required => 1,
);

has 'want_leftovers' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

sub build_events {
    my ($self, $running) = @_;

    if( $self->direction eq 'r' ){
        return $self->name;
    }

    return;
}

sub build_done_delegates {
    my $self = shift;
    my $h = $self->handle;
    my $want = $self->want_leftovers ? 1 : undef;
    my ($rbuf, $wbuf) = map { $want && delete $h->{$_} } qw/rbuf wbuf/;

    return AnyEvent::Subprocess::Done::Delegate::Handle->new(
        name => $self->name,
        (defined $rbuf ? (rbuf => $rbuf) : ()),
        (defined $wbuf ? (wbuf => $wbuf) : ()),
    );
}

sub completion_hook {}

sub BUILD {
    my ($self) = @_;

    # todo: we should check "rw" also, but there is not a good way to
    # do this
    if($self->direction eq 'r'){
        $self->handle->on_finalize(
            $self->event_sender_for($self->name),
        );
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

AnyEvent::Subprocess::Running::Delegate::Handle - Running part of the Handle delegate

=head1 VERSION

version 1.102912

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


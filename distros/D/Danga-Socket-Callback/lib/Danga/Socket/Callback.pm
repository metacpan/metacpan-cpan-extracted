package Danga::Socket::Callback;
use strict;
use warnings;
use base qw(Danga::Socket);
use fields qw(on_read_ready on_write_ready on_error on_signal_hup context);

our $VERSION = '0.013';

sub new
{
    my Danga::Socket::Callback $self = shift;
    my %args = @_;
    $self = fields::new($self) unless ref $self;
    $self->SUPER::new($args{handle});

    foreach my $field (qw(on_read_ready on_write_ready on_error on_signal_hup context)) {
        $self->{$field} = $args{$field} if $args{$field}
    }

    if ($self->{on_read_ready}) {
        $self->watch_read(1);
    }

    if ($self->{on_write_ready}) {
        $self->watch_write(1);
    }

    return $self;
}

sub event_read
{
    my Danga::Socket::Callback $self = shift;
    if (my $code = $self->{on_read_ready}) {
        return $code->($self);
    }
}

sub event_write
{
    my Danga::Socket::Callback $self = shift;
    if (my $code = $self->{on_write_ready}) {
        return $code->($self);
    } else {
        $self->SUPER::event_write();
    }
}

sub event_hup
{
    my Danga::Socket::Callback $self = shift;
    if (my $code = $self->{on_signal_hup}) {
        return $code->($self);
    }
}

sub event_err
{
    my Danga::Socket::Callback $self = shift;
    if (my $code = $self->{on_error}) {
        $code->($self);
    }
}

1;

__END__

=head1 NAME

Danga::Socket::Callback - Use Danga::Socket From Callbacks

=head1 SYNOPSIS 

  my $danga = Danga::Socket::Callback->new(
    handle         => $socket,
    context        => { ... },
    on_read_ready  => sub { ... },
    on_write_ready => sub { ... },
    on_error       => sub { ... },
    on_signal_hup  => sub { ... },
  );

  Danga::Socket->EventLoop();

=head1 DESCRIPTION

Love the fact that Perlbal, Mogilefs, and friends all run fast because of
Danga::Socket, but despise it because you need to subclass it every time?
Well, here's a module for all you lazy people.

Danga::Socket::Callback is a thin wrapper arond Danga::Socket that allows
you to set callbacks to be called at various events. This allows you to
define multiple Danga::Socket-based sockets without defining multiple
classes:

  my $first = Danga::Socket::Callback->new(
    hadle => $sock1,
    on_read_ready => \&sub1
  );

  my $second = Danga::Socket::Callback->new(
    hadle => $sock2,
    on_read_ready => \&sub2
  );

  Danga::Socket->EventLoop();

=head1 METHODS

=head2 new

Creates a new instance of Danga::Socket::Callback. Takes the following
parameters:

=over 4

=item handle

The socket/handle to read from.

=item context

Arbitrary data to be shared between your app and Danga::Socket::Callback.

=item on_read_ready

Specify the code reference to be fired when the socket is ready to be read

=item on_write_ready

Specify the code reference to be fired when the socket is ready to be written

=item on_error

Specify te code reference to be fired when there was an error

=item on_signal_hup

Specify the code reference to be fired when a HUP signal is received.

=back

=head2 event_read

=head2 event_write

=head2 event_err

=head2 event_hup

Implements each method available from Danga::Socket. If the corresponding
callbacks are available, then calls the callback. Each callback receives
the Danga::Socket::Callback object.

For event_write, if no callback is available, then the default event_write
method from Danga::Socket is called.

=head1 BUGS

Possibly. I don't claim to use 100% of Danga::Socket. If you find any,
please report them (preferrably with a failing test case)

=head1 AUTHOR

Copyright (c) Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

use utf8;
use strict;
use warnings;

package AnyEvent::Tools::Buffer;
use AnyEvent::AggressiveIdle qw(aggressive_idle stop_aggressive_idle);
use AnyEvent::Util;
use Carp;

sub new
{
    my $class = shift;
    croak "usage: buffer(on_flush => sub { ... }, ...)" if @_ % 2;


    my (%opts) = @_;

    my $self = bless {
        queue       => [],
        exists      => {},
        timer       => undef,
        lock        => 0,
        do_flush    => 0,
        unique_cb   => undef,
    } => ref($class) || $class;

    $self->on_flush($opts{on_flush});
    $self->size($opts{size} || 0);
    $self->interval($opts{interval} || 0);
    $self->unique_cb($opts{unique_cb});

    return $self;
}

sub interval
{
    my ($self, $ival) = @_;
    return $self->{interval} if @_ == 1;
    undef $self->{timer} unless $ival;
    return $self->{interval} = $ival;
}

sub on_flush
{
    my ($self, $cb) = @_;
    croak "callback must be CODEREF" if $cb and 'CODE' ne ref $cb;
    return $self->{on_flush} = $cb;
}

sub unique_cb
{
    my ($self, $cb) = @_;

    # disable unique checking
    unless($cb) {
        $self->{exists} = {};
        return $self->{unique_cb} = $cb;
    }

    croak "unique_cb must be CODEREF" unless 'CODE' eq ref $cb;
    $self->flush;
    return $self->{unique_cb} = $cb;
}

sub push :method
{
    my ($self, @data) = @_;
    if (@data) {
        if ($self->{unique_cb}) {
            while(@data) {
                my $add = shift @data;
                my $key = $self->{unique_cb}->($add);
                croak "unique_cb must return defined SCALAR"
                    if ref $key or !defined($key);
                next if exists $self->{exists}{$key};
                $self->{exists}{$key} = 1;
                push @{ $self->{queue} }, $add;
            }
        } else {
            push @{ $self->{queue} }, @data;
        }
    }

    $self->_check_buffer;
    return;
}

sub unshift :method
{
    my ($self, @data) = @_;
    if (@data) {
        if ($self->{unique_cb}) {
            while(@data) {
                my $add = pop @data;
                my $key = $self->{unique_cb}->($add);
                croak "unique_cb must return defined SCALAR"
                    if ref $key or !defined($key);
                next if exists $self->{exists}{$key};
                $_++ for values %{ $self->{exists} };
                $self->{exists}{$key} = 1;
                unshift @{ $self->{queue} }, $add;
            }
        } else {
            unshift @{ $self->{queue} }, @data;
        }
    }

    $self->_check_buffer;
    return;
}

sub unshift_back
{
    my ($self, $data) = @_;
    croak "Guard has already been destroyed" unless $self->{lock};
    unless ($self->{unique_cb}) {
        unshift @{ $self->{queue} }, @$data;
        return;
    }

    my @buffer;
    $self->{exists} = {};
    for (@$data, @{ $self->{queue} }) {
        my $key = $self->{unique_cb}->($_);
        next if exists $self->{exists}{$key};
        $self->{exists}{$key} = 1;
        push @buffer, $_;
    }
    $self->{queue} = \@buffer;
    return;
}


sub size
{
    my ($self, $value) = @_;
    return $self->{size} if @_ == 1;
    $self->{size} = $value;
    $self->_check_buffer;
    return $self->{size};
}


sub flush
{
    my ($self) = @_;
    return unless @{ $self->{queue} };
    return unless $self->{on_flush};
    if ($self->{lock}) {
        $self->{do_flush} = 1;
        return;
    }
    undef $self->{timer};
    my $queue = $self->{queue};
    $self->{queue} = [];
    $self->{exists} = {};
    my $guard = guard sub {

        return unless $self;  # it can be destroyed

        $self->{lock} = 0;

        if ($self->{do_flush}) {
            $self->{do_flush} = 0;
            return unless @{ $self->{queue} };
            aggressive_idle sub { # avoid recursion
                stop_aggressive_idle $_[0];
                $self->flush if $self;
            };
            return;
        }
        return unless $self;
        return unless @{ $self->{queue} };
        aggressive_idle sub { # avoid recursion
            stop_aggressive_idle $_[0];
            $self->_check_buffer if $self; # can be destroyed again
        };
        return;
    };
    $self->{lock} = 1;
    $self->{on_flush}->($guard, $queue);
    return;
}


sub _check_buffer
{
    my ($self) = @_;

    return if $self->{lock};
    return unless $self->{on_flush};

    unless (@{ $self->{queue} }) {
        undef $self->{timer};
        return;
    }

    if ($self->size) {
        if (@{ $self->{queue} } >= $self->size) {
            $self->flush;
            return;
        }
    }

    return if $self->{timer};
    return unless $self->interval;
    $self->{timer} = AE::timer $self->interval, 0 => sub { $self->flush };
    return;
}

1;

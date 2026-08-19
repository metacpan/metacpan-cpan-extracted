package DBIx::Loop::Loop::Mojo;

use 5.008003;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.06';

# The loop adapter for Mojo::IOLoop, implementing the DBIx::Loop seam
# (add_reader / add_writer / remove / timer / new_future / await) over the
# Mojo reactor. to_native() bridges a DBIx::Loop::Future to a Mojo::Promise.

sub new {
    my ($class, %opt) = @_;
    require Mojo::IOLoop;
    my $loop = $opt{loop} || Mojo::IOLoop->singleton;
    return bless { loop => $loop, fh => {} }, $class;
}

sub loop { $_[0]{loop} }

# watch a raw fd (owned by C): dup it so the reactor can hold a handle;
# remove() closes only our dup, never C's fd.
sub _fh {
    my ($self, $fd, $mode) = @_;
    open my $fh, $mode, $fd or Carp::croak("DBIx::Loop: fdopen($fd): $!");
    return $fh;
}

sub add_reader {
    my ($self, $fd, $cb) = @_;
    my $e = $self->{fh}{$fd} ||= { fh => $self->_fh($fd, '<&'), r => 0, w => 0 };
    $e->{r} = 1;
    my $reactor = $self->{loop}->reactor;
    $reactor->io($e->{fh} => sub {
        my (undef, $writable) = @_;
        $writable ? ($e->{wcb} && $e->{wcb}->()) : ($e->{rcb} && $e->{rcb}->());
    }) unless $e->{registered}++;
    $e->{rcb} = $cb;
    $reactor->watch($e->{fh}, $e->{r}, $e->{w});
}

sub add_writer {
    my ($self, $fd, $cb) = @_;
    my $e = $self->{fh}{$fd} ||= { fh => $self->_fh($fd, '>&'), r => 0, w => 0 };
    $e->{w} = 1;
    my $reactor = $self->{loop}->reactor;
    $reactor->io($e->{fh} => sub {
        my (undef, $writable) = @_;
        $writable ? ($e->{wcb} && $e->{wcb}->()) : ($e->{rcb} && $e->{rcb}->());
    }) unless $e->{registered}++;
    $e->{wcb} = $cb;
    $reactor->watch($e->{fh}, $e->{r}, $e->{w});
}

sub remove {
    my ($self, $fd) = @_;
    my $e = delete $self->{fh}{$fd} or return;
    $self->{loop}->reactor->remove($e->{fh});
    close $e->{fh};
    return;
}

sub timer {
    my ($self, $after, $cb) = @_;
    return $self->{loop}->timer($after => $cb);
}

# ecosystem-native pending future for this loop
sub new_future {
    require Mojo::Promise;
    return Mojo::Promise->new;
}

# bridge a DBIx::Loop::Future to a Mojo::Promise
sub to_native {
    my ($self, $future) = @_;
    require Mojo::Promise;
    my $p = Mojo::Promise->new;
    $future->on_ready(sub {
        my ($f) = @_;
        $f->is_done ? $p->resolve($f->get) : $p->reject($f->failure);
    });
    return $p;
}

# run the loop until $future (a DBIx::Loop::Future) is ready
sub await {
    my ($self, $future) = @_;
    $self->{loop}->one_tick until $future->is_ready;
    return $future;
}

1;

__END__

=head1 NAME

DBIx::Loop::Loop::Mojo - drive DBIx::Loop on Mojo::IOLoop

=head1 SYNOPSIS

    use DBIx::Loop;
    use DBIx::Loop::Loop::Mojo;

    my $adapter = DBIx::Loop::Loop::Mojo->new;   # or (loop => $io_loop)
    my $db = DBIx::Loop->connect($dsn, $u, $p, \%attr, loop => $adapter);

    # future style
    my $f = $db->query("SELECT ...");
    $adapter->await($f);

    # promise style
    $adapter->to_native($db->query("SELECT ..."))->then(sub { ... })->wait;

=head1 DESCRIPTION

The loop adapter for L<Mojo::IOLoop>. Implements the DBIx::Loop loop seam over
the Mojo reactor; C<to_native> bridges a query future to a L<Mojo::Promise>
for promise-style chaining. See L<DBIx::Loop>.

Needs a Mojolicious that ships L<Mojo::Promise> (7.54, mid-2018, or
later) - an older install has the reactor but not the promise, and this
adapter needs both.

=head1 AUTHOR

LNATION <email@lnation.org>

=cut

package DBIx::Loop::Loop::AnyEvent;

use 5.008003;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.05';

# The loop adapter for AnyEvent, implementing the DBIx::Loop seam over AE io
# and timer watchers. AnyEvent has no native future, so queries stay
# DBIx::Loop::Future; to_native() bridges one to an AnyEvent condvar. Through
# AnyEvent this also covers EV, Event, etc. via its own backends.

sub new {
    my ($class, %opt) = @_;
    require AnyEvent;
    return bless { r => {}, w => {}, t => {} }, $class;
}

sub add_reader {
    my ($self, $fd, $cb) = @_;
    $self->{r}{$fd} = AnyEvent->io(fh => $fd, poll => 'r', cb => $cb);
}

sub add_writer {
    my ($self, $fd, $cb) = @_;
    $self->{w}{$fd} = AnyEvent->io(fh => $fd, poll => 'w', cb => $cb);
}

sub remove {
    my ($self, $fd) = @_;
    delete $self->{r}{$fd};
    delete $self->{w}{$fd};
    return;
}

sub timer {
    my ($self, $after, $cb) = @_;
    my $id;
    $id = "t" . ++$self->{tid};
    $self->{t}{$id} = AnyEvent->timer(after => $after, cb => sub {
        delete $self->{t}{$id};
        $cb->();
    });
    return $id;
}

# AnyEvent has no ecosystem future; the canonical one is ours
sub new_future {
    require DBIx::Loop;
    return DBIx::Loop::Future->new;
}

# bridge a DBIx::Loop::Future to an AnyEvent condvar
sub to_native {
    my ($self, $future) = @_;
    require AnyEvent;
    my $cv = AnyEvent->condvar;
    $future->on_ready(sub {
        my ($f) = @_;
        $f->is_done ? $cv->send($f->get) : $cv->croak($f->failure);
    });
    return $cv;
}

# block (running the AE loop) until $future is ready
sub await {
    my ($self, $future) = @_;
    return $future if $future->is_ready;
    require AnyEvent;
    my $cv = AnyEvent->condvar;
    $future->on_ready(sub { $cv->send });
    $cv->recv;
    return $future;
}

1;

__END__

=head1 NAME

DBIx::Loop::Loop::AnyEvent - drive DBIx::Loop on AnyEvent

=head1 SYNOPSIS

    use DBIx::Loop;
    use DBIx::Loop::Loop::AnyEvent;

    my $adapter = DBIx::Loop::Loop::AnyEvent->new;
    my $db = DBIx::Loop->connect($dsn, $u, $p, \%attr, loop => $adapter);

    my $f = $db->query("SELECT ...");
    $adapter->await($f);                  # or:
    my @res = $adapter->to_native($f)->recv;   # condvar style

=head1 DESCRIPTION

The loop adapter for L<AnyEvent> (and, through AnyEvent's own backends, EV,
Event and friends). Implements the DBIx::Loop loop seam with AE C<io>/C<timer>
watchers; C<to_native> bridges a query future to an AnyEvent condvar. See
L<DBIx::Loop>.

=head1 AUTHOR

LNATION <email@lnation.org>

=cut

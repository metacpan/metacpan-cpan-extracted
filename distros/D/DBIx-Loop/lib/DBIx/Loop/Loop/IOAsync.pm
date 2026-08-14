package DBIx::Loop::Loop::IOAsync;

use 5.008003;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.03';

# A loop adapter over IO::Async::Loop, implementing the DBIx::Loop seam:
# add_reader / add_writer / remove / timer / new_future / await. The backends
# only ever call these five-plus-await methods; this is the whole coupling to
# IO::Async. (Phase 05 adds Mojo / AnyEvent / Hyperman adapters against the
# same seam, plus a conformance suite.)

sub new {
    my ($class, %opt) = @_;
    my $loop = $opt{loop};
    if (!$loop) {
        require IO::Async::Loop;
        $loop = IO::Async::Loop->new;
    }
    return bless { loop => $loop, fh => {} }, $class;
}

sub loop { $_[0]{loop} }

# watch a raw fd (owned by C) for readiness. We dup it into a Perl filehandle
# so IO::Async can watch it; remove() closes only our dup, never C's fd.
sub _fh {
    my ($self, $fd, $mode) = @_;
    open my $fh, $mode, $fd or Carp::croak("DBIx::Loop: fdopen($fd): $!");
    return $fh;
}

sub add_reader {
    my ($self, $fd, $cb) = @_;
    my $fh = $self->{fh}{$fd} ||= $self->_fh($fd, '<&');
    $self->{loop}->watch_io(handle => $fh, on_read_ready => $cb);
}

sub add_writer {
    my ($self, $fd, $cb) = @_;
    my $fh = $self->{fh}{$fd} ||= $self->_fh($fd, '>&');
    $self->{loop}->watch_io(handle => $fh, on_write_ready => $cb);
}

sub remove {
    my ($self, $fd) = @_;
    my $fh = delete $self->{fh}{$fd} or return;
    $self->{loop}->unwatch_io(
        handle => $fh, on_read_ready => 1, on_write_ready => 1);
    close $fh;
    return;
}

sub timer {
    my ($self, $after, $cb) = @_;
    return $self->{loop}->watch_time(after => $after, code => $cb);
}

# A pending future of this ecosystem's native class.
#
# IO::Async before 0.805 stores the loop by poking $future->{loop}, and Future
# 0.50+ no longer implements a Future as a hashref - so on that pairing (which
# a smoker will happily assemble: IO::Async 0.801 with a current Future)
# $loop->new_future dies "Not a HASH reference" before it returns anything.
# That is IO::Async's business, not ours, but it is not worth dying over: fall
# back to a plain Future, which is the same class from the caller's side and
# differs only in not carrying its own ->await (we await on the loop anyway).
sub _native_future {
    my ($self) = @_;
    my $f = eval { $self->{loop}->new_future };
    return $f if $f;
    require Future;
    return Future->new;
}

# native future for this ecosystem (IO::Async's own); the phase-2 pool uses the
# canonical DBIx::Loop::Future directly and does not call this yet.
sub new_future { $_[0]->_native_future }

# bridge a DBIx::Loop::Future to an IO::Async Future
sub to_native {
    my ($self, $future) = @_;
    my $nf = $self->_native_future;
    $future->on_ready(sub {
        my ($f) = @_;
        $f->is_done ? $nf->done($f->get) : $nf->fail($f->failure);
    });
    return $nf;
}

# run the loop until $future is ready (for a blocking ->get in tests / scripts)
sub await {
    my ($self, $future) = @_;
    $self->{loop}->loop_once until $future->is_ready;
    return $future;
}

1;

__END__

=head1 NAME

DBIx::Loop::Loop::IOAsync - drive DBIx::Loop on an IO::Async event loop

=head1 SYNOPSIS

    use IO::Async::Loop;
    use DBIx::Loop;
    use DBIx::Loop::Loop::IOAsync;

    my $adapter = DBIx::Loop::Loop::IOAsync->new;   # or (loop => $existing)
    my $db = DBIx::Loop->connect($dsn, $u, $p, \%attr, loop => $adapter);

    my $f = $db->query("SELECT ...");
    $adapter->await($f);           # run the loop until ready
    my $res = ($f->get)[0];

=head1 DESCRIPTION

The loop adapter for L<IO::Async>. It implements the DBIx::Loop loop seam
(C<add_reader>, C<add_writer>, C<remove>, C<timer>, C<new_future>) plus
C<await> for synchronous use. See L<DBIx::Loop>.

C<new_future> and C<to_native> hand back an L<IO::Async::Future>, except on
IO::Async before 0.805 running against L<Future> 0.50 or newer: those
IO::Async versions construct theirs by poking C<< $f->{loop} >>, which a
Future of that vintage is not, and C<< $loop->new_future >> dies. There the
adapter returns a plain L<Future> instead - the same class to the caller,
without its own C<await>, which costs nothing here because awaiting is the
adapter's job.

=head1 AUTHOR

LNATION <email@lnation.org>

=cut

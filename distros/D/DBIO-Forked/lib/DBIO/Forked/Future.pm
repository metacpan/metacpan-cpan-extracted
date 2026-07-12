package DBIO::Forked::Future;
# ABSTRACT: Loop-free, pipe-backed Future for DBIO::Forked

use strict;
use warnings;

use Carp 'croak';
use Errno ();
use IO::Select;
use Scalar::Util ();
use Storable ();
use namespace::clean;


# A future is in one of two modes:
#   leaf    -- backed by a forked child: { read_fh, pid, buffer }. A leaf built
#              already-resolved (done/fail) has no child: read_fh/pid undef,
#              ready+reaped set.
#   derived -- lazy over a source future: { source, on_done, on_fail }
# Both share the resolution slots { ready, failed, result, reaped }.
# On success, result is an arrayref of the resolved values; on failure it is
# the error scalar.


sub new {
  my ($class, %args) = @_;
  return bless {
    mode    => 'leaf',
    read_fh => $args{read_fh},
    pid     => $args{pid},
    buffer  => '',
    ready   => 0,
    failed  => 0,
    result  => undef,
    reaped  => 0,
  }, $class;
}

# Internal constructor for a derived (then/catch) future.
sub _derived {
  my ($class, $source, $on_done, $on_fail) = @_;
  return bless {
    mode    => 'derived',
    source  => $source,
    on_done => $on_done,
    on_fail => $on_fail,
    ready   => 0,
    failed  => 0,
    result  => undef,
    reaped  => 1,   # a derived future owns no child
  }, $class;
}

# --- Immediately-settled constructors (Test::Future-compatible surface) ---
#
# done/fail/needs_all are CLASS methods. Core's ResultSet async helpers build
# futures via $storage->future_class->done(@rows) / ->fail($err), so this class
# must answer them as a class, not just an instance. A settled future is just a
# pre-resolved leaf with no child, so _resolve short-circuits on {ready} and the
# existing get/is_ready/is_failed work unchanged.
sub _settled {
  my ($class, $failed, $result) = @_;
  return bless {
    mode    => 'leaf',
    read_fh => undef,
    pid     => undef,
    buffer  => '',
    ready   => 1,
    failed  => $failed,
    result  => $result,
    reaped  => 1,
  }, $class;
}


sub done {
  my $class = shift;
  return $class->_settled(0, [ @_ ]);
}


sub fail {
  my ($class, $error) = @_;
  return $class->_settled(1, $error);
}


sub needs_all {
  my $class = shift;
  my @results;
  for my $f (@_) {
    my @r = eval { $f->get };
    if (my $err = $@) {
      return $class->fail($err);
    }
    push @results, @r;
  }
  return $class->done(@results);
}


sub then {
  my ($self, $on_done, $on_fail) = @_;
  return ref($self)->_derived($self, $on_done, $on_fail);
}


sub catch {
  my ($self, $on_fail) = @_;
  return ref($self)->_derived($self, undef, $on_fail);
}


sub and_then {
  my ($self, $cb) = @_;
  return $self->then($cb);
}


sub get {
  my $self = shift;
  $self->_resolve(1);
  croak $self->{result} if $self->{failed};
  my @r = @{ $self->{result} || [] };
  return wantarray ? @r : $r[0];
}


sub is_ready {
  my $self = shift;
  return $self->_resolve(0) ? 1 : 0;
}


sub is_failed {
  my $self = shift;
  return 0 unless $self->_resolve(0);
  return $self->{failed} ? 1 : 0;
}

# --- Resolution machinery ---

# Try to resolve. With $blocking true, block until resolved and return true;
# with $blocking false, do as much as can be done without blocking and return
# whether the future is now resolved.
sub _resolve {
  my ($self, $blocking) = @_;
  return 1 if $self->{ready};
  return $self->{mode} eq 'derived'
    ? $self->_resolve_derived($blocking)
    : $self->_resolve_leaf($blocking);
}

# Drain the pipe. Non-blocking: read what is available, accumulate, return 0
# until EOF. Blocking: read until EOF. On EOF, thaw + reap + cache.
sub _resolve_leaf {
  my ($self, $blocking) = @_;
  my $fh = $self->{read_fh};
  croak 'DBIO::Forked::Future: no read handle to resolve' unless defined $fh;
  my $sel = $self->{_select} ||= IO::Select->new($fh);

  while (1) {
    if (!$blocking) {
      return 0 unless $sel->can_read(0);
    }
    my $n = sysread($fh, my $chunk, 65536);
    if (!defined $n) {
      next if $!{EINTR};   # interrupted by a signal -- retry
      croak "DBIO::Forked::Future: read error: $!";
    }
    if ($n == 0) {         # EOF: the child closed its write end
      $self->_finish_leaf;
      return 1;
    }
    $self->{buffer} .= $chunk;
  }
}

sub _finish_leaf {
  my $self = shift;

  my $blob = $self->{buffer};
  $self->{buffer} = undef;
  delete $self->{_select};
  if (defined $self->{read_fh}) {
    close $self->{read_fh};
    $self->{read_fh} = undef;
  }
  $self->_reap;

  my $data;
  $data = eval { Storable::thaw($blob) } if defined $blob && length $blob;
  if (!$data || ref $data ne 'HASH') {
    $self->{failed} = 1;
    $self->{result} = 'DBIO::Forked::Future: corrupt or empty result from child'
      . ($@ ? ": $@" : '');
  }
  elsif (exists $data->{error}) {
    $self->{failed} = 1;
    $self->{result} = $data->{error};
  }
  else {
    $self->{failed} = 0;
    $self->{result} = $data->{rows} || [];
  }
  $self->{ready} = 1;
}

# Resolve a derived future: force the source, then apply the callback. Runs the
# callback synchronously (the source is ready by now). Returns 0 without effect
# if the source is not ready and we are non-blocking.
sub _resolve_derived {
  my ($self, $blocking) = @_;
  my $source = $self->{source};
  return 0 unless $source->_resolve($blocking);

  my @out;
  if (!$source->{failed}) {
    if (my $cb = $self->{on_done}) {
      @out = eval { $cb->(@{ $source->{result} || [] }) };
      return $self->_settle_failed("$@") if $@;
    }
    else {
      @out = @{ $source->{result} || [] };   # pass-through (bare catch)
    }
  }
  else {
    if (my $cb = $self->{on_fail}) {
      @out = eval { $cb->($source->{result}) };
      return $self->_settle_failed("$@") if $@;
    }
    else {
      return $self->_settle_failed($source->{result});   # no handler -- propagate
    }
  }

  # Flatten a single returned future (chaining).
  if (@out == 1 && Scalar::Util::blessed($out[0]) && $out[0]->isa(__PACKAGE__)) {
    my $inner = $out[0];
    return 0 unless $inner->_resolve($blocking);
    $self->{failed} = $inner->{failed} ? 1 : 0;
    $self->{result} = $inner->{result};
    $self->{ready}  = 1;
    return 1;
  }

  $self->{failed} = 0;
  $self->{result} = \@out;
  $self->{ready}  = 1;
  return 1;
}

sub _settle_failed {
  my ($self, $err) = @_;
  $self->{failed} = 1;
  $self->{result} = $err;
  $self->{ready}  = 1;
  return 1;
}

sub _reap {
  my $self = shift;
  return if $self->{reaped};
  waitpid($self->{pid}, 0) if defined $self->{pid};
  $self->{reaped} = 1;
}

# Reap an un-collected child so it does not become a zombie.
sub DESTROY {
  my $self = shift;
  return if $self->{reaped};
  close $self->{read_fh} if defined $self->{read_fh};
  waitpid($self->{pid}, 0) if defined $self->{pid};
  $self->{reaped} = 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Forked::Future - Loop-free, pipe-backed Future for DBIO::Forked

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

A loop-free Future implementation over a pipe read fd, with no L<Future>, no
L<Future::IO> and no event loop. It is what L<DBIO::Forked::Storage> hands back
from its C<*_async> methods.

It fulfils both the minimal core L<DBIO::Future> contract (C<then> / C<catch> /
C<get> / C<is_ready> / C<is_failed>) AND the fuller, L<DBIO::Future::Immediate>-compatible
surface (the C<done> / C<fail> / C<needs_all> class constructors, plus
C<and_then>), so it works as a live C<future_class> for core's ResultSet async
helpers (C<all_async> / C<first_async> / C<single_async> / C<count_async> /
C<create_async>), which build futures via C<< $storage->future_class->done(@rows) >>
and C<< ->fail($err) >>.

The model is deliberately simple, matching Model A (one forked child per
query):

=over 4

=item *

B<is_ready> is an EOF-clean, non-blocking drain. C<< IO::Select->can_read(0) >>
goes true as soon as the child writes I<anything>, not when it is done, so a
bare peek would be premature. Instead C<is_ready> reads whatever is available
without blocking and accumulates it across calls; it returns true only once the
child closes its write end (C<sysread> returns 0 = EOF), at which point the blob
is thawed, cached and the child reaped.

=item *

B<get> blocks until EOF, C<Storable>-thaws the accumulated blob, C<waitpid>-reaps
the child, and returns the rows -- or re-throws the child's error. It is
idempotent: the result is cached, so a second C<get> does not read or reap
again.

=item *

B<then> / B<catch> / B<and_then> compose lazily. A derived future stores its
callbacks and a reference to its source; it resolves (running the callback
synchronously, since the source is by then ready) the first time it is forced
via C<get>, or via C<is_ready>/C<is_failed> once the source is ready. No
callback runs before its source has resolved, and nothing blocks unless C<get>
is called.

=item *

B<done> / B<fail> / B<needs_all> are immediate class constructors (no fork): a
settled future is a pre-resolved leaf with no child, so it flows through the
same resolution machinery. C<needs_all> blocks on each input via C<get> in turn
(the children already run in parallel).

=back

=head1 METHODS

=head2 new

  my $future = DBIO::Forked::Future->new(read_fh => $fh, pid => $pid);

Construct a leaf future bound to the pipe read handle C<read_fh> and the forked
child C<pid>. Both are optional so the object can be built before the fork
wiring is in place.

=head2 done

  my $f = DBIO::Forked::Future->done(@values);

Class method: an immediately-resolved successful future carrying @values, with
no fork and no pipe. This is the constructor core's ResultSet async helpers call
as C<< $storage->future_class->done(@rows) >>.

=head2 fail

  my $f = DBIO::Forked::Future->fail($error);

Class method: an immediately-resolved failed future; L</get> re-throws $error.
The ResultSet async helpers call C<< $storage->future_class->fail($err) >>.

=head2 needs_all

  my $f = DBIO::Forked::Future->needs_all(@futures);

Class method: resolves once ALL @futures have resolved, collecting their values
in order; fails as soon as any one fails, with that future's error. Under Model A
the forked children already run in parallel; C<needs_all> just blocks on each in
turn via L</get>. Because collection is serial and each child holds its result
in the pipe until read, a batch of many large results can stall on the
pipe-buffer ceiling (see C<docs/adr/0003>); fine for modest result sets.

=head2 then

  my $g = $future->then(sub { my @result = @_; ... });

Success continuation. Returns a new C<DBIO::Forked::Future> that, when forced,
runs the callback with this future's resolved values and resolves to the
callback's return values. On failure the callback is skipped and the failure
propagates (unless an optional second C<$on_fail> argument is given).

=head2 catch

  my $g = $future->catch(sub { my $error = shift; ... });

Failure continuation. Returns a new C<DBIO::Forked::Future>; on failure it runs
the callback with the error and resolves to its return values, on success it
passes the values through unchanged.

=head2 and_then

  my $g = $future->and_then(sub { my @r = @_; return DBIO::Forked::Future->done(...) });

Like L</then>, but the callback is expected to return a future, which is
flattened into the chain (no future-wrapping-a-future). Mirrors
L<DBIO::Future::Immediate/and_then>. (C<then> already flattens a returned future, so
C<and_then> is C<then> with future-returning intent made explicit.)

=head2 get

  my @result = $future->get;

Block until resolved, then return the resolved values -- or C<croak> with the
child's error if it failed. Idempotent. Like L<DBIO::Future::Immediate/get>, in
scalar context it returns the first value (not the count).

=head2 is_ready

  if ($future->is_ready) { ... }

Non-blocking. True once resolved (the child has finished and its blob been
read, or the source of a derived future has resolved). Never blocks.

=head2 is_failed

  if ($future->is_failed) { ... }

Non-blocking. True once resolved I<and> the result is an error.

=head1 STATUS

Full C<future_class> surface implemented: the minimal L<DBIO::Future> contract
plus the L<DBIO::Future::Immediate>-compatible C<done> / C<fail> / C<needs_all> /
C<and_then>. L</then> / L</catch> / L</and_then> flatten a single returned
C<DBIO::Forked::Future> (chaining) but do not otherwise inspect nested
structures.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

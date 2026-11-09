package DBIO::Test::Future;
# ABSTRACT: Manually settled Future for deterministic DBIO tests

use strict;
use warnings;

our $VERSION = '0.900004';

use Scalar::Util ();
use DBIO::Exception ();

# Also callable on an instance, for a new pending Future of the same class --
# the Future.pm idiom core's listen machinery relies on (karr k222).
sub new {
  my ($class) = @_;
  return bless {
    state     => 'pending',
    values    => [],
    callbacks => [],
  }, ref($class) || $class;
}

sub done {
  my $invocant = shift;
  my $self = ref $invocant ? $invocant : $invocant->new;
  return $self->_settle(done => @_);
}

sub fail {
  my $invocant = shift;
  my $self = ref $invocant ? $invocant : $invocant->new;
  return $self->_settle(failed => @_);
}

sub _settle {
  my ($self, $state, @values) = @_;
  DBIO::Exception->throw('DBIO::Test::Future is already settled')
    unless $self->{state} eq 'pending';
  $self->{state}  = $state;
  $self->{values} = \@values;
  $self->_drain_callbacks;
  return $self;
}

sub is_ready  { return $_[0]{state} ne 'pending' }
sub is_failed { return $_[0]{state} eq 'failed' }

sub get {
  my ($self) = @_;
  DBIO::Exception->throw('Cannot get a pending DBIO::Test::Future')
    unless $self->is_ready;
  DBIO::Exception->throw($self->{values}[0])
    if $self->is_failed;
  return wantarray ? @{ $self->{values} } : $self->{values}[0];
}

sub then {
  my ($self, $on_done, $on_fail) = @_;
  my $derived = ref($self)->new;
  push @{ $self->{callbacks} }, [ $derived, $on_done, $on_fail ];
  $self->_drain_callbacks if $self->is_ready;
  return $derived;
}

sub catch {
  my ($self, $on_fail) = @_;
  return $self->then(undef, $on_fail);
}

# A derived Future is held strongly -- here, and in the closures below -- so the
# chain is held from its head: a ->then result nobody holds still runs its
# callback. It can be gone only in global destruction, where Perl clears
# references to objects in no particular order; nobody is left to be told
# there, so its callback does not run and nothing is settled (karr core k257).
sub _drain_callbacks {
  my ($self) = @_;
  while (my $entry = shift @{ $self->{callbacks} }) {
    next unless defined $entry->[0];
    $self->_run_callback(@$entry);
  }
  return;
}

sub _run_callback {
  my ($self, $derived, $on_done, $on_fail) = @_;
  my $callback = $self->is_failed ? $on_fail : $on_done;

  unless ($callback) {
    return $self->is_failed
      ? $derived->fail(@{ $self->{values} })
      : $derived->done(@{ $self->{values} });
  }

  my ($ok, $result, $error);
  {
    local $@;
    $ok = eval {
      $result = scalar $callback->(@{ $self->{values} });
      1;
    };
    $error = $@ unless $ok;
  }
  return $derived->fail($error) unless $ok;
  return $self->_adopt_result($derived, $result);
}

sub _adopt_result {
  my ($self, $derived, $result) = @_;
  unless (Scalar::Util::blessed($result)
      && $result->isa('DBIO::Test::Future')) {
    return $derived->done($result);
  }

  $result->then(
    sub {
      $derived->done(@_) if defined $derived;
      return;
    },
    sub {
      $derived->fail($_[0]) if defined $derived;
      return;
    },
  );
  return $derived;
}

# The Futures a needs_all aggregate is made of that are still pending, as
# Future.pm answers it for a convergent Future. Like Future.pm it refuses any
# other Future.
sub pending_futures {
  my ($self) = @_;
  DBIO::Exception->throw('Cannot call ->pending_futures on a non-convergent Future')
    unless $self->{subs};
  return grep { !$_->is_ready } @{ $self->{subs} };
}

sub needs_all {
  my ($class, @futures) = @_;
  my $aggregate = $class->new;
  $aggregate->{subs} = [ @futures ];
  return $aggregate->done unless @futures;

  my $remaining = scalar @futures;
  my @results;
  for my $index (0 .. $#futures) {
    $futures[$index]->then(
      sub {
        return unless defined $aggregate;
        $results[$index] = [ @_ ];
        unless (--$remaining) {
          $aggregate->done(map { @$_ } @results)
            unless $aggregate->is_ready;
        }
        return;
      },
      sub {
        return unless defined $aggregate;
        $aggregate->fail($_[0]) unless $aggregate->is_ready;
        return;
      },
    );
  }
  return $aggregate;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Future - Manually settled Future for deterministic DBIO tests

=head1 VERSION

version 0.900004

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package DBIO::Storage::BlockRunner;
# ABSTRACT: Execute code blocks with transaction wrapping and retry logic

use warnings;
use strict;

use DBIO::Exception;
use DBIO::Carp;
use Context::Preserve 'preserve_context';
use DBIO::Util qw(is_exception qsub);
use Scalar::Util qw(weaken blessed reftype);
use Try::Tiny;
use namespace::clean;


sub new {
  my $class = shift;
  my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

  for my $required (qw(storage wrap_txn retry_handler)) {
    DBIO::Exception->throw("Missing required attribute '$required'")
      unless exists $args{$required};
  }

  # isa check for retry_handler
  (Scalar::Util::reftype($args{retry_handler})||'') eq 'CODE'
    or DBIO::Exception->throw('retry_handler must be a CODE reference');

  my $self = bless {
    storage       => $args{storage},
    wrap_txn      => $args{wrap_txn},
    retry_handler => $args{retry_handler},
    max_attempts  => exists $args{max_attempts} ? $args{max_attempts} : 20,
    ( exists $args{retry_debug} ? ( retry_debug => $args{retry_debug} ) : () ),
    # failed_attempt_count and exception_stack have init_arg => undef
    # so they are never accepted from constructor args
  }, ref $class || $class;

  return $self;
}

sub storage { $_[0]->{storage} }

sub wrap_txn { $_[0]->{wrap_txn} }

# true - retry, false - rethrow, or you can throw your own (not catching)
sub retry_handler { $_[0]->{retry_handler} }

sub retry_debug {
  if (@_ > 1) {
    $_[0]->{retry_debug} = $_[1];
    return $_[1];
  }
  # lazy default
  $_[0]->{retry_debug} = $ENV{DBIO_STORAGE_RETRY_DEBUG}
    unless exists $_[0]->{retry_debug};
  return $_[0]->{retry_debug};
}

sub max_attempts { $_[0]->{max_attempts} }

sub failed_attempt_count {
  # lazy default
  $_[0]->{failed_attempt_count} = 0
    unless exists $_[0]->{failed_attempt_count};
  return $_[0]->{failed_attempt_count};
}

sub _set_failed_attempt_count {
  $_[0]->{failed_attempt_count} = $_[1];
  # trigger
  $_[0]->throw_exception( sprintf (
    'Reached max_attempts amount of %d, latest exception: %s',
    $_[0]->max_attempts, $_[0]->last_exception
  )) if $_[0]->max_attempts <= ($_[1]||0);
  return $_[1];
}

sub exception_stack {
  # lazy default
  $_[0]->{exception_stack} = []
    unless exists $_[0]->{exception_stack};
  return $_[0]->{exception_stack};
}

sub _reset_exception_stack {
  delete $_[0]->{exception_stack};
}

sub last_exception { shift->exception_stack->[-1] }

sub throw_exception { shift->storage->throw_exception (@_) }

sub run {
  my $self = shift;

  $self->_reset_exception_stack;
  $self->_set_failed_attempt_count(0);

  my $cref = shift;

  $self->throw_exception('run() requires a coderef to execute as its first argument')
    if ( reftype($cref)||'' ) ne 'CODE';

  my $storage = $self->storage;

  # Don't get into the tangle of code below if we already know the storage is
  # trying to rollback.
  $storage->_throw_deferred_rollback if $storage->deferred_rollback;

  return $cref->( @_ ) if (
    $storage->{_in_do_block}
      and
    ! $self->wrap_txn
  );

  local $storage->{_in_do_block} = 1 unless $storage->{_in_do_block};

  return $self->_run($cref, @_);
}

# this is the actual recursing worker
sub _run {
  # internal method - we know that both refs are strong-held by the
  # calling scope of run(), hence safe to weaken everything
  weaken( my $self = shift );
  weaken( my $cref = shift );

  my $args = @_ ? \@_ : [];

  # from this point on (defined $txn_init_depth) is an indicator for wrap_txn
  # save a bit on method calls
  my $txn_init_depth = $self->wrap_txn ? $self->storage->transaction_depth : undef;
  my $txn_begin_ok;

  my $run_err = '';

  return preserve_context {
    try {
      if (defined $txn_init_depth) {
        $self->storage->txn_begin;
        $txn_begin_ok = 1;
      }
      $cref->( @$args );
    } catch {
      $run_err = $_;
      (); # important, affects @_ below
    };
  } replace => sub {
    my @res = @_;

    my $storage = $self->storage;
    my $cur_depth = $storage->transaction_depth;

    if (defined $txn_init_depth and ! is_exception $run_err) {
      my $delta_txn = (1 + $txn_init_depth) - $cur_depth;

      if ($delta_txn) {
        # a rollback in a top-level txn_do is valid-ish (seen in the wild and our own tests)
        carp (sprintf
          'Unexpected reduction of transaction depth by %d after execution of '
        . '%s, skipping txn_commit()',
          $delta_txn,
          $cref,
        ) unless $delta_txn == 1 and $cur_depth == 0;
      }
      elsif ($storage->deferred_rollback) {
        # This means the inner code called 'rollback' in a case where savepoints
        # weren't enabled, and then caught the exception.
        carp 'A deferred rollback is in effect, but you exited a transaction-wrapped '
           . 'block cleanly which normally implies "commit". '
           . "You're getting a rollback instead.";
        # perform rollback via the error path below
        $run_err = eval { $storage->txn_rollback; 1 } ? '' : $@;
      }
      else {
        $run_err = eval { $storage->txn_commit; 1 } ? '' : $@;
      }
    }

    # something above threw an error (could be the begin, the code or the commit)
    if ( is_exception $run_err ) {

      # attempt a rollback if we did begin in the first place
      if ($txn_begin_ok) {
        # some DBDs go crazy if there is nothing to roll back on, perform a soft-check
        my $rollback_exception = $storage->_seems_connected
          ? (! eval { $storage->txn_rollback; 1 }) ? $@ : ''
          : 'lost connection to storage'
        ;

        if ( $rollback_exception and (
          ! defined blessed $rollback_exception
            or
          ! $rollback_exception->isa('DBIO::Storage::NESTED_ROLLBACK_EXCEPTION')
        ) ) {
          $run_err = "Transaction aborted: $run_err. Rollback failed: $rollback_exception";
        }
      }

      push @{ $self->exception_stack }, $run_err;

      # this will throw if max_attempts is reached
      $self->_set_failed_attempt_count($self->failed_attempt_count + 1);

      # init depth of > 0 ( > 1 with AC) implies nesting - no retry attempt queries
      $storage->throw_exception($run_err) if (
        (
          defined $txn_init_depth
            and
          # FIXME - we assume that $storage->{_dbh_autocommit} is there if
          # txn_init_depth is there, but this is a DBI-ism
          $txn_init_depth > ( $storage->{_dbh_autocommit} ? 0 : 1 )
        ) or ! $self->retry_handler->($self)
      );

      # we got that far - let's retry
      carp( sprintf 'Retrying %s (attempt %d) after caught exception: %s',
        $cref,
        $self->failed_attempt_count + 1,
        $run_err,
      ) if $self->retry_debug;

      $storage->ensure_connected;
      # if txn_depth is > 1 this means something was done to the
      # original $dbh, otherwise we would not get past the preceding if()
      $storage->throw_exception(sprintf
        'Unexpected transaction depth of %d on freshly connected handle',
        $storage->transaction_depth,
      ) if (defined $txn_init_depth and $storage->transaction_depth);

      return $self->_run($cref, @$args);
    }

    return wantarray ? @res : $res[0];
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::BlockRunner - Execute code blocks with transaction wrapping and retry logic

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Utility object used by L<DBIO::Storage::DBI> to execute coderefs with
transaction wrapping and retry semantics.

=head1 ATTRIBUTES

=head2 storage

The storage object used for transaction methods and exception handling.

=head2 wrap_txn

Boolean. If true, wrap each execution attempt in a transaction.

=head2 retry_handler

Coderef deciding whether to retry after a failure.

=head2 retry_debug

Boolean controlling retry debug output.

=head2 max_attempts

Maximum number of failed attempts before aborting.

=head2 failed_attempt_count

Internal counter of failed attempts in the current C<run>.

=head2 exception_stack

Collected exceptions from failed attempts in the current C<run>.

=head1 METHODS

=head2 last_exception

Returns the most recent exception captured in C<exception_stack>.

=head2 throw_exception

Delegates exception throwing to the configured C<storage>.

=head2 run

Execute a coderef with configured retry and transaction behavior.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

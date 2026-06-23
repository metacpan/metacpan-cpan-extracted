package DBIO::Storage::Statistics;
# ABSTRACT: SQL Statistics

use strict;
use warnings;

use DBIO::Util qw(sigwarn_silencer qsub);
use IO::Handle ();
use Time::HiRes ();

use base 'DBIO::Base';
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw(
  _defaulted_to_stderr
  silence
  callback
  _query_start_time
  last_query_elapsed
  total_elapsed
  query_count
));


sub new {
  my $class = shift;
  my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
  my $self = bless {}, ref $class || $class;
  $self->{$_} = $args{$_} for grep { exists $args{$_} }
    qw(_debugfh _defaulted_to_stderr silence callback);
  $self->{total_elapsed} = 0;
  $self->{query_count} = 0;
  return $self;
}

# FIXME - there ought to be a way to fold this into _debugfh itself
# having the undef re-trigger the builder (or better yet a default
# which can be folded in as a qsub)
sub debugfh {
  my $self = shift;

  return $self->_debugfh(@_) if @_;
  $self->_debugfh || $self->_build_debugfh;
}

sub _debugfh {
  my $self = shift;
  if (@_) {
    $self->{_debugfh} = $_[0];
    $self->_defaulted_to_stderr(undef);
    return $_[0];
  }
  return $self->{_debugfh};
}

sub _build_debugfh {
  my $fh;

  my $debug_env = $ENV{DBIO_TRACE};

  if (defined($debug_env) and ($debug_env =~ /=(.+)$/)) {
    open ($fh, '>>', $1)
      or die("Cannot open trace file $1: $!\n");
  }
  else {
    open ($fh, '>&STDERR')
      or die("Duplication of STDERR for debug output failed (perhaps your STDERR is closed?): $!\n");
    $_[0]->_defaulted_to_stderr(1);
  }

  $fh->autoflush(1);

  $fh;
}


sub print {
  my ($self, $msg) = @_;

  return if $self->silence;

  my $fh = $self->debugfh;

  # not using 'no warnings' here because all of this can change at runtime
  local $SIG{__WARN__} = sigwarn_silencer(qr/^Wide character in print/)
    if $self->_defaulted_to_stderr;

  $fh->print($msg);
}

sub txn_begin {
  my $self = shift;

  return if $self->callback;

  $self->print("BEGIN WORK\n");
}

sub txn_rollback {
  my $self = shift;

  return if $self->callback;

  $self->print("ROLLBACK\n");
}

sub txn_commit {
  my $self = shift;

  return if $self->callback;

  $self->print("COMMIT\n");
}

sub svp_begin {
  my ($self, $name) = @_;

  return if $self->callback;

  $self->print("SAVEPOINT $name\n");
}

sub svp_release {
  my ($self, $name) = @_;

  return if $self->callback;

  $self->print("RELEASE SAVEPOINT $name\n");
}

sub svp_rollback {
  my ($self, $name) = @_;

  return if $self->callback;

  $self->print("ROLLBACK TO SAVEPOINT $name\n");
}

sub query_start {
  my ($self, $string, @bind) = @_;

  $self->_query_start_time(Time::HiRes::time());

  # @bind is only populated when debug output is enabled
  return unless @bind;

  my $message = "$string: ".join(', ', @bind)."\n";

  if(defined($self->callback)) {
    $string =~ m/^(\w+)/;
    $self->callback->($1, $message);
    return;
  }

  $self->print($message);
}


sub query_end {
  my ($self, $string, @bind) = @_;

  my $start = $self->_query_start_time;
  return unless defined $start;

  my $elapsed = Time::HiRes::time() - $start;
  $self->last_query_elapsed($elapsed);
  $self->{total_elapsed} += $elapsed;
  $self->{query_count}++;
  $self->_query_start_time(undef);

  # only print elapsed when debug output is active
  if (@bind && !$self->silence && !defined($self->callback)) {
    $self->print(sprintf("  Elapsed: %.6fs\n", $elapsed));
  }
}


sub reset_stats {
  my $self = shift;
  $self->{query_count} = 0;
  $self->{total_elapsed} = 0;
  $self->{last_query_elapsed} = undef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::Statistics - SQL Statistics

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

    my $stats = $schema->storage->debugobj;

    # Query timing is always available, even without DBIO_TRACE
    say $stats->last_query_elapsed;   # seconds (float) of last query
    say $stats->total_elapsed;        # cumulative seconds
    say $stats->query_count;          # number of queries executed
    $stats->reset_stats;              # reset counters

    # Enable trace output to see SQL and timing:
    #   DBIO_TRACE=1 ./my_app.pl
    # Output:
    #   SELECT me.id, me.name FROM artist me: '1', '2'
    #     Elapsed: 0.003421s

=head1 DESCRIPTION

This class is called by DBIO::Storage::DBI as a means of collecting
statistics on its actions.  It prints SQL statements and elapsed time
when tracing is enabled, and always tracks query timing internally
for programmatic access.

To customize statistics collection, subclass this class and override
the C<query_start>/C<query_end> methods as discussed in
L<DBIO::Manual::Cookbook>.

=head1 ATTRIBUTES

=head2 _defaulted_to_stderr

Internal flag indicating that debug output currently defaults to STDERR.

=head2 silence

Boolean flag to suppress trace output when true.

=head2 callback

Optional callback invoked by C<query_start> instead of printing.

=head2 last_query_elapsed

The elapsed time (in seconds, as a float) of the most recent query.
Always available, even when debug output is disabled.

=head2 total_elapsed

The cumulative elapsed time (in seconds) of all queries since the
statistics object was created or L</reset_stats> was called.

=head2 query_count

The number of queries executed since the statistics object was created
or L</reset_stats> was called.

=head1 METHODS

=head2 new

Returns a new L<DBIO::Storage::Statistics> object.

=head2 debugfh

Sets or retrieves the filehandle used for trace/debug output.  This should
be an L<IO::Handle> compatible object (only the
L<< print|IO::Handle/METHODS >> method is used). By
default it is initially set to STDERR - although see discussion of the
L<DBIO_TRACE|DBIO::Storage/DBIO_TRACE> environment variable.

Invoked as a getter it will lazily open a filehandle and set it to
L<< autoflush|perlvar/HANDLE->autoflush( EXPR ) >> (if one is not
already set).

=head2 print

Prints the specified string to our debugging filehandle.  Provided to save our
methods the worry of how to display the message.

=head2 txn_begin

Called when a transaction begins.

=head2 txn_rollback

Called when a transaction is rolled back.

=head2 txn_commit

Called when a transaction is committed.

=head2 svp_begin

Called when a savepoint is created.

=head2 svp_release

Called when a savepoint is released.

=head2 svp_rollback

Called when rolling back to a savepoint.

=head2 query_start

Called before a query is executed.  The first argument is the SQL string being
executed and subsequent arguments are the parameters used for the query.

=head2 query_end

Called when a query finishes executing.  Has the same arguments as
C<query_start>.  Records the elapsed time and updates L</query_count>
and L</total_elapsed>.

=head2 reset_stats

Resets L</query_count>, L</total_elapsed>, and L</last_query_elapsed>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package DBIO::Storage::DBI::Cursor;
# ABSTRACT: Object representing a query cursor on a resultset.

use strict;
use warnings;

use base 'DBIO::Cursor';

use Try::Tiny;
use Scalar::Util qw(refaddr weaken);
use DBIO::Util qw(has_ithreads is_windows shuffle_unordered_resultsets);
use namespace::clean;

__PACKAGE__->mk_group_accessors('simple' =>
    qw/storage args attrs/
);


{
  my %cursor_registry;

  sub new {
    my ($class, $storage, $args, $attrs) = @_;

    my $self = bless {
      storage => $storage,
      args => $args,
      attrs => $attrs,
    }, ref $class || $class;

    if (has_ithreads) {

      # quick "garbage collection" pass - prevents the registry
      # from slowly growing with a bunch of undef-valued keys
      defined $cursor_registry{$_} or delete $cursor_registry{$_}
        for keys %cursor_registry;

      weaken( $cursor_registry{ refaddr($self) } = $self )
    }

    return $self;
  }

  sub CLONE {
    for (keys %cursor_registry) {
      # once marked we no longer care about them, hence no
      # need to keep in the registry, left alone renumber the
      # keys (all addresses are now different)
      my $self = delete $cursor_registry{$_}
        or next;

      $self->{_intra_thread} = 1;
    }
  }
}


sub next {
  my $self = shift;

  return if $self->{_done};

  my $sth;

  if (
    $self->{attrs}{software_limit}
      && $self->{attrs}{rows}
        && ($self->{_pos}||0) >= $self->{attrs}{rows}
  ) {
    if ($sth = $self->sth) {
      # explicit finish will issue warnings, unlike the DESTROY below
      $sth->finish if $sth->FETCH('Active');
    }
    $self->{_done} = 1;
    return;
  }

  unless ($sth = $self->sth) {
    (undef, $sth, undef) = $self->storage->_select( @{$self->{args}} );

    $self->{_results} = [ (undef) x $sth->FETCH('NUM_OF_FIELDS') ];
    $sth->bind_columns( \( @{$self->{_results}} ) );

    if ( $self->{attrs}{software_limit} and $self->{attrs}{offset} ) {
      $sth->fetch for 1 .. $self->{attrs}{offset};
    }

    $self->sth($sth);
  }

  if ($sth->fetch) {
    $self->{_pos}++;
    return @{$self->{_results}};
  } else {
    $self->{_done} = 1;
    return ();
  }
}



sub all {
  my $self = shift;

  # delegate to DBIC::Cursor which will delegate back to next()
  if ($self->{attrs}{software_limit}
        && ($self->{attrs}{offset} || $self->{attrs}{rows})) {
    return $self->next::method(@_);
  }

  my $sth;

  if ($sth = $self->sth) {
    # explicit finish will issue warnings, unlike the DESTROY below
    $sth->finish if ( ! $self->{_done} and $sth->FETCH('Active') );
    $self->sth(undef);
  }

  (undef, $sth) = $self->storage->_select( @{$self->{args}} );

  (
    shuffle_unordered_resultsets
      and
    ! $self->{attrs}{order_by}
      and
    require List::Util
  )
    ? List::Util::shuffle( @{$sth->fetchall_arrayref} )
    : @{$sth->fetchall_arrayref}
  ;
}


sub sth {
  my $self = shift;

  if (@_) {
    delete @{$self}{qw/_pos _done _pid _intra_thread/};

    $self->{sth} = $_[0];
    $self->{_pid} = $$ if ! is_windows and $_[0];
  }
  elsif ($self->{sth} and ! $self->{_done}) {

    my $invalidate_handle_reason;

    if (has_ithreads and $self->{_intra_thread} ) {
      $invalidate_handle_reason = 'Multi-thread';
    }
    elsif (!is_windows and $self->{_pid} != $$ ) {
      $invalidate_handle_reason = 'Multi-process';
    }

    if ($invalidate_handle_reason) {
      $self->storage->throw_exception("$invalidate_handle_reason access attempted while cursor in progress (position $self->{_pos})")
        if $self->{_pos};

      # reinvokes the reset logic above
      $self->sth(undef);
    }
  }

  return $self->{sth};
}


sub reset {
  $_[0]->__finish_sth if $_[0]->{sth};
  $_[0]->sth(undef);
}


sub DESTROY {
  $_[0]->__finish_sth if $_[0]->{sth};
}


sub __finish_sth {
  # It is (sadly) extremely important to finish() handles we are about
  # to lose (due to reset() or a DESTROY() ). $rs->reset is the closest
  # thing the user has to getting to the underlying finish() API and some
  # DBDs mandate this (e.g. DBD::InterBase will segfault, DBD::Sybase
  # won't start a transaction sanely, etc)
  # We also can't use the accessor here, as it will trigger a fork/thread
  # check, and resetting a cursor in a child is perfectly valid

  my $self = shift;

  # No need to care about failures here
  try { local $SIG{__WARN__} = sub {}; $self->{sth}->finish } if (
    $self->{sth} and ! try { ! $self->{sth}->FETCH('Active') }
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::Cursor - Object representing a query cursor on a resultset.

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

  my $cursor = $schema->resultset('CD')->cursor();

  # raw values off the database handle in resultset columns/select order
  my @next_cd_column_values = $cursor->next;

  # list of all raw values as arrayrefs
  my @all_cds_column_values = $cursor->all;

See F<t/cursor.t> for a runnable example of this raw-value C<< ->next >>/
C<< ->all >> API (the public cursor contract shared with L<DBIO::Cursor>).

=head1 DESCRIPTION

A Cursor represents a query cursor on a L<DBIO::ResultSet> object. It
allows for traversing the result set with L</next>, retrieving all results with
L</all> and resetting the cursor with L</reset>.

Usually, you would use the cursor methods built into L<DBIO::ResultSet>
to traverse it. See L<DBIO::ResultSet/next>,
L<DBIO::ResultSet/reset> and L<DBIO::ResultSet/all> for more
information.

=head1 ATTRIBUTES

=head2 storage

Storage handle used to execute underlying select statements.

=head2 args

Arguments forwarded to C<< $storage->_select(...) >>.

=head2 attrs

Cursor/resultset attributes affecting fetch behavior.

=head1 METHODS

=head2 new

Returns a new L<DBIO::Storage::DBI::Cursor> object.

=head2 next

=over 4

=item Arguments: none

=item Return Value: \@row_columns

=back

Advances the cursor to the next row and returns an array of column
values (the result of L<DBI/fetchrow_array> method).

=head2 all

=over 4

=item Arguments: none

=item Return Value: \@row_columns+

=back

Returns a list of arrayrefs of column values for all rows in the
L<DBIO::ResultSet>.

=head2 sth

Getter/setter for the underlying statement handle with process/thread safety
checks.

=head2 reset

Resets the cursor to the beginning of the L<DBIO::ResultSet>.

=head2 DESTROY

Ensures active statement handles are finished during object destruction.

=head2 __finish_sth

Internal helper to safely finish a statement handle, suppressing warnings.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package DBIO::Sybase::Diff;
# ABSTRACT: Compare two introspected Sybase ASE models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';


use DBIO::Sybase::Diff::Table      ();
use DBIO::Sybase::Diff::Column     ();
use DBIO::Sybase::Diff::Index      ();
use DBIO::Sybase::Diff::ForeignKey ();
use DBIO::Sybase::Diff::View       ();

sub _build_operations {
  my ($self) = @_;
  my @ops;

  # Foreign keys are diffed once, then split: drops must precede table/column
  # drops, adds must follow table/column creates. ASE FKs are not altered in
  # place, so an attribute change is already a drop+create pair from ::ForeignKey.
  my @fk_ops = DBIO::Sybase::Diff::ForeignKey->diff(
    $self->source->{foreign_keys}, $self->target->{foreign_keys},
    $self->source->{tables},       $self->target->{tables},
  );
  my @fk_drops = grep { $_->action eq 'drop'   } @fk_ops;
  my @fk_adds  = grep { $_->action eq 'create' } @fk_ops;

  # Indexes are diffed once, then split the same way FKs are: ASE refuses to
  # drop a column while an index still references it, so an index DROP must
  # precede the column diff. A CREATE/ALTER must FOLLOW it -- a new or changed
  # column has to exist before an index can name it (an ::Index alter is itself
  # a DROP+CREATE pair whose create half references the column, so it belongs
  # with the creates).
  my @idx_ops = DBIO::Sybase::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
  );
  my @idx_drops   = grep { $_->action eq 'drop' } @idx_ops;
  my @idx_creates = grep { $_->action ne 'drop' } @idx_ops;

  # Primary keys of retained tables (karr k53), split like the indexes: the
  # drop before the column diff (a key column may be about to go), the add
  # after it (a key column may be about to be added or made NOT NULL) and
  # before the FK adds (a new reference may need the new key).
  my @pk_ops = DBIO::Sybase::Diff::Table->diff_primary_keys(
    $self->source->{tables},  $self->target->{tables},
    $self->source->{columns}, $self->target->{columns},
    $self->source->{indexes},
  );
  my @pk_drops = grep { $_->action eq 'drop' } @pk_ops;
  my @pk_adds  = grep { $_->action ne 'drop' } @pk_ops;

  # Views (karr k98): the ones removed or changed go before any change to the
  # tables under them, the new and changed ones are created last, when every
  # table and column they read exists. Between views the order is that of their
  # dependencies.
  my @view_ops    = DBIO::Sybase::Diff::View->diff(
    $self->source->{views}, $self->target->{views});
  my @view_drops   = grep { $_->action eq 'drop'   } @view_ops;
  my @view_creates = grep { $_->action eq 'create' } @view_ops;

  push @ops, @fk_drops;
  push @ops, @view_drops;
  push @ops, DBIO::Sybase::Diff::Table->diff(
    $self->source->{tables},       $self->target->{tables},
    $self->target->{columns},     $self->target->{foreign_keys},
  );
  push @ops, @pk_drops;
  push @ops, @idx_drops;
  push @ops, DBIO::Sybase::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, @pk_adds;
  push @ops, @idx_creates;
  push @ops, @fk_adds;
  push @ops, @view_creates;

  return \@ops;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Diff - Compare two introspected Sybase ASE models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Sybase::Diff> compares two introspected Sybase ASE database models
(as produced by L<DBIO::Sybase::Introspect>) and produces a list of
structured diff operations that can be rendered to SQL or a human-readable
summary.

    my $diff = DBIO::Sybase::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Diff operations are generated in dependency order: foreign-key drops first
(so a referenced table/column can then be dropped), then the drops of removed
and changed views (a view must be gone before the table under it changes; see
L<DBIO::Sybase::Diff::View>), then tables, then
primary-key and index drops (ASE refuses to drop a column while an index still
references it), then columns, then primary-key adds and index creates/alters (a
new or changed column must exist before a key or an index can name it), then
foreign-key adds (so the tables/columns -- and keys -- they reference
already exist), and the creates of new and changed views last (so the tables
and columns they read exist). The primary key is compared as an ordered column
list, see L<DBIO::Sybase::Diff::Table/THE PRIMARY KEY IS PART OF THE TABLE>.

=head1 EVERY STATEMENT ENDS IN C<;>

Each op's C<as_sql> terminates every statement it renders with C<;> -- also
the second statement of a two-statement op (an index alter's DROP/CREATE, a
column alter's MODIFY followed by its REPLACE). That is the only boundary the
apply path knows: L<DBIO::Diff::Base> joins the ops with a newline, and
C<DBIO::Deploy::Base::_execute_ddl> splits the result on C<;> and nothing else
before handing each piece to C<< $dbh->do >>. An unterminated op is glued to
the next one, and the run reaches ASE as one batch. ASE compiles a batch
before executing any of it, so a correctly ordered migration fails whole --
live on ASE 16.0 SP02 a C<DROP INDEX> followed by the C<ALTER TABLE ... DROP>
of the indexed column was refused with Msg 4939, because the drop of the index
had not run when the column drop was compiled.

The split is not quote-aware. C<DBIO::SQL::Util::_split_statements> (core)
knows PostgreSQL C<$$> quoting and nothing else, so a C<;> inside a
single-quoted string -- a literal default such as C<'a;b'> -- is split as if it
ended the statement, and both halves are rejected. There is no way to escape
it from here; a literal default containing C<;> cannot be applied through
L<DBIO::Sybase::Deploy> until core's splitter honours C<'...'>.

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::Sybase::Deploy> - orchestrates introspection and diff

=item * L<DBIO::Sybase::Introspect> - produces the models being compared

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

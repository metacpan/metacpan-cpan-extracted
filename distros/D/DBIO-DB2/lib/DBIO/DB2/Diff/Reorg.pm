package DBIO::DB2::Diff::Reorg;
# ABSTRACT: Diff operation for the REORG a DB2 table needs after some column changes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::DB2::DDL qw(_db2_quote_ident _db2_quote_table);


__PACKAGE__->mk_diff_accessors(qw/table_name/);


sub diff {
  my ($class, @column_ops) = @_;
  my (%seen, @ops);

  for my $op (@column_ops) {
    next unless $op->reorg_recommended;
    next if $seen{ $op->table_name }++;
    push @ops, $class->new(action => 'reorg', table_name => $op->table_name);
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  (my $command = 'REORG TABLE ' . _db2_quote_table($self->table_name)) =~ s/'/''/g;
  return "CALL SYSPROC.ADMIN_CMD('$command');";
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sreorg: %s', $self->summary_prefix, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Diff::Reorg - Diff operation for the REORG a DB2 table needs after some column changes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Some of the C<ALTER TABLE> statements L<DBIO::DB2::Diff::Column> writes leave
the table in I<reorg-pending> state. Until a C<REORG> has run, Db2 refuses
C<INSERT>, C<UPDATE> and C<CREATE INDEX> on it with SQL0668N, reason code 7
(SQLSTATE 57007) -- so a diff that drops a column and creates an index on the
same table stops at the index, and since this deploy does not run its DDL in a
transaction (L<DBIO::DB2::Deploy/Transactional DDL -- the engine has it, this deploy does not use it>)
the column is gone by then.

This operation is that C<REORG>, as a statement of the diff: it is in
L<DBIO::Diff::Base/operations>, L<DBIO::Diff::Base/as_sql> and
L<DBIO::Diff::Base/summary> before anything is applied, and
L<DBIO::Deploy::Base/apply> runs it like every other statement.
L<DBIO::DB2::Diff> puts one per table after the column operations and before
the index operations; which column operations ask for one is
L<DBIO::DB2::Diff::Column/reorg_recommended>.

It is a classic C<REORG TABLE>, run through the C<SYSPROC.ADMIN_CMD> procedure
because C<REORG> is a command and not an SQL statement. It rewrites the table:
the time it takes grows with the table, and it is part of the upgrade from the
moment the diff contains one of those C<ALTER TABLE> statements -- the table
takes no row before it has run. See ADR 0008 for the measurements, and for
what is known about locks and the authority the call needs.

B<A table that is reorg-pending before the diff> -- an earlier upgrade that
stopped half way, a C<REORG> that failed, an C<ALTER TABLE> run by hand -- is
not in the diff: reorg-pending is a state of the table and not part of the
introspected model, so the diff sees no column operation and writes no
C<REORG>. L<DBIO::DB2::Deploy/upgrade> covers it outside the diff: it asks
C<SYSIBMADM.ADMINTABINFO> for the tables present in both models and runs this
operation's statement for the pending ones first (ADR 0008, addendum). C<diff>
and C<as_sql> do not show that C<REORG>; C<apply> alone, given a diff, does not
run it either.

C<new>, C<action> (always C<reorg>) and C<summary_prefix> come from
L<DBIO::Diff::Op>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::DB2::Diff::Reorg->diff(@column_ops);

Takes the operations of the column pass and returns one C<reorg> operation for
every table that has at least one operation answering true to
L<DBIO::DB2::Diff::Column/reorg_recommended> -- one, however many there are, in
the order the tables first appear. Db2 takes further C<ALTER TABLE> statements
on a reorg-pending table, so one C<REORG> after the last of them is enough.

=head2 as_sql

    CALL SYSPROC.ADMIN_CMD('REORG TABLE "author"');

The table name is a quoted identifier and unqualified, like the C<ALTER TABLE>
statements before it: C<ADMIN_CMD> resolves it against C<CURRENT SCHEMA>, as
the server does theirs. The command is a string literal, so an apostrophe in
the name is doubled.

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

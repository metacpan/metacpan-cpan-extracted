package DBIO::PostgreSQL::Diff::NoStatement;
# ABSTRACT: An operation the diff has no statement for is refused, not written as a comment or a placeholder

use strict;
use warnings;

our $VERSION = '0.900004';



sub refuse_without_definition {
  my ($class, %object) = @_;
  my ($kind, $name, $from) = @object{qw( kind name from )};

  die join "\n",
    ( $object{in_database}
        ? "refusing to diff: $kind $name is in the database and in the target, and the target model has no definition to compare it by or to write it from"
        : "refusing to diff: $kind $name is in the target and not in the database, and the target model has no definition to create it from" ),
    '',
    "The diff writes every $kind as the text $from gives for it,",
    'and compares it by that text.',
    ( $object{null_when_gone}
        ? ( 'The catalog gives none for an object that is gone by the time it is asked:',
            'one that another session dropped while the model was read.' )
        : () ),
    'A model built by hand has none unless it is given one.',
    ( defined $object{also} ? $object{also} : () ),
    'No statement was generated.',
    '',
    ( $object{null_when_gone} ? 'Read the target model again and diff again.' : () ),
    "In a model built by hand, give the $kind its definition.",
    '';
}


sub throw {
  my ($class, $op, $object, $why) = @_;
  my $action = $op->action;
  $why //= 'the class knows no such action';

  die sprintf "%s: no statement for %s on %s -- %s\n",
    ref $op, ( defined $action ? "action '$action'" : 'an operation without an action' ),
    $object, $why;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::NoStatement - An operation the diff has no statement for is refused, not written as a comment or a placeholder

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    use DBIO::PostgreSQL::Diff::NoStatement ();

    # in the diff method of an operation class, before the operation is built
    DBIO::PostgreSQL::Diff::NoStatement->refuse_without_definition(
      kind           => 'trigger',
      name           => "$trigger_name on $table_key",
      in_database    => $in_database,
      from           => 'pg_get_triggerdef',
      null_when_gone => 1,
    ) unless ($target_entry->{definition} // '') =~ /\S/;

    # in as_sql, where the operation has no statement
    DBIO::PostgreSQL::Diff::NoStatement->throw(
      $self, "trigger $trigger_name on $table_key", 'its trigger_info has no definition',
    );

    # and behind the last action as_sql knows
    DBIO::PostgreSQL::Diff::NoStatement->throw($self, "trigger $trigger_name on $table_key");

=head1 DESCRIPTION

A function, a trigger, an index and a view are not written by
L<DBIO::PostgreSQL::Diff> from their parts: they are written, and compared, as
the text the catalog gives for them (C<pg_get_functiondef>,
C<pg_get_triggerdef>, C<pg_get_indexdef>, C<pg_get_viewdef>). A model that has
such an object without that text leaves the diff with an operation and no
statement.

What used to come out then was a stand-in: C<-- CREATE TRIGGER ... (definition
unavailable)>, or C<CREATE INDEX ... (?)>, or for an index that had its
columns in the model the plain index on those columns. None of the three is an
answer:

=over 4

=item * The comment is not a statement that does nothing.
L<DBIO::Deploy::Base/_execute_ddl> cuts the script at its semicolons and
skips every piece that starts with C<-->. A comment has no semicolon, so it is
one piece with the statement that follows it, and that statement is skipped as
well. A trigger whose definition changed was dropped and not created again.

=item * C<(?)> is not SQL.

=item * The columns of an index are not the index. Whether it is unique, its
predicate, its access method, the order and the operator class of each column
are in the definition and nowhere else that a statement is written from.

=back

The rule that answers this stands here, once:

B<An operation that has no statement is not built, and where it is built by
hand it is not written.> L</refuse_without_definition> is for the C<diff>
method of an operation class -- C<refusing to diff: ...>, see
L<DBIO::PostgreSQL::Diff/WHAT IS REFUSED>, so that it is
L<DBIO::PostgreSQL::Deploy/diff> that dies and not a later C<as_sql> or
C<apply>. L</throw> is for C<as_sql>: an operation somebody built with C<new>
has passed no C<diff>, and its C<as_sql> dies instead of returning a comment, a
placeholder, an empty string or nothing.

=head2 When the catalog has no definition

Measured on PostgreSQL 18.6: C<pg_get_functiondef>, C<pg_get_triggerdef> and
C<pg_get_indexdef> return NULL for an object that is not there when they are
asked. They look it up apart from the snapshot of the statement that calls
them, so a session that reads the catalog under an older snapshot
(C<REPEATABLE READ>) still finds the row of a function, a trigger or an index
another session has dropped since -- with its name, and for an index with its
columns, that it is unique and its predicate -- and gets no definition for
it. That is the one way L<DBIO::PostgreSQL::Introspect> was found to hand out
such an entry; every function, trigger and index that was there had its
definition. L</refuse_without_definition> says so for these three
(C<null_when_gone>).

A view is no such case. C<pg_get_viewdef> does not return NULL for a view
that is gone, it raises C<could not open relation with OID ...>, and the
reading of the model dies of it. Nor is an aggregate: C<pg_get_functiondef>
raises an error for one, and L<DBIO::PostgreSQL::Introspect::Functions> reads
an aggregate and a window function without a definition. The diff refuses one
it would have to create or change, with a message of its own
(L<DBIO::PostgreSQL::Diff::Function/diff>).

The other way to such a model is to build it by hand.

=head1 METHODS

=head2 refuse_without_definition

    DBIO::PostgreSQL::Diff::NoStatement->refuse_without_definition(
      kind           => 'index',
      name           => 'users_email_idx on auth.users',
      in_database    => 0,
      from           => 'pg_get_indexdef',
      null_when_gone => 1,
      also           => 'Its columns are in the model, but ...',
    );

Dies with the refusal for an object the diff would have to create, or create
again, and that the target model has no definition for.

=over 4

=item C<kind> -- what the object is, as a reader calls it: C<function>,
C<trigger>, C<index>, C<view>

=item C<name> -- its name as a reader sees it, unquoted

=item C<in_database> -- true when the source model has the object as well.
The diff then cannot say whether the two are the same either: it compares
them by their definitions.

=item C<from> -- the catalog function the definition comes from

=item C<null_when_gone> -- true when that function returns NULL for an object
that is gone (L</When the catalog has no definition>). The message then names
that as the cause, and reading the model again as the way out.

=item C<also> -- optional: a sentence more on why the diff cannot write the
object from what the model does hold of it. It is a line of the message, or
several with a newline between them.

=back

=head2 throw

    DBIO::PostgreSQL::Diff::NoStatement->throw($op, $object, $why);
    DBIO::PostgreSQL::Diff::NoStatement->throw($op, $object);

Dies for an operation C<as_sql> has no statement for. C<$op> is the
operation, C<$object> says what it is on, as a reader calls it (C<function
public.f()>), and C<$why> why there is no statement. Without C<$why> the
reason is that the class of C<$op> does not know its C<action>: every
C<as_sql> ends in this call, so that an action nobody wrote a statement for
is not answered with nothing.

The message names the class of the operation, its action and the object.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL::Diff/WHAT IS REFUSED>

=item * L<DBIO::PostgreSQL::Diff::CaseOnly> - the other rule the operation classes share

=item * L<DBIO::Deploy::Base/_execute_ddl> - what runs the statements, and skips a comment

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

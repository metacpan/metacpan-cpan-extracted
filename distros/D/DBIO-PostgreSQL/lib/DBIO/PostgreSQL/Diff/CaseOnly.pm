package DBIO::PostgreSQL::Diff::CaseOnly;
# ABSTRACT: A name that differs from one in the database only in case is not a new object

use strict;
use warnings;

our $VERSION = '0.900004';



sub pairs {
  my ($class, $source, $target) = @_;

  # A name cannot hold a NUL byte, so nothing joined with one reads as
  # another place.
  my (%source, %target);
  $source{ join "\0", @{ $_->{in} } }{ $_->{name} } = $_ for @$source;
  $target{ join "\0", @{ $_->{in} } }{ $_->{name} } = $_ for @$target;

  my @pairs;
  for my $in (sort keys %target) {
    my ($had, $wanted) = ($source{$in} // {}, $target{$in});

    my %gone;
    push @{ $gone{ lc $_ } }, $_ for grep { !exists $wanted->{$_} } sort keys %$had;

    for my $new (sort grep { !exists $had->{$_} } keys %$wanted) {
      push @pairs, map { [ $had->{$_}, $wanted->{$new} ] } @{ $gone{ lc $new } // [] };
    }
  }
  return @pairs;
}


sub refuse {
  my ($class, $would, $first, @more) = @_;
  return unless $first;

  die join "\n",
    sprintf(
      'refusing to diff: %s %s is in the database and %s in the target, and the two names differ only in upper and lower case',
      @{$first}{qw( kind database target )},
    ),
    ( @more
        ? ( 'The same holds for:', map { "  $_->{kind} $_->{database} and $_->{target}" } @more )
        : () ),
    '',
    'PostgreSQL reads a name written without quotes in lower case and a quoted one',
    'exactly, so one object is easily known under two spellings. The diff takes',
    'them for two: it would create what the target names and drop what the',
    'database has.',
    $would,
    'No statement was generated.',
    '',
    'Where the two are the same object, rename what the database has,',
    ( map { "  $_->{rename}" } $first, @more ),
    'and diff again. Where they are not, drop what the database has yourself, or',
    'give it another name, and diff again.',
    '';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::CaseOnly - A name that differs from one in the database only in case is not a new object

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    use DBIO::PostgreSQL::Diff::CaseOnly ();
    use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified);

    # in the diff method of an operation class, ahead of everything else
    my @pairs = DBIO::PostgreSQL::Diff::CaseOnly->pairs(
      [ map { { in => [ $_->{schema_name} ], name => $_->{table_name} } } values %$source ],
      [ map { { in => [ $_->{schema_name} ], name => $_->{table_name} } } values %$target ],
    );

    DBIO::PostgreSQL::Diff::CaseOnly->refuse(
      'DROP TABLE takes its rows.',
      map {
        my ($old, $new) = @$_;
        my $schema = $old->{in}[0];
        {
          kind     => 'table',
          database => "$schema.$old->{name}",
          target   => "$schema.$new->{name}",
          rename   => sprintf('ALTER TABLE %s RENAME TO %s;',
            quote_qualified($schema, $old->{name}), quote_ident($new->{name})),
        }
      } @pairs,
    );

=head1 DESCRIPTION

PostgreSQL reads a name written without quotes in lower case and a quoted one
exactly. A database built from statements that wrote C<UserAccount> bare
holds C<useraccount>; a statement that quotes it makes C<"UserAccount">. One
object is easily known under two spellings that way, and L<DBIO::PostgreSQL::Diff>
compares names as they are: it sees an object to create and another to drop.
For a table that is C<CREATE TABLE "UserAccount"> and C<DROP TABLE useraccount>,
and the rows are gone.

The rule that answers this stands here, once, for every operation class that
drops something the database cannot get back:

B<A name the target has and the database does not, and a name the database
has and the target does not, that are the same but for upper and lower case,
are not taken for two objects.> The diff does not know they are one, and it
does not know they are two, so it is refused -- C<refusing to diff: ...>, see
L<DBIO::PostgreSQL::Diff/WHAT IS REFUSED> -- and the message names both and
the C<RENAME> that makes the one into the other.

The diff does not write that C<RENAME> itself. Whether it should is an open
question of the family (core ADR 0060); until it is answered, the one who
knows whether the two are the same object decides.

Which classes ask, and which leave a pair of this kind to be dropped and
created, is listed under L<DBIO::PostgreSQL::Diff/WHAT IS REFUSED>.

=head1 METHODS

=head2 pairs

    my @pairs = DBIO::PostgreSQL::Diff::CaseOnly->pairs(\@source, \@target);

Finds the names that differ only in case. C<@source> is what the database
has and C<@target> what the target has, each entry a hashref with

=over 4

=item C<name> -- the name, as the catalog has it

=item C<in> -- an arrayref of the names that say where it is a name: the
schema of a table, the schema and the table of a column, nothing for a
schema. Two names are only ever compared within the same place, and the place
is compared exactly: C<auth.users> and C<Auth.users> are tables in two
schemas, and it is the schemas that differ in case.

=back

and whatever else the caller wants to find again. Returns a list of
C<[ $source_entry, $target_entry ]>, in the order of the places and, within
one, of the target's names.

A pair is an entry only the target has and an entry only the source has, in
the same place, whose names are equal in lower case. A name both sides have
never pairs: a target with C<users> and C<Users> beside a database with
C<users> has a second table to create, and a database with both beside a
target with C<Users> has one to drop. Where one name matches several on the
other side -- C<users> and C<USERS> to drop, C<Users> to create -- each is a
pair of its own.

The names are compared with Perl's C<lc>. That is wider than what the server
does to a bare name -- it lowers the letters A to Z and, in a database in
UTF-8, no other -- and errs to the side of asking.

=head2 refuse

    DBIO::PostgreSQL::Diff::CaseOnly->refuse($would, @found);

Dies with the refusal for C<@found>, and returns when there is none. Each
entry of C<@found> is a hashref:

=over 4

=item C<kind> -- what the object is, as a reader calls it: C<table>,
C<column>, C<schema>

=item C<database>, C<target> -- the object's full name on either side, as a
reader sees it, unquoted (C<public.useraccount>, C<public.UserAccount>)

=item C<rename> -- the statement that gives the object in the database the
target's name, its identifiers written by
L<DBIO::PostgreSQL::Util/quote_ident>

=back

C<$would> is a sentence saying what dropping the one in the database does: what
goes with it, or why the server does not take the statement. It is a line of
the message, or several with a newline between them.

All of C<@found> is in the one message, each with its C<rename>: a schema
declared in Mixed Case has more than one such table, and a refusal for each
would be a run for each.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL::Diff/WHAT IS REFUSED>

=item * L<DBIO::PostgreSQL::Util/quote_ident> - the server's rule for a name in a statement

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

package DBIO::MySQL::IndexType;
# ABSTRACT: MySQL/MariaDB CREATE INDEX class/type keyword grammar

use strict;
use warnings;

our $VERSION = '0.900004';



sub index_type_split {
  my ($token) = @_;
  return unless defined $token && length $token;
  my $u = uc $token;
  return ('', " USING $u") if $u eq 'BTREE' || $u eq 'HASH';
  return ("$u ", '')       if $u eq 'FULLTEXT' || $u eq 'SPATIAL';
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::IndexType - MySQL/MariaDB CREATE INDEX class/type keyword grammar

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Single source of truth for how a MySQL/MariaDB index type token renders in a
C<CREATE INDEX> statement. MySQL's grammar (8.4 Reference Manual) is

    CREATE [UNIQUE | FULLTEXT | SPATIAL] INDEX name [index_type]
        ON tbl (key_part,...) [index_option] ...

where C<index_type> is C<USING {BTREE | HASH}>. The four tokens are not rendered
alike, because the grammar does not treat them alike: C<BTREE> and C<HASH> are
index I<types> and render as a trailing C<USING> clause, while C<FULLTEXT> and
C<SPATIAL> are index I<classes> and render in front of C<INDEX> (the manual
states outright that "the index_type clause cannot be used for FULLTEXT INDEX
specifications", so C<USING FULLTEXT> is not a statement any server accepts).

This split is needed in two places -- desired-state DDL generation
(L<DBIO::MySQL::DDL>) and migration-diff rendering (L<DBIO::MySQL::Diff::Index>)
-- so it lives here once rather than being rendered twice.

=head1 METHODS

=head2 index_type_split

    my ($class_kw, $using_clause) = DBIO::MySQL::IndexType::index_type_split($token);

Maps a single index type token (C<BTREE>, C<HASH>, C<FULLTEXT>, C<SPATIAL>,
matched case-insensitively) to the two rendering fragments C<CREATE INDEX> needs:
a leading class keyword (with a trailing space, empty for the type tokens) and a
trailing C<USING> clause (with a leading space, empty for the class tokens).
Exactly one of the two is non-empty for a recognised token.

Returns the empty list for C<undef>, an empty string, or an unrecognised token.
The distinction is deliberately left to the caller: this function only I<maps>,
it never croaks. L<DBIO::MySQL::DDL> refuses an unrecognised C<using> value (and
the C<UNIQUE>/class combination) at DDL-generation time, naming the offending
index; L<DBIO::MySQL::Diff::Index>, whose token comes from the server's own
introspect, falls back to a plain C<CREATE INDEX>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

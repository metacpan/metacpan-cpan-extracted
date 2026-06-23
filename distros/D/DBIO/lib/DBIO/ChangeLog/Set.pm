package DBIO::ChangeLog::Set;
# ABSTRACT: ResultSource definition for the changelog_set table

use strict;
use warnings;

use DBIO::ChangeLog::Table;


sub source_definition {
  return DBIO::ChangeLog::Table->build_source({
    table   => 'changelog_set',
    columns => {
      id => {
        data_type         => 'integer',
        is_auto_increment => 1,
      },
      user_id => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
      },
      session_id => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
      },
      created_at => {
        data_type   => 'datetime',
        is_nullable => 0,
      },
    },
    column_order  => [qw/ id user_id session_id created_at /],
    primary_key   => ['id'],
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ChangeLog::Set - ResultSource definition for the changelog_set table

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Defines the result source for the C<changelog_set> table, which groups
individual changelog entries into logical changesets (typically one per
transaction via L<DBIO::ChangeLog::Schema/txn_do>).

Each changeset records an optional user and session identifier along
with a creation timestamp.

=head1 ATTRIBUTES

=head2 id

Integer primary key, auto-increment.

=head2 user_id

Optional C<varchar(255)>. Set from L<DBIO::ChangeLog::Schema/changelog_user>.

=head2 session_id

Optional C<varchar(255)>. Set from L<DBIO::ChangeLog::Schema/changelog_session>.

=head2 created_at

C<datetime>, NOT NULL. Automatically set when the changeset is created.

=head1 COLUMN DEFINITIONS

=head1 SEE ALSO

L<DBIO::ChangeLog>, L<DBIO::ChangeLog::Schema>, L<DBIO::ChangeLog::Table>

=cut

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

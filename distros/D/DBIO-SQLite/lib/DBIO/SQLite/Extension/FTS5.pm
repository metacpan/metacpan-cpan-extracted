package DBIO::SQLite::Extension::FTS5;
# ABSTRACT: The extension class of SQLite's FTS5 full-text module

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::SQLite::Extension::VirtualTable';


sub module          { 'fts5' }
sub shadow_suffixes { qw( _config _content _data _docsize _idx ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Extension::FTS5 - The extension class of SQLite's FTS5 full-text module

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  __PACKAGE__->sqlite_extensions('fts5');

=head1 DESCRIPTION

FTS5 keeps an index table C<docs> in the shadow tables C<docs_config>,
C<docs_content>, C<docs_data>, C<docs_docsize> and C<docs_idx>. They are the
module's and not the application's: this class claims them
(L<DBIO::SQLite::Extension::VirtualTable/claims>), found by the probe of
L<DBIO::SQLite::Extension::VirtualTable/inspect>. The declaration needs no
C<library> when FTS5 is compiled into libsqlite, as it is in DBD::SQLite's own.

=head1 METHODS

=head2 module

C<fts5>.

=head2 shadow_suffixes

C<_config>, C<_content>, C<_data>, C<_docsize>, C<_idx>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

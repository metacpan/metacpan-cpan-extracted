package DBIO::SQLite::Extension::VirtualTable;
# ABSTRACT: Base of the extension classes of SQLite modules that keep shadow tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::SQLite::Extension';

use DBIO::SQLite::Util qw(sql_tokens create_name_index token_identifier);


sub module          { die ref($_[0]) || $_[0], " must define module\n" }
sub shadow_suffixes { die ref($_[0]) || $_[0], " must define shadow_suffixes\n" }

sub name { $_[0]->module }


sub inspect {
  my ($class, $ctx) = @_;
  my $dbh    = $ctx->{dbh};
  my $module = $class->module;

  my $modules = eval { $dbh->selectcol_arrayref('PRAGMA module_list') };
  my $available = $modules ? ((grep { lc $_ eq $module } @$modules) ? 1 : 0) : undef;

  my $rows = $dbh->selectall_arrayref(q{
    SELECT name, sql FROM sqlite_master
    WHERE type = 'table' AND sql IS NOT NULL ORDER BY name
  });

  my @virtual = grep { $class->_uses_module($_->[1]) } @$rows;
  my @names   = map { $_->[0] } @virtual;

  return {
    module         => $module,
    available      => $available,
    virtual_tables => \@names,
    shadow_tables  => [ map { my $n = $_; map { $n . $_ } $class->shadow_suffixes } @names ],
  };
}

# CREATE VIRTUAL TABLE <name> USING <module>(...)
sub _uses_module {
  my ($class, $sql) = @_;
  my @tokens = sql_tokens($sql);
  my $at = create_name_index(\@tokens, 'VIRTUAL', 'TABLE');
  return 0 unless defined $at;

  my @rest = grep { $_->[0] ne 'skip' } @tokens[ $at + 1 .. $#tokens ];
  return 0 unless @rest >= 2 && $rest[0][0] eq 'word' && uc $rest[0][1] eq 'USING';
  return lc token_identifier(@{ $rest[1] }) eq $class->module ? 1 : 0;
}


sub claims {
  my ($class, $model, $ctx) = @_;
  my $state = ($ctx->{self} || {})->{state} || {};
  return [ map { $ctx->{driver}{table}->($_) } @{ $state->{shadow_tables} || [] } ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Extension::VirtualTable - Base of the extension classes of SQLite modules that keep shadow tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The shared rules of L<DBIO::SQLite::Extension::FTS5> and
L<DBIO::SQLite::Extension::RTree>: a module that is used with C<CREATE VIRTUAL
TABLE name USING module(...)> and stores itself in tables of the user's schema
named after the virtual table. A subclass names the L</module> and the
L</shadow_suffixes>; this class does the rest.

=head1 METHODS

=head2 module

The module name as it stands after C<USING>. Subclass.

=head2 shadow_suffixes

The suffixes of the module's shadow tables, C<_data> for C<docs_data>.
Subclass.

=head2 inspect

The probe (SQLite has no catalog of extensions, ADR 0066 section 1.3). Reads
C<< $ctx->{dbh} >> and answers

  { module         => 'fts5',
    available      => 1,                 # 1, 0, or undef when the library cannot say
    virtual_tables => [ 'docs', 'notes' ],
    shadow_tables  => [ 'docs_config', 'docs_content', ... ] }

C<available> is whether the running libsqlite has the module (C<PRAGMA
module_list>, libsqlite 3.30+; C<undef> before). C<virtual_tables> are the
tables of C<sqlite_master> whose C<CREATE VIRTUAL TABLE> statement uses the
module, read with the driver's lexer, so the word in a string or a comment
makes none. C<shadow_tables> is what L</claims> hands on: the names the module
gives the shadow tables of each of them, whether or not this libsqlite makes
every one of them (an FTS5 table without a content table has no C<_content>).

=head2 claims

C<< [ table => $name ] >> for each shadow table L</inspect> found. The deploy
removes them, with their columns, indexes, foreign keys and triggers, from both
models (L<DBIO::SQLite::Deploy/Claims and their cascade>). The virtual table
itself is the application's and stays. Claiming a table the model does not hold
-- libsqlite 3.37+ has already kept the shadow tables out of the model
(L<DBIO::SQLite::Introspect::Tables>), and the target model has no virtual
table at all -- changes nothing.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

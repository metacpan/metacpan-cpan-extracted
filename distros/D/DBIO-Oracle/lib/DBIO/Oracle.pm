package DBIO::Oracle;
# ABSTRACT: Oracle-specific schema management for DBIO
our $VERSION = '0.900000';
use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::Oracle::Storage');
  return $self->next::method(@info);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle - Oracle-specific schema management for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

    package MySchema;
    use DBIO Schema => -ora;

    # ... later
    my $schema = MySchema->connect($dsn, $user, $pass);
    # Storage is automatically set to DBIO::Oracle::Storage

=head1 DESCRIPTION

This class is a thin L<DBIO> subclass that automatically sets the storage
class to L<DBIO::Oracle::Storage> when a connection is established. The
C<-ora> shortcut (handled by L<DBIO::Shortcut::ora>) wires the Oracle storage
into your schema; the classic C<use base 'DBIO::Oracle'> / C<load_components>
forms remain supported. Load it into your schema instead of the base L<DBIO>
class when connecting to Oracle databases.

For Oracle versions prior to 9.0 that do not support ANSI join syntax, the
storage will automatically use L<DBIO::Oracle::Storage::WhereJoins> instead.

=head1 METHODS

=head2 connection

    $schema->connection($dsn, $user, $pass, \%attrs);

Sets the storage type to L<DBIO::Oracle::Storage> before delegating to the
parent C<connection> method.

=head1 SEE ALSO

=over

=item * L<DBIO::Shortcut::ora> - the C<use DBIO -ora> shortcut

=item * L<DBIO::Oracle::Storage> - Oracle storage implementation

=item * L<DBIO::Oracle::SQLMaker> - Oracle SQL dialect

=item * L<DBIO::Oracle::Storage::WhereJoins> - WHERE-clause join support for Oracle E<lt> 9

=item * L<DBIO> - Base ORM class

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

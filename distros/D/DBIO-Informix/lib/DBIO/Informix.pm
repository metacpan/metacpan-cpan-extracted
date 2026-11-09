package DBIO::Informix;
our $VERSION = '0.900004';


# ABSTRACT: Informix-specific schema management for DBIO

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::Informix::Storage');
  return $self->next::method(@info);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix - Informix-specific schema management for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    package MySchema;
    use DBIO Schema => -ix;

    # ... later ...
    my $schema = MySchema->connect($dsn, $user, $pass);
    # Storage is automatically set to DBIO::Informix::Storage

=head1 DESCRIPTION

This class is a thin L<DBIO> subclass that automatically sets the storage
class to L<DBIO::Informix::Storage> when a connection is established. Load
it into your schema instead of the base L<DBIO> class when connecting to
IBM Informix databases.

The C<-ix> shortcut (shipped as L<DBIO::Shortcut::ix>) is the recommended
way to pin the Informix storage on a schema class: C<use DBIO 'Schema', -ix>
sets the storage type to L<DBIO::Informix::Storage> at compile time.

=head1 METHODS

=head2 connection

    $schema->connection($dsn, $user, $pass, \%attrs);

Sets the storage type to L<DBIO::Informix::Storage> before delegating to
the parent C<connection> method.

=head1 SEE ALSO

=over

=item * L<DBIO::Informix::Storage> - Informix storage implementation

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

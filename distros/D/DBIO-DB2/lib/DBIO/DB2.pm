package DBIO::DB2;
our $VERSION = '0.900001';


# ABSTRACT: IBM DB2-specific schema management for DBIO

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::DB2::Storage');
  return $self->next::method(@info);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2 - IBM DB2-specific schema management for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

    package MySchema;
    use DBIO Schema => -db2;

    # ... elsewhere ...
    my $schema = MySchema->connect($dsn, $user, $pass);
    # Storage is automatically set to DBIO::DB2::Storage

=head1 DESCRIPTION

This class is a thin L<DBIO> subclass that automatically sets the storage
class to L<DBIO::DB2::Storage> when a connection is established. Load it
into your schema instead of the base L<DBIO> class when connecting to IBM
DB2 databases.

The C<-db2> shortcut shown above (see L<DBIO::Shortcut::db2>) pins the DB2
storage driver onto your schema class without naming the storage class by
hand. It is equivalent to loading this class as a schema component.

=head1 METHODS

=head2 connection

    $schema->connection($dsn, $user, $pass, \%attrs);

Sets the storage type to L<DBIO::DB2::Storage> before delegating to the
parent C<connection> method.

=head1 SEE ALSO

=over

=item * L<DBIO::DB2::Storage> - DB2 storage implementation

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

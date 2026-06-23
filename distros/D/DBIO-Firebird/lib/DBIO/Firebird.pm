package DBIO::Firebird;
# ABSTRACT: Firebird-specific schema management for DBIO
our $VERSION = '0.900000';

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::Firebird::Storage');
  return $self->next::method(@info);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird - Firebird-specific schema management for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

    package MySchema;
    use DBIO Schema => -fb;

    # elsewhere
    my $schema = MySchema->connect($dsn, $user, $pass);
    # Storage is automatically set to DBIO::Firebird::Storage

=head1 DESCRIPTION

This class is a thin L<DBIO> subclass that automatically sets the storage
class to L<DBIO::Firebird::Storage> when a connection is established. Load
it into your schema instead of the base L<DBIO> class when connecting to
Firebird databases.

The C<-fb> shortcut (see L<DBIO::Shortcut::fb>) is the convenient way to load
it: C<use DBIO 'Schema', -fb;> sets up the C<DBIO::Schema> base and pins the
storage type to L<DBIO::Firebird::Storage>.

=head1 METHODS

=head2 connection

    $schema->connection($dsn, $user, $pass, \%attrs);

Sets the storage type to L<DBIO::Firebird::Storage> before delegating to
the parent C<connection> method.

=head1 SEE ALSO

=over

=item * L<DBIO::Firebird::Storage> - Firebird storage via L<DBD::Firebird>

=item * L<DBIO::Firebird::Storage::InterBase> - InterBase storage variant

=item * L<DBIO::Firebird::Storage::Common> - Shared storage base class

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

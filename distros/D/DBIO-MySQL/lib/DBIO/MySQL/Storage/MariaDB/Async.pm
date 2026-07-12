package DBIO::MySQL::Storage::MariaDB::Async;
# ABSTRACT: future_io async adapter for MariaDB-DSN connections (DBD::MariaDB binding)

use strict;
use warnings;
use base 'DBIO::MySQL::Storage::Async';



sub _async_prepare_attrs { { mariadb_async => 1 } }


sub _conn_socket_fd { $_[1]->mariadb_sockfd }


sub _async_ready { $_[1]->mariadb_async_ready }


sub _async_result { $_[1]->mariadb_async_result }


sub _async_insertid { $_[1]->{mariadb_insertid} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Storage::MariaDB::Async - future_io async adapter for MariaDB-DSN connections (DBD::MariaDB binding)

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

The C<future_io> transport adapter resolved by convention for a C<dbi:MariaDB:>
connection. DBIO reblesses such a connection into L<DBIO::MySQL::Storage::MariaDB>
(the MariaDB driver storage subclass), so the core future_io resolver derives
C<ref($storage) . '::Async'> == C<DBIO::MySQL::Storage::MariaDB::Async> (ADR 0030
refinement, karr #65).

It reuses all the shared transport control flow from
L<DBIO::MySQL::Storage::Async> and overrides B<only> the five DBD-specific async
primitives, swapping DBD::mysql's binding for L<DBD::MariaDB>'s C<mariadb_*> one.
This exactly mirrors the sync split, where L<DBIO::MySQL::Storage::MariaDB>
overrides L<DBIO::MySQL::Storage> to read C<mariadb_insertid>: a C<dbi:MariaDB:>
future_io connection drives DBD::MariaDB's C<mariadb_async> binding, while a
C<dbi:mysql:> one drives DBD::mysql's C<async> binding, so whichever DBD the user
named in the DSN is the one used for async.

=head1 METHODS

=head2 _async_prepare_attrs

DBD::MariaDB arms an async query with C<< { mariadb_async => 1 } >>.

=head2 _conn_socket_fd

DBD::MariaDB exposes the connection socket fd as C<< $dbh->mariadb_sockfd >>.

=head2 _async_ready

DBD::MariaDB C<< $sth->mariadb_async_ready >>.

=head2 _async_result

DBD::MariaDB C<< $sth->mariadb_async_result >>.

=head2 _async_insertid

DBD::MariaDB per-statement C<< $sth->{mariadb_insertid} >>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

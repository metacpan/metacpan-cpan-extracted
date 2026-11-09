package DBIO::MySQL::Storage::MariaDB::Async;
# ABSTRACT: future_io async adapter resolved for the MariaDB storage class

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::MySQL::Storage::Async';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Storage::MariaDB::Async - future_io async adapter resolved for the MariaDB storage class

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The C<future_io> transport adapter resolved by convention for
L<DBIO::MySQL::Storage::MariaDB>: the core future_io resolver derives
C<ref($storage) . '::Async'> == C<DBIO::MySQL::Storage::MariaDB::Async> (ADR 0030
refinement). A connection lands in that storage class through a
C<dbi:MariaDB:> DSN, or through C<load_components('MySQL::MariaDB')> with any
DSN.

It is L<DBIO::MySQL::Storage::Async> under the name the convention asks for,
and adds nothing: the transport, the emulated LISTEN/NOTIFY
(L<DBIO::MySQL::Storage::Async/"LISTEN / NOTIFY (emulated)">) and its
C<listen> / C<notify> capabilities are all inherited.

This class does B<not> select the L<DBD::MariaDB> binding, although it used to
(this dist's ADR 0007). Which DBD's async binding a connection is driven
through -- C<mariadb_async>, C<mariadb_sockfd>, C<mariadb_async_ready>,
C<mariadb_async_result>, C<mariadb_insertid>, C<mariadb_auto_reconnect>, or
L<DBD::mysql>'s C<mysql_*> counterparts -- is decided per connection, by the
DBD its DSN names (L<DBIO::MySQL::Storage::Async/One dist, two DBD drivers>).
A choice made by class missed C<load_components('MySQL')> over a
C<dbi:MariaDB:> DSN, which never reaches this class, and was wrong here for
C<load_components('MySQL::MariaDB')> over a C<dbi:mysql:> DSN (ADR
0007 addendum 2026-10-04). An override of one of the DBD-specific primitives
in this class would bring that mistake back.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package DBIO::Firebird::Storage;
# ABSTRACT: Driver for the Firebird RDBMS via L<DBD::Firebird>

use strict;
use warnings;
use base qw/DBIO::Firebird::Storage::InterBase/;
use mro 'c3';

DBIO::Storage::DBI->register_driver('Firebird' => __PACKAGE__);

__PACKAGE__->datetime_parser_type('DBIO::Firebird::DateTime::Format');

sub dbio_deploy_class { 'DBIO::Firebird::Deploy' }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Storage - Driver for the Firebird RDBMS via L<DBD::Firebird>

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Storage driver for the Firebird RDBMS using L<DBD::Firebird>. DBD::Firebird is
closely modeled on L<DBD::InterBase>, so this is a subclass of
L<DBIO::Firebird::Storage::InterBase>: it inherits SQL dialect 3 forcing and the
C<connect_call_use_softcommit> / C<connect_call_datetime_setup> connect-calls,
and registers itself for the C<Firebird> DBD driver name.

=head1 SEE ALSO

=over

=item * L<DBIO::Firebird> - Firebird schema component

=item * L<DBIO::Firebird::Storage::Common> - Shared Firebird/InterBase logic

=item * L<DBIO::Firebird::Storage::InterBase> - InterBase driver

=item * L<DBIO::Storage::DBI> - Base DBI storage class

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

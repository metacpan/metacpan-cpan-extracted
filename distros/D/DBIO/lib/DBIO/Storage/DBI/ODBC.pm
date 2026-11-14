package DBIO::Storage::DBI::ODBC;
# ABSTRACT: Base class for ODBC drivers
use strict;
use warnings;

our $VERSION = '0.900005';

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

use DBIO::Util 'modver_gt_or_eq';
use namespace::clean;


# Whether or not we are connecting via the freetds ODBC driver
sub _using_freetds {
  my $self = shift;

  my $dsn = $self->_dbi_connect_info->[0];

  return 1 if (
    ( (! ref $dsn) and $dsn =~ /driver=FreeTDS/i)
      or
    ( ($self->_dbh_get_info('SQL_DRIVER_NAME')||'') =~ /tdsodbc/i )
  );

  return 0;
}


# Either returns the FreeTDS version via which we are connecting, 0 if can't
# be determined, or undef otherwise
sub _using_freetds_version {
  my $self = shift;
  return undef unless $self->_using_freetds;
  return $self->_dbh_get_info('SQL_DRIVER_VER') || 0;
}


sub _disable_odbc_array_ops {
  my $self = shift;
  my $dbh  = $self->_get_dbh;

  $DBD::ODBC::__DBIO_DISABLE_ARRAY_OPS_VIA__ ||= [ do {
    if( modver_gt_or_eq('DBD::ODBC', '1.35_01') ) {
      odbc_array_operations => 0;
    }
    elsif( modver_gt_or_eq('DBD::ODBC', '1.33_01') ) {
      odbc_disable_array_operations => 1;
    }
  }];

  if (my ($k, $v) = @$DBD::ODBC::__DBIO_DISABLE_ARRAY_OPS_VIA__) {
    $dbh->{$k} = $v;
  }
}


sub _connect_params_dsn {
  my $self = shift;
  $self->throw_exception(
    'Cannot build a DBD::ODBC DSN from connection parameters (dbname, host, '
  . 'port): DBD::ODBC connects through a data source name (dbi:ODBC:DSN=...) '
  . 'or a connection string naming the ODBC driver (dbi:ODBC:Driver=...;...), '
  . 'and connection parameters carry neither. Give the whole DSN instead -- '
  . 'as dsn, or as a dbname starting with dbi:ODBC: -- or use an AccessBroker '
  . 'that answers in DBI form ([ $dsn, $user, $password ]).'
  );
}


1;

# vim:sts=2 sw=2:

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::ODBC - Base class for ODBC drivers

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

The base of the ODBC storage classes of drivers that run over L<DBD::ODBC>
(L<DBIO::MSSQL::Storage::ODBC>, L<DBIO::Firebird::Storage::ODBC>): the ODBC
transport helpers above, and the refusal to build a DSN from connection
parameters. It is not a driver and does not find one: an ODBC connection does
not say which engine is behind it, so a schema declares its driver, and a
driver that runs over ODBC moves its storage into its own ODBC class in its
L<DBIO::Storage::DBI/_adapt_to_access_path> (ADR 0059, ADR 0067).
L<DBIO/driver_for> refuses an ODBC DSN for the same reason.

=head1 METHODS

=head2 _using_freetds

Return true when current connection appears to use FreeTDS.

=head2 _using_freetds_version

Return FreeTDS version string if available, C<0> if undetermined, or C<undef>
when FreeTDS is not in use.

=head2 _disable_odbc_array_ops

Disable array-operations behavior in DBD::ODBC using version-appropriate
driver attributes.

=head2 _connect_params_dsn

Refuses. The DSN seam of L<DBIO::Storage::DBI/_connect_params_dsn> (ADR 0057)
has no form to build for L<DBD::ODBC> out of C<dbname>, C<host> and C<port>:
DBD::ODBC connects through a data source name (C<dbi:ODBC:DSN=name>,
configured in F<odbc.ini>) or a connection string that names the ODBC driver
(C<dbi:ODBC:Driver={...};...>), whose keywords that driver defines -- and
connection parameters carry neither. Guessing one would connect somewhere
else, or not at all.

The error names the ways out: the whole DSN, as C<dsn> or as a C<dbname> that
starts with C<dbi:ODBC:> (L<DBIO::AccessBroker::Static> passes it on), or an
AccessBroker that answers in DBI form. An engine reached over ODBC whose
driver knows its ODBC connection string overrides this in its own ODBC
storage class.

=head1 METHODS

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

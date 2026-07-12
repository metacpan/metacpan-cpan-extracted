package DBIO::Storage::DBI::ODBC;
# ABSTRACT: Base class for ODBC drivers
use strict;
use warnings;
use base qw/DBIO::Storage::DBI/;
use mro 'c3';

use DBIO::Util 'modver_gt_or_eq';
use namespace::clean;


sub _rebless { shift->_determine_connector_driver('ODBC') }


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


1;

# vim:sts=2 sw=2:

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::ODBC - Base class for ODBC drivers

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

This class simply provides a mechanism for discovering and loading a sub-class
for a specific ODBC backend.  It should be transparent to the user.

=head1 METHODS

=head2 _rebless

Resolve and rebless into a backend-specific ODBC storage subclass.

=head2 _using_freetds

Return true when current connection appears to use FreeTDS.

=head2 _using_freetds_version

Return FreeTDS version string if available, C<0> if undetermined, or C<undef>
when FreeTDS is not in use.

=head2 _disable_odbc_array_ops

Disable array-operations behavior in DBD::ODBC using version-appropriate
driver attributes.

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

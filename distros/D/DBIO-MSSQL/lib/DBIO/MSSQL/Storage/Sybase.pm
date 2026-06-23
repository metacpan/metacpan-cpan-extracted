package DBIO::MSSQL::Storage::Sybase;
# ABSTRACT: Support for Microsoft SQL Server via DBD::Sybase

use strict;
use warnings;

use base qw/
  DBIO::Sybase::Storage
  DBIO::MSSQL::Storage
/;
use mro 'c3';

use DBIO::Carp;
use namespace::clean;


__PACKAGE__->datetime_parser_type(
  'DBIO::MSSQL::Storage::Sybase::DateTime::Format'
);

sub _rebless {
  my $self = shift;
  my $dbh  = $self->_get_dbh;

  return if ref $self ne __PACKAGE__;
  if (not $self->_use_typeless_placeholders) {
    carp_once <<'EOF' unless $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN};
Placeholders do not seem to be supported in your configuration of
DBD::Sybase/FreeTDS.

This means you are taking a large performance hit, as caching of prepared
statements is disabled.

Make sure to configure your server with "tds version" of 8.0 or 7.0 in
/etc/freetds/freetds.conf .

To turn off this warning, set the DBIO_MSSQL_FREETDS_LOWVER_NOWARN environment
variable.
EOF
    require
      DBIO::MSSQL::Storage::Sybase::NoBindVars;
    bless $self,
      'DBIO::MSSQL::Storage::Sybase::NoBindVars';
    $self->_rebless;
  }
}

sub _init {
  my $self = shift;

  $self->next::method(@_);

  # work around massively broken freetds versions after 0.82
  # - explicitly no scope_identity
  # - no sth caching
  #
  # warn about the fact as well, do not provide a mechanism to shut it up
  if ($self->_using_freetds and (my $ver = $self->_using_freetds_version||999) > 0.82) {
    carp_once(
      "Your DBD::Sybase was compiled against buggy FreeTDS version $ver. "
    . 'Statement caching does not work and will be disabled.'
    );

    $self->_identity_method('@@identity');
    $self->_no_scope_identity_query(1);
    $self->disable_sth_caching(1);
  }
}

# invoked only if DBD::Sybase is compiled against FreeTDS
sub _set_autocommit_stmt {
  my ($self, $on) = @_;

  return 'SET IMPLICIT_TRANSACTIONS ' . ($on ? 'OFF' : 'ON');
}

sub _get_server_version {
  my $self = shift;

  my $product_version = $self->_get_dbh->selectrow_hashref('master.dbo.xp_msver ProductVersion');

  if ((my $version = $product_version->{Character_Value}) =~ /^(\d+)\./) {
    return $version;
  }
  else {
    $self->throw_exception(
      "MSSQL Version Retrieval Failed, Your ProductVersion's Character_Value is missing or malformed!"
    );
  }
}


sub connect_call_datetime_setup {
  my $self = shift;
  my $dbh = $self->_get_dbh;

  if ($dbh->can('syb_date_fmt')) {
    # amazingly, this works with FreeTDS
    $dbh->syb_date_fmt('ISO_strict');
  }
  else{
    carp_once
      'Your DBD::Sybase is too old to support '
    . 'DBIO::InflateColumn::DateTime, please upgrade!';
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::Sybase - Support for Microsoft SQL Server via DBD::Sybase

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Storage driver for Microsoft SQL Server accessed via L<DBD::Sybase>
(including FreeTDS-based connections). Inherits from both
L<DBIO::Sybase::Storage> and L<DBIO::MSSQL::Storage>.

On connect, the driver checks whether your L<DBD::Sybase> build supports
placeholders. If not, the storage is reblessed to
C<DBIO::MSSQL::Storage::Sybase::NoBindVars>. FreeTDS versions above 0.82
have known statement-caching bugs; the driver detects these and disables
statement caching automatically.

=head1 METHODS

=head2 connect_call_datetime_setup

Used as:

  on_connect_call => 'datetime_setup'

In L<connect_info|DBIO::Storage::DBI/connect_info> to set:

  $dbh->syb_date_fmt('ISO_strict'); # output fmt: 2004-08-21T14:36:48.080Z

On connection for use with L<DBIO::InflateColumn::DateTime>

This works for both C<DATETIME> and C<SMALLDATETIME> columns, although
C<SMALLDATETIME> columns only have minute precision.

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL> - MSSQL schema component

=item * L<DBIO::MSSQL::Storage> - MSSQL storage base class

=item * L<DBIO::Sybase::Storage> - Sybase storage base class

=item * L<DBIO::Sybase::Storage::FreeTDS> - FreeTDS connection layer

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

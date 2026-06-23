package DBIO::Sybase::Storage;
# ABSTRACT: Base class for drivers using L<DBD::Sybase>

use strict;
use warnings;
use Try::Tiny;
use DBIO::Util 'old_mro';
use namespace::clean;

use base qw/DBIO::Storage::DBI/;
__PACKAGE__->register_driver('Sybase' => __PACKAGE__);

sub dbio_deploy_class { 'DBIO::Sybase::Deploy' }



sub _rebless {
  my $self = shift;

  my $dbtype;
  try {
    $dbtype = @{$self->_get_dbh->selectrow_arrayref(qq{sp_server_info \@attribute_id=1})}[2]
  } catch {
    $self->throw_exception("Unable to establish connection to determine database type: $_")
  };

  if ($dbtype) {
    $dbtype =~ s/\W/_/gi;

    # saner class name
    $dbtype = 'ASE' if $dbtype eq 'SQL_Server';

    my $subclass = __PACKAGE__ . "::$dbtype";
    if ($self->load_optional_class($subclass)) {
      bless $self, $subclass;
      $self->_rebless;
    }
  }
}

sub _init {
  # once the driver is determined see if we need to insert the DBD::Sybase w/ FreeTDS fixups
  # this is a dirty version of "instance role application", \o/ DO WANT Moo \o/
  my $self = shift;
  if (! $self->isa('DBIO::Sybase::Storage::FreeTDS') and $self->_using_freetds) {
    require DBIO::Sybase::Storage::FreeTDS;

    my @isa = @{mro::get_linear_isa(ref $self)};
    my $class = shift @isa; # this is our current ref

    my $trait_class = $class . '::FreeTDS';
    mro::set_mro ($trait_class, 'c3');
    no strict 'refs';
    @{"${trait_class}::ISA"} = ($class, 'DBIO::Sybase::Storage::FreeTDS', @isa);

    bless ($self, $trait_class);

    Class::C3->reinitialize() if old_mro();

    $self->_init(@_);
  }

  $self->next::method(@_);
}

sub _ping {
  my $self = shift;

  my $dbh = $self->_dbh or return 0;

  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;

  ( try { $dbh->do('select 1'); 1 } )
    ? 1
    : 0
  ;
}

sub _set_max_connect {
  my $self = shift;
  my $val  = shift // 256;

  my $dsn = $self->_dbi_connect_info->[0];

  return if ref($dsn) eq 'CODE';

  if ($dsn !~ /maxConnect=/) {
    $self->_dbi_connect_info->[0] = "$dsn;maxConnect=$val";
    my $connected = defined $self->_dbh;
    $self->disconnect;
    $self->ensure_connected if $connected;
  }
}

# Whether or not DBD::Sybase was compiled against FreeTDS. If false, it means
# the Sybase OpenClient libraries were used.
sub _using_freetds {
  my $self = shift;
  return ($self->_get_dbh->{syb_oc_version}||'') =~ /freetds/i;
}

# Either returns the FreeTDS version against which DBD::Sybase was compiled,
# 0 if can't be determined, or undef otherwise
sub _using_freetds_version {
  my $inf = shift->_get_dbh->{syb_oc_version};
  return undef unless ($inf||'') =~ /freetds/i;
  return $inf =~ /v([0-9\.]+)/ ? $1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage - Base class for drivers using L<DBD::Sybase>

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Base storage class and dispatcher for L<DBD::Sybase>-based connections.
On first use, this storage introspects the connected server type via
C<sp_server_info> and reblesses itself into the appropriate subclass:
L<DBIO::Sybase::Storage::ASE> for Sybase ASE, or falls back to subclasses
registered for other server types (such as L<DBIO::MSSQL::Storage::Sybase>
for Microsoft SQL Server).

If L<DBD::Sybase> was compiled against FreeTDS, the FreeTDS fixups from
L<DBIO::Sybase::Storage::FreeTDS> are mixed in automatically.

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase> - Sybase schema component

=item * L<DBIO::Sybase::Storage::ASE> - Sybase ASE storage

=item * L<DBIO::Sybase::Storage::FreeTDS> - FreeTDS connection layer

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

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

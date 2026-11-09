# ABSTRACT: One fixed set of connection parameters as an AccessBroker
package DBIO::AccessBroker::Static;

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::AccessBroker';

__PACKAGE__->mk_group_accessors('simple' => qw(
  host port dbname username password
));



sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);
  $self->host($args{host}) if exists $args{host};
  $self->port($args{port}) if exists $args{port};
  $self->dbname($args{dbname}) if exists $args{dbname};
  $self->username($args{username} // '');
  $self->password($args{password} // '');
  return $self;
}


sub connect_info_for {
  my ($self, $mode) = @_;
  $mode //= 'write';

  my %info = (
    host     => $self->host,
    port     => $self->port,
    dbname   => $self->dbname,
    user     => $self->username,
    password => $self->password,
  );

  return \%info;
}


sub needs_refresh { 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::AccessBroker::Static - One fixed set of connection parameters as an AccessBroker

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Static brokers keep a single set of connection details and are transaction-safe
by default. See L<DBIO::AccessBroker/TRANSACTION SAFETY>.

=head1 METHODS

=head2 new

    my $broker = DBIO::AccessBroker::Static->new(
      host     => 'localhost',
      port     => 5432,
      dbname   => 'myapp',
      username => 'myapp',
      password => 'secret',
    );

Stores one fixed set of connection details. C<host>, C<port> and C<dbname>
are kept only when given; C<username> and C<password> default to the empty
string. Each is readable (and writable) through the accessor of the same name.

=head2 connect_info_for

    my $info = $broker->connect_info_for;

Returns the stored details as a hashref C<< { host, port, dbname, user,
password } >> (note: the C<username> attribute is returned under the key
C<user>). The C<$mode> argument is accepted for back-compat and ignored.

These are connection parameters, not a DSN, and they name no driver. A
L<DBIO::Storage::DBI> builds the DSN from C<dbname>, C<host> and C<port> for
the driver its storage class belongs to, in the form that driver's DBD takes
(L<DBIO::Storage::DBI/_connect_params_dsn>, ADR 0057) --
C<dbi:Pg:dbname=myapp;host=localhost;port=5432> for a schema that loaded the
C<PostgreSQL> component -- and leaves out the parts not given. So the schema
must load its driver component: a storage that would learn its driver from the
DSN has nothing to build one for, and refuses the broker. A driver whose DBD
has no such form refuses too (ODBC); give it the whole DSN as C<dbname>
(C<< dbname => 'dbi:ODBC:DSN=myapp' >>), which is taken as the DSN -- with
C<host> and C<port> left out, since they cannot be put into it.

=head2 needs_refresh

Always false: static credentials never rotate.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

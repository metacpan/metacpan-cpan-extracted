# ABSTRACT: Single-DSN AccessBroker drop-in replacement
package DBIO::AccessBroker::Static;

use strict;
use warnings;
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

DBIO::AccessBroker::Static - Single-DSN AccessBroker drop-in replacement

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Static brokers keep a single set of connection details and are transaction-safe
by default. See L<DBIO::AccessBroker/TRANSACTION SAFETY>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

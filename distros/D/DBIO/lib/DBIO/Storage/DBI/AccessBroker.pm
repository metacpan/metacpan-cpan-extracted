package DBIO::Storage::DBI::AccessBroker;
# ABSTRACT: DBI-specific AccessBroker integration for DBIO storage

use strict;
use warnings;

use base 'DBIO::Storage';
use mro 'c3';

use Scalar::Util 'blessed';
use namespace::clean;


sub _is_access_broker_connect_info {
  my ($self, $info) = @_;

  return 0 unless ref $info eq 'ARRAY' && @$info == 1;
  return 0 unless blessed($info->[0]);

  return $info->[0]->isa('DBIO::AccessBroker');
}


sub _current_dbi_connect_info {
  my ($self, $mode) = @_;

  my $connect_info = $self->current_access_broker_connect_info($mode);
  return $connect_info if $connect_info;

  return $self->_dbi_connect_info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::AccessBroker - DBI-specific AccessBroker integration for DBIO storage

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Mixin for L<DBIO::Storage::DBI> that provides the DBI-level
L<DBIO::AccessBroker> integration: connect-info detection and
mode-based credential routing.

The abstract broker management API (C<set_access_broker>,
C<clear_access_broker>, C<current_access_broker_connect_info>,
C<_assert_transaction_safe_access_broker>) lives in
L<DBIO::Storage>.

=head2 _is_access_broker_connect_info

Returns true when the supplied connect_info looks like a broker-style
invocation: a single-element arrayref whose sole member is a blessed
L<DBIO::AccessBroker> instance.

=head2 _current_dbi_connect_info

Returns the connect info to use for the current connection attempt.
Defers to the attached broker (if any) for the requested mode;
falls back to the stored C<_dbi_connect_info> otherwise.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

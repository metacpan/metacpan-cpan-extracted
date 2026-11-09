package DBIO::Oracle::Storage::ConnectSetup;
# ABSTRACT: Oracle session NLS setup on connect

use strict;
use warnings;

our $VERSION = '0.900004';


# The seam: core runs _apply_connection_schema first on every new connection,
# the synchronous one (_run_connection_actions) and the pool connection
# (_run_pool_connect_actions) alike, before the user's on_connect_call and
# on_connect_do. Their own ALTER SESSION therefore wins over this default.
sub _apply_connection_schema {
  my $self = shift;
  $self->connect_call_datetime_setup;
  return $self->next::method(@_);
}

sub connect_call_datetime_setup {
  my $self = shift;
  my $date_format = $ENV{NLS_DATE_FORMAT} ||= 'YYYY-MM-DD HH24:MI:SS';
  my $timestamp_format = $ENV{NLS_TIMESTAMP_FORMAT} ||= 'YYYY-MM-DD HH24:MI:SS.FF';
  my $timestamp_tz_format = $ENV{NLS_TIMESTAMP_TZ_FORMAT} ||= 'YYYY-MM-DD HH24:MI:SS.FF TZHTZM';
  $self->_do_query("alter session set nls_date_format = '$date_format'");
  $self->_do_query("alter session set nls_timestamp_format = '$timestamp_format'");
  $self->_do_query("alter session set nls_timestamp_tz_format='$timestamp_tz_format'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Storage::ConnectSetup - Oracle session NLS setup on connect

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Sets the Oracle session NLS date/timestamp formats to ISO
(C<NLS_DATE_FORMAT> C<YYYY-MM-DD HH24:MI:SS>, C<NLS_TIMESTAMP_FORMAT>
C<YYYY-MM-DD HH24:MI:SS.FF>, C<NLS_TIMESTAMP_TZ_FORMAT>
C<YYYY-MM-DD HH24:MI:SS.FF TZHTZM>) on B<every> new connection of the driver,
the connections of an async pool included. Nothing has to be asked for: without
this a session reads dates and timestamps in the server's format
(C<19-OCT-26 04.15.31.601359 AM>), which neither the ISO strings of the
result classes nor L<DateTime::Format::Oracle> take. A format named in the
environment variable of the same name (C<NLS_DATE_FORMAT> ...) is used instead
of the ISO one. The format in use is also written to those variables when
they are not set: L<DateTime::Format::Oracle> parses with the format of the
environment, not of the session, and its own defaults are not ISO.

The call is still there as C<< on_connect_call =E<gt> 'datetime_setup' >>, for
applications that name it: it sets the same formats a second time, which is
harmless.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

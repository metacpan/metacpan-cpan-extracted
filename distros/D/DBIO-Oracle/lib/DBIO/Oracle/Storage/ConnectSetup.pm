package DBIO::Oracle::Storage::ConnectSetup;
# ABSTRACT: Oracle session NLS setup on connect

use strict;
use warnings;




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

version 0.900000

=head1 DESCRIPTION

Sets Oracle session NLS date/timestamp formats on connect. Used as:

    on_connect_call => 'datetime_setup'

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package DBIO::MSSQL::Storage::Sybase::DateTime::Format;
# ABSTRACT: DateTime parser for MSSQL via DBD::Sybase

use strict;
use warnings;

our $VERSION = '0.900007';

use base 'DBIO::Storage::DateTimeFormat';

# Asymmetric: DBD::Sybase with syb_date_fmt('ISO_strict') emits ISO on read,
# but MSSQL wants a plain datetime literal on write, in the form YYYYMMDD
# (no dashes): the dashed form is read by the DATEFORMAT of the session. No preferred_format_class:
# DateTime::Format::MSSQL is mdy-based and does not round-trip with ISO_strict.
__PACKAGE__->datetime_parse_pattern('%Y-%m-%dT%H:%M:%S.%3NZ');
__PACKAGE__->datetime_format_pattern('%Y%m%d %H:%M:%S.%3N');
# A date column comes back through the same ISO_strict conversion, as a
# datetime at midnight (2026-10-25T00:00:00.000Z); written as YYYYMMDD.
__PACKAGE__->date_parse_pattern('%Y-%m-%dT%H:%M:%S.%3NZ');
__PACKAGE__->date_format_pattern('%Y%m%d');

# datetime2, datetimeoffset and time: what DBD::Sybase hands over depends on the
# TDS version FreeTDS speaks (measured, MSSQL 2022, FreeTDS 1.3.17):
#   TDS 7.0 - 7.2  the server sends the new types as text, in full:
#                  '2026-10-25 13:14:15.1234567',
#                  '2026-10-05 13:14:15.1234567 +02:00', '13:14:15.1234567'
#   TDS 7.3, 7.4   the client library converts them to its datetime and
#                  syb_date_fmt('ISO_strict') writes that: milliseconds only,
#                  a datetimeoffset as the UTC instant ('2026-10-05T11:14:15.123Z',
#                  the offset is gone), a time with a day that is not the time's
#                  ('2026-10-05T13:14:15.123Z')
# The parsers take both; the second form loses what the client library dropped
# before the string reached Perl. Writing is the form of the ODBC class: it does
# not depend on how the value is read.
use DBIO::MSSQL::Storage::DateTime::Format;
my $ODBC = 'DBIO::MSSQL::Storage::DateTime::Format';

sub parse_datetime2      { shift; $ODBC->parse_datetime2(@_) }
sub format_datetime2     { shift; $ODBC->format_datetime2(@_) }
sub parse_datetimeoffset { shift; $ODBC->parse_datetimeoffset(@_) }
sub format_datetimeoffset { shift; $ODBC->format_datetimeoffset(@_) }
sub format_time          { shift; $ODBC->format_time(@_) }

# the date in front of a time is the client library's filler, not the time's
sub parse_time {
  my ($class, $value) = @_;
  $value =~ s/\A\s*\d{4}-\d\d-\d\d[ T]// if defined $value;
  $value =~ s/Z\s*\z// if defined $value;
  return $ODBC->parse_time($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::Sybase::DateTime::Format - DateTime parser for MSSQL via DBD::Sybase

=head1 VERSION

version 0.900007

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

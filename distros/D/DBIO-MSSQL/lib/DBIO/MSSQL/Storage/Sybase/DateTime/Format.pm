package DBIO::MSSQL::Storage::Sybase::DateTime::Format;
# ABSTRACT: DateTime parser for MSSQL via DBD::Sybase

use strict;
use warnings;

use base 'DBIO::Storage::DateTimeFormat';

# Asymmetric: DBD::Sybase with syb_date_fmt('ISO_strict') emits ISO on read,
# but MSSQL wants a plain datetime literal on write. No preferred_format_class:
# DateTime::Format::MSSQL is mdy-based and does not round-trip with ISO_strict.
__PACKAGE__->datetime_parse_pattern('%Y-%m-%dT%H:%M:%S.%3NZ');
__PACKAGE__->datetime_format_pattern('%Y-%m-%d %H:%M:%S.%3N'); # %F %T

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::Sybase::DateTime::Format - DateTime parser for MSSQL via DBD::Sybase

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

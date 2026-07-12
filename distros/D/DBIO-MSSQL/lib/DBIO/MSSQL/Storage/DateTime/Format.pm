package DBIO::MSSQL::Storage::DateTime::Format;
# ABSTRACT: DateTime parser for MSSQL datetime and smalldatetime columns

use strict;
use warnings;

use base 'DBIO::Storage::DateTimeFormat';

# MSSQL adds a third channel beyond the base datetime/date: smalldatetime
# (minute precision, no fractional seconds). Core's InflateColumn::DateTime
# routes it to parse_smalldatetime/format_smalldatetime when the parser
# ->can() them, otherwise falls back to parse_datetime/format_datetime.
__PACKAGE__->mk_group_accessors('inherited' => qw/
  smalldatetime_parse_pattern smalldatetime_format_pattern
/);

__PACKAGE__->datetime_parse_pattern('%Y-%m-%d %H:%M:%S.%3N');   # %F %T
__PACKAGE__->datetime_format_pattern('%Y-%m-%d %H:%M:%S.%3N');
__PACKAGE__->smalldatetime_parse_pattern('%Y-%m-%d %H:%M:%S');
__PACKAGE__->smalldatetime_format_pattern('%Y-%m-%d %H:%M:%S');


sub parse_smalldatetime {
  my ($class, $value) = @_;

  return $class->_strptime_for(smalldatetime_parse => 'smalldatetime_parse_pattern')
    ->parse_datetime($value);
}


sub format_smalldatetime {
  my ($class, $dt) = @_;

  return $class->_strptime_for(smalldatetime_format => 'smalldatetime_format_pattern')
    ->format_datetime($dt);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::DateTime::Format - DateTime parser for MSSQL datetime and smalldatetime columns

=head1 VERSION

version 0.900001

=head1 METHODS

=head2 parse_smalldatetime

  my $dt = $class->parse_smalldatetime($string);

Parses a C<smalldatetime> string (minute precision) into a L<DateTime>.

=head2 format_smalldatetime

  my $string = $class->format_smalldatetime($dt);

Formats a L<DateTime> for a C<smalldatetime> column.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

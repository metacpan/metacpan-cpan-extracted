package DBIO::MSSQL::Storage::DateTime::Format;
# ABSTRACT: DateTime parser for MSSQL date, time, datetime, smalldatetime, datetime2 and datetimeoffset columns

use strict;
use warnings;

our $VERSION = '0.900007';

use base 'DBIO::Storage::DateTimeFormat';

# MSSQL adds a third channel beyond the base datetime/date: smalldatetime
# (minute precision, no fractional seconds). Core's InflateColumn::DateTime
# routes it to parse_smalldatetime/format_smalldatetime when the parser
# ->can() them, otherwise falls back to parse_datetime/format_datetime.
__PACKAGE__->mk_group_accessors('inherited' => qw/
  smalldatetime_parse_pattern smalldatetime_format_pattern
/);

# Reading is what the DBD hands over (YYYY-MM-DD hh:mm:ss.mmm). Writing is
# YYYYMMDD hh:mm:ss[.mmm]: the dashed form of a datetime/smalldatetime literal
# is read by the DATEFORMAT of the session (SET LANGUAGE German/French is dmy:
# 2026-10-05 became 2026-05-10, 2026-10-25 failed with Msg 242), the form
# without dashes is read the same under every language.
__PACKAGE__->datetime_parse_pattern('%Y-%m-%d %H:%M:%S.%3N');   # %F %T
__PACKAGE__->datetime_format_pattern('%Y%m%d %H:%M:%S.%3N');
# date: DBD::ODBC hands over YYYY-MM-DD. Written as YYYYMMDD like the others,
# so no setting of the session can touch the day and month of a date.
__PACKAGE__->date_parse_pattern('%Y-%m-%d');
__PACKAGE__->date_format_pattern('%Y%m%d');
__PACKAGE__->smalldatetime_parse_pattern('%Y-%m-%d %H:%M:%S');
__PACKAGE__->smalldatetime_format_pattern('%Y%m%d %H:%M:%S');


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

# datetime2, datetimeoffset and time have a channel of their own (core's
# InflateColumn::DateTime routes datetime2(7) to parse_datetime2, datetimeoffset(7)
# to parse_datetimeoffset, time(7) to parse_time). They are read and written by
# hand, not by a strptime pattern: the server gives a fraction of as many digits
# as the scale of the column (none for time(0)), and a pattern with a fixed
# count of digits would refuse the rest.
#
# Writing is language independent: YYYYMMDD without dashes, the offset as
# +HH:MM after a blank, a time as HH:MM:SS.fffffff. Seven fractional digits are
# what the types take at most; the server rounds to the scale of the column.

# $dt => 'YYYYMMDD hh:mm:ss.fffffff'
sub _wall_clock {
  my ($class, $dt) = @_;
  return sprintf('%04d%02d%02d %02d:%02d:%02d.%07d',
    $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second,
    int($dt->nanosecond / 100));
}

# fraction digits as nanoseconds
sub _frac_ns {
  my ($class, $frac) = @_;
  return defined $frac ? substr($frac . '000000000', 0, 9) + 0 : 0;
}

# 'YYYY-MM-DD hh:mm:ss[.f]' (DBD::ODBC) or with a T (DBD::Sybase from TDS 7.3)
my $DATETIME_RE = qr/(\d{4})-(\d\d)-(\d\d)[ T](\d\d):(\d\d):(\d\d)(?:\.(\d{1,9}))?/;


sub parse_datetime2 {
  my ($class, $value) = @_;

  my @m = defined $value ? $value =~ /\A\s*$DATETIME_RE Z?\s*\z/xi : ()
    or die "Unreadable datetime2 value\n";

  require DateTime;
  return DateTime->new(
    year => $m[0], month => $m[1], day => $m[2],
    hour => $m[3], minute => $m[4], second => $m[5],
    nanosecond => $class->_frac_ns($m[6]),
  );
}


sub format_datetime2 {
  my ($class, $dt) = @_;
  return $class->_wall_clock($dt);
}


sub parse_datetimeoffset {
  my ($class, $value) = @_;

  my @m = defined $value
    ? $value =~ /\A\s*$DATETIME_RE\s*(?:(Z)|([+-])(\d\d):?(\d\d))?\s*\z/i : ()
    or die "Unreadable datetimeoffset value\n";

  my $zone = defined $m[7] ? 'UTC'
           : defined $m[8] ? sprintf('%s%02d%02d', @m[8..10])
           : 'UTC';

  require DateTime;
  return DateTime->new(
    year => $m[0], month => $m[1], day => $m[2],
    hour => $m[3], minute => $m[4], second => $m[5],
    nanosecond => $class->_frac_ns($m[6]),
    time_zone => $zone,
  );
}


sub format_datetimeoffset {
  my ($class, $dt) = @_;

  my $off = $dt->offset;
  my $sign = $off < 0 ? '-' : '+';
  $off = abs $off;

  return $class->_wall_clock($dt)
    . sprintf(' %s%02d:%02d', $sign, int($off / 3600), int(($off % 3600) / 60));
}


sub parse_time {
  my ($class, $value) = @_;

  my @m = defined $value ? $value =~ /\A\s*(\d\d):(\d\d):(\d\d)(?:\.(\d{1,9}))?\s*\z/ : ()
    or die "Unreadable time value\n";

  require DateTime;
  return DateTime->new(
    year => 1970, month => 1, day => 1,
    hour => $m[0], minute => $m[1], second => $m[2],
    nanosecond => $class->_frac_ns($m[3]),
  );
}


sub format_time {
  my ($class, $dt) = @_;
  return sprintf('%02d:%02d:%02d.%07d', $dt->hour, $dt->minute, $dt->second,
    int($dt->nanosecond / 100));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::DateTime::Format - DateTime parser for MSSQL date, time, datetime, smalldatetime, datetime2 and datetimeoffset columns

=head1 VERSION

version 0.900007

=head1 METHODS

=head2 parse_smalldatetime

  my $dt = $class->parse_smalldatetime($string);

Parses a C<smalldatetime> string (minute precision) into a L<DateTime>.

=head2 format_smalldatetime

  my $string = $class->format_smalldatetime($dt);

Formats a L<DateTime> for a C<smalldatetime> column.

=head2 parse_datetime2

  my $dt = $class->parse_datetime2('2026-10-25 13:14:15.1234567');

Parses a C<datetime2> string with up to seven fractional digits into a
floating L<DateTime>; nothing below the fraction is lost.

=head2 format_datetime2

  my $string = $class->format_datetime2($dt);   # 20261025 13:14:15.1234567

Formats a L<DateTime> for a C<datetime2> column with seven fractional digits,
in the form that no C<DATEFORMAT> or language of the session changes.

=head2 parse_datetimeoffset

  my $dt = $class->parse_datetimeoffset('2026-10-05 13:14:15.1234567 +02:00');

Parses a C<datetimeoffset> string into a L<DateTime> that carries the offset
(a fixed-offset time zone). A value that comes with C<Z> (DBD::Sybase from TDS
7.3 hands the instant over in UTC) has the offset +00:00.

=head2 format_datetimeoffset

  my $string = $class->format_datetimeoffset($dt);   # 20261005 15:14:15.1234567 +02:00

Formats a L<DateTime> for a C<datetimeoffset> column: the wall clock of the
value in its own time zone and the offset it has at that instant (a value in an
Olson zone writes the offset of that moment). A floating value is written as
+00:00.

=head2 parse_time

  my $dt = $class->parse_time('13:14:15.1234567');

Parses a C<time> string with up to seven fractional digits (or none, for
C<time(0)>). The date of the result is 1970-01-01.

=head2 format_time

  my $string = $class->format_time($dt);   # 13:14:15.1234567

Formats the time of day of a L<DateTime> with seven fractional digits.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

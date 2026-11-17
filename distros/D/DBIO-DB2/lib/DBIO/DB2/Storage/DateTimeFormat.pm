package DBIO::DB2::Storage::DateTimeFormat;
# ABSTRACT: Db2 datetime parser with a working time of day

use strict;
use warnings;

our $VERSION = '0.900007';

use base 'DateTime::Format::DB2';


sub parse_time {
  my ($class, $value) = @_;

  my ($h, $m, $s, $frac) = defined $value
    ? $value =~ /^\s*(\d\d):(\d\d):(\d\d)(?:\.(\d+))?\s*\z/
    : ()
    or die "Unreadable time of day '" . (defined $value ? $value : 'NULL') . "'\n";

  return DateTime->new(
    year => 1970, month => 1, day => 1,
    hour => $h, minute => $m, second => $s,
    nanosecond => defined $frac ? substr($frac . '0' x 9, 0, 9) + 0 : 0,
    time_zone => 'floating',
  );
}

sub format_time {
  my ($class, $dt) = @_;
  return sprintf '%02d:%02d:%02d', $dt->hour, $dt->minute, $dt->second;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Storage::DateTimeFormat - Db2 datetime parser with a working time of day

=head1 VERSION

version 0.900007

=head1 DESCRIPTION

The datetime parser of L<DBIO::DB2::Storage>. It is L<DateTime::Format::DB2>
with C<parse_time> and C<format_time> of its own: C<parse_time> of
L<DateTime::Format::DB2> 0.06 dies on every value ("year is a required
parameter"), so a C<time> column with C<inflate_datetime> could not be read.

=head1 METHODS

=head2 parse_time

Reads C<HH:MM:SS>, as L<DBD::DB2> returns a C<TIME>, with an optional fraction.
The L<DateTime> is floating and stands on 1970-01-01, the day
L<DBIO::InflateColumn::DateTime> gives every time of day.

=head2 format_time

Writes C<HH:MM:SS>, the form Db2 takes for a C<TIME> in every locale. The date
and the fraction of the L<DateTime> are not written.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Date::Format::ISO8601;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-22'; # DATE
our $DIST = 'Date-Format-ISO8601'; # DIST
our $VERSION = '0.010'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
     gmtime_to_iso8601_date
     gmtime_to_iso8601_time
     gmtime_to_iso8601_datetime

     localtime_to_iso8601_date
     localtime_to_iso8601_time
     localtime_to_iso8601_datetime
);

sub _format {
    my $local_or_gm = shift;
    my $which = shift;
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $timestamp = shift;

    my $tz = $opts->{tz}; $tz = ($local_or_gm eq 'gm' ? 'Z':'') unless defined $tz;

    my ($sec, $min, $hour, $day, $mon, $year) =
        $local_or_gm eq 'local' ? localtime($timestamp) : gmtime($timestamp);
    $year+=1900; $mon++;
    my $sec_frac = $timestamp - int($timestamp);

    my $s_date = '';
    my $s_time = '';

    if ($which eq 'date' || $which eq 'datetime') {
        my $date_sep = $opts->{date_sep}; $date_sep = '-' unless defined $date_sep;
        $s_date = sprintf "%04d%s%02d%s%02d", $year, $date_sep, $mon, $date_sep, $day;
    }

    if ($which eq 'time' || $which eq 'datetime') {
        my $time_sep = $opts->{time_sep}; $time_sep = ':' unless defined $time_sep;
        $s_time = sprintf "%02d%s%02d%s%02d", $hour, $time_sep, $min, $time_sep, $sec;
        if ($sec_frac &&
                !defined($opts->{second_precision}) ||
                 $opts->{second_precision}) {
            my $s_secfrac;
            if (!defined($opts->{second_precision})) {
                $s_secfrac = sprintf("%s", $sec_frac);
            } else {
                $s_secfrac = sprintf("%.$opts->{second_precision}f",
                                     $sec_frac);
            }
            $s_time .= substr($s_secfrac, 1); # remove the "0" part
        }
        $s_time .= $tz;
    }

    if ($which eq 'date') {
        return $s_date;
    } elsif ($which eq 'time') {
        return $s_time;
    } elsif ($which eq 'datetime') {
        return $s_date . 'T' . $s_time;
    } else {
        die "BUG: Unknown which '$which'"; # shouldn't happen
    }
}

sub gmtime_to_iso8601_date        { _format('gm'   , 'date'    , @_) }
sub gmtime_to_iso8601_time        { _format('gm'   , 'time'    , @_) }
sub gmtime_to_iso8601_datetime    { _format('gm'   , 'datetime', @_) }
sub localtime_to_iso8601_date     { _format('local', 'date'    , @_) }
sub localtime_to_iso8601_time     { _format('local', 'time'    , @_) }
sub localtime_to_iso8601_datetime { _format('local', 'datetime', @_) }

1;
# ABSTRACT: Format date (Unix timestamp/epoch) as ISO8601 date/time string

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Format::ISO8601 - Format date (Unix timestamp/epoch) as ISO8601 date/time string

=head1 VERSION

This document describes version 0.010 of Date::Format::ISO8601 (from Perl distribution Date-Format-ISO8601), released on 2020-10-22.

=head1 SYNOPSIS

 use Date::Format::ISO8601 qw(
     gmtime_to_iso8601_date
     gmtime_to_iso8601_time
     gmtime_to_iso8601_datetime

     localtime_to_iso8601_date
     localtime_to_iso8601_time
     localtime_to_iso8601_datetime
 );

 my $timestamp      = 1529780523    ; # Sat Jun 23 19:02:03 2018 GMT
 my $timestamp_frac = 1529780523.456; # Sat Jun 23 19:02:03 2018 GMT

Assuming local timezone is UTC+7.

Formatting dates:

 say gmtime_to_iso8601_date   ($timestamp);   # => 2018-06-23
 say localtime_to_iso8601_date($timestamp);   # => 2018-06-24

Formatting times:

 say gmtime_to_iso8601_time   ($timestamp);            # => 19:02:03Z
 say gmtime_to_iso8601_time   ({tz=>''}, $timestamp);  # => 19:02:03
 say gmtime_to_iso8601_time   ({second_precision=>3}, $timestamp_frac);
                                                       # => 19:02:03.456Z
 say localtime_to_iso8601_time($timestamp);            # => 00:02:03
 say localtime_to_iso8601_time({tz=>'+07:00'}, $timestamp);
                                                       # => 00:02:03+07:00

Formatting date+time:

 say gmtime_to_iso8601_datetime   ($timestamp);        # => 2018-06-23T19:02:03Z
 say gmtime_to_iso8601_datetime   ({tz=>''}, $timestamp);
                                                       # => 2018-06-23T19:02:03
 say gmtime_to_iso8601_datetime   ({second_precision=>3}, $timestamp_frac);
                                                       # => 2018-06-23T19:02:03.456Z
 say localtime_to_iso8601_datetime($timestamp);        # => 2018-06-24T00:02:03
 say localtime_to_iso8601_datetime({tz=>'+07:00'}, $timestamp);
                                                       # => 2018-06-24T00:02:03+07:00

=head1 DESCRIPTION

This module formats Unix timestamps (epochs) as ISO8601 date/time strings. It is
a lightweight alternative to L<DateTime::Format::ISO8601::Format> and
L<DateTime::Format::ISO8601>.

=head1 FUNCTIONS

=head2 gmtime_to_iso8601_date

Usage:

 my $str = gmtime_to_iso8601_date([ \%opts, ] $timestamp);

Options:

=over

=item * tz

String. Will be appended after the time portion.

=item * date_sep

String. Default is colon (C<->).

=item * time_sep

String. Default is colon (C<:>).

=item * second_precision

Integer. Number of digits for fractional second. Default is undef (precision as
needed).

=back

=head2 gmtime_to_iso8601_time

See Synopsis and L</gmtime_to_iso8601_date> for syntax and options.

=head2 gmtime_to_iso8601_datetime

See Synopsis and L</gmtime_to_iso8601_date> for syntax and options.

=head2 localtime_to_iso8601_date

See Synopsis and L</gmtime_to_iso8601_date> for syntax and options.

=head2 localtime_to_iso8601_time

See Synopsis and L</gmtime_to_iso8601_date> for syntax and options.

=head2 localtime_to_iso8601_datetime

See Synopsis and L</gmtime_to_iso8601_date> for syntax and options.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Date-Format-ISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Date-Format-ISO8601>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Date-Format-ISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DateTime::Format::ISO8601::Format>

L<DateTime::Format::ISO8601>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

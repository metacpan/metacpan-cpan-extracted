package App::TimelogTxt::Utils;

use warnings;
use strict;

use POSIX qw(strftime);
use Time::Local;

our $VERSION = '0.22';

my $LAX_DATE_RE  = qr<[0-9]{4}[-/](?:0[1-9]|1[0-2])[-/](?:0[1-9]|[12][0-9]|3[01])>;
my $TIME_RE      = qr<(?:[01][0-9]|2[0-3]):[0-5][0-9]:[0-6][0-9]>;

my $DATE_FMT     = '%Y-%m-%d';
my $DATETIME_FMT = "$DATE_FMT %H:%M:%S";
my $ONE_DAY      = 86400;
my $TODAY        = 'today';
my $YESTERDAY    = 'yesterday';
my @DAYS         = qw/sunday monday tuesday wednesday thursday friday saturday/;

sub TODAY    { return $TODAY; }
sub STOP_CMD { return 'stop'; }

sub parse_event_line
{
    my ($line) = @_;
    my ( $stamp, $time, $task ) = $line =~ m<\A
        ( $LAX_DATE_RE ) \s ( $TIME_RE )
        \s+(.*)          # the log entry
    \Z>x;
    die "Not a valid event line.\n" unless $stamp;
    return ( $stamp, $time, $task );
}

sub fmt_time
{
    my ( $time ) = @_;
    return strftime( $DATETIME_FMT, localtime $time );
}

sub fmt_date
{
    my ( $time ) = @_;
    return strftime( $DATE_FMT, localtime $time );
}

sub is_today
{
    my ($day) = @_;
    return (!$day or $day eq $TODAY or $day eq today_stamp());
}

sub is_stop_cmd
{
    my ($task) = @_;
    return $task eq STOP_CMD();
}

sub has_project
{
    my ($task) = @_;
    return scalar( $task =~ /(?: |\A)\+\w+/ );
}

sub today_stamp
{
    return App::TimelogTxt::Utils::fmt_date( time );
}

sub day_end
{
    my ( $stamp ) = @_;
    return unless defined $stamp;
    return App::TimelogTxt::Utils::fmt_date( stamp_to_localtime( $stamp ) + $ONE_DAY );
}

sub stamp_to_localtime
{
    my ( $stamp ) = @_;
    return unless is_datestamp( $stamp );
    my @date = split /-/, $stamp;
    return unless @date == 3;
    $date[0] -= 1900;
    --$date[1];
    return timelocal( 59, 59, 23, reverse @date );
}

sub prev_stamp
{
    my ($stamp) = @_;
    my $epoch = stamp_to_localtime( $stamp ) - 12 * 3600; # noon today
    return fmt_date( $epoch - 86400 ); # noon yesterday
}

sub day_stamp
{
    my ( $day ) = @_;
    return today_stamp() if is_today( $day );

    # Parse the string to generate a reasonable guess for the day.
    return canonical_datestamp( $day ) if is_datestamp( $day );

    $day = lc $day;
    return unless grep { $day eq $_ } $YESTERDAY, @DAYS;

    my $now   = time;
    my $delta = 0;
    if( $day eq $YESTERDAY )
    {
        $delta = 1;
    }
    else
    {
        my $index = day_num_from_name( $day );
        return if $index < 0;
        my $wday = ( localtime $now )[6];
        $delta = $wday - $index;
        $delta += 7 if $delta < 1;
    }
    return fmt_date( $now - $ONE_DAY * $delta );
}

sub day_num_from_name
{
    my ($day) = @_;
    $day = lc $day;
    my $index = 0;
    foreach my $try ( @DAYS )
    {
        return $index if $try eq $day;
        ++$index;
    }
    return -1;
}

sub is_datestamp
{
    my ($stamp) = @_;
    return scalar ($stamp =~ m/\A$LAX_DATE_RE\z/);
}

sub canonical_datestamp
{
    my ($stamp) = @_;
    $stamp =~ tr{/}{-};
    return $stamp;
}

1;
__END__

=head1 NAME

App::TimelogTxt::Utils - Utility functions for the App::TimelogTxt modules.

=head1 VERSION

This document describes App::TimelogTxt::Utils version 0.22

=head1 SYNOPSIS

    use App::TimelogTxt::Utils;

    my $t = App::TimelogTxt::Utils::stamp_to_localtime( $stamp );
    my $estamp = App::TimelogTxt::Utils::day_end( $stamp );

=head1 DESCRIPTION

This module collects a set of utility functions and constants into one place to
avoid duplication in multiple modules or odd dependency loops. No effort has
been made to have these utility functions be particularly useful to code
outside this application.

=head1 INTERFACE

=head2 canonical_datestamp( $stamp )

Given a datestamp-like string that has '/' instead of '-' as separators,
convert to standard datestamp form: YYYY-MM-DD.

=head2 day_end( $stamp )

Given a properly formatted datestamp, find the next datestamp after the one
supplied.

=head2 day_num_from_name( $day_name )

Given a day name in English, return the day number (0-6).

=head2 day_stamp( $day_str )

Return a properly formatted datestamp for the supplied string. The C<$day_str>
argument may be any one of the following:

=over 4

=item The empty string or 'today'

Datestamp for today.

=item 'yesterday'

Datestamp for yesterday.

=item 'monday', 'tuesday', etc.

Datestamp for the most recent day named. For example, if today is Wednesday
and the string 'tuesday' is supplied, yesterday's datestamp is returned.

=item A datestamp

The supplied datestamp is returned.

=back

=head2 prev_stamp( $stamp )

Return a date stamp for the day before the date represented by C<$stamp>.

=head2 fmt_date( $time )

Return a properly formatted datestamp for the day corresponding to C<$time>
in the local timezone.

=head2 fmt_time( $time )

Return a properly formatted datestamp plus time corresponding to C<$time>
in the local timezone.

=head2 is_datestamp( $stamp )

Returns C<true> if C<$stamp> is a properly formatted datestamp.

=head2 is_today( $day_str )

Returns C<true> if C<$day_str> is either 'today' or the empty string.

=head2 is_stop_cmd( $task )

Returns C<true> if the supplied C<$task> is equal to the C<STOP_CMD> constant.

=head2 has_project( $task )

Returns C<true> if the supplied C<$task> has a project entry.

=head2 parse_event_line( $line )

Parse the supplied string into the datestamp, time, and the rest of the line,
if the string represents a proper event line.

=head2 stamp_to_localtime( $stamp )

Convert the datestamp to the last second of the day specified by C<$stamp> in
the local timezone.

=head2 STOP_CMD()

This constant returns the string 'stop' used throughout the system as to
represent the command that stops timing.

=head2 TODAY()

This constant returns the string 'today' used throughout the system to
represent today.

=head2 today_stamp()

Return the datestamp for today.

=head1 CONFIGURATION AND ENVIRONMENT

App::TimelogTxt::Utils requires no configuration files or environment variables.

=head1 DEPENDENCIES

POSIX, Time::Local.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< gwadej@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, G. Wade Johnson C<< gwadej@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


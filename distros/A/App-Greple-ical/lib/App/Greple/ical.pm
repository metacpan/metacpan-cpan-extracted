=encoding utf-8

=head1 NAME

ical - Module to support Apple macOS Calendar data

=head1 SYNOPSIS

greple -Mical [ options ]

    --simple  print data in one line
    --detail  print one line data with description if available

=head1 SAMPLES

greple -Mical PATTERN

greple -Mical --simple PATTERN

greple -Mical --detail PATTERN

=head1 DESCRIPTION

This module searches Apple macOS Calendar data.

Recent versions of macOS store calendar data in a SQLite database
(F<Calendar.sqlitedb> under F<~/Library/Group Containers/group.com.apple.calendar>),
instead of individual C<.ics> files which older versions used.  This
module reads the database with the B<sqlite3> command and converts
each event to a C<VEVENT>-like paragraph, which is then searched by
B<greple> in paragraph mode:

     BEGIN:VEVENT
     DTSTART:20260903T163000
     DTEND:20260903T190000
     SUMMARY:映画：ローマの休日
     LOCATION:Theater X
     END:VEVENT

Used without options, matched events are printed in the above format.

With B<--simple> option, summarize content in single line:

     2026/09/03 16:30-19:00 映画：ローマの休日 @[Theater X]

With B<--detail> option, print summarized line with description data
if it is attached.  The result is sorted.

=head1 REQUIREMENTS

The B<sqlite3> command is required (standard on macOS).

The terminal application needs the B<Full Disk Access> privilege to
read the calendar database.  If you get an "Operation not permitted"
error, add your terminal application in: System Settings ->
Privacy & Security -> Full Disk Access, and restart the terminal.

=head1 TIPS

Use C<-dfn> option to observe the command running status.

Use C<-ds> option to see statistics information.

=head1 SEE ALSO

RFC2445

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2017-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::ical;

our $VERSION = '1.00';

use v5.14;
use warnings;
use Carp;
use Exporter 'import';

use App::Greple::Common qw(FILELABEL);

our @EXPORT = qw(&print_simple &print_detail &print_desc &ical_data);

##
## Convert Calendar.sqlitedb to VEVENT-like paragraphs.
## Dates in the database are in Core Data epoch (seconds since
## 2001-01-01 UTC); 978307200 is the offset to Unix epoch.
##
my $SQL = <<'END';
SELECT 'BEGIN:VEVENT' || char(10)
    || 'DTSTART:' || strftime(CASE WHEN i.all_day THEN '%Y%m%d' ELSE '%Y%m%dT%H%M%S' END,
                              i.start_date + 978307200, 'unixepoch', 'localtime') || char(10)
    || CASE WHEN i.end_date IS NOT NULL
            THEN 'DTEND:' || strftime(CASE WHEN i.all_day THEN '%Y%m%d' ELSE '%Y%m%dT%H%M%S' END,
                                      i.end_date + 978307200, 'unixepoch', 'localtime') || char(10)
            ELSE '' END
    || 'SUMMARY:' || replace(i.summary, char(10), ' ') || char(10)
    || CASE WHEN loc.title IS NOT NULL
            THEN 'LOCATION:' || replace(loc.title, char(10), ' ') || char(10)
            ELSE '' END
    || CASE WHEN i.description IS NOT NULL
            THEN 'DESCRIPTION:' || replace(i.description, char(10), '\n') || char(10)
            ELSE '' END
    || 'END:VEVENT' || char(10)
FROM CalendarItem i
LEFT JOIN Location loc ON i.location_id = loc.ROWID
WHERE i.summary IS NOT NULL AND i.start_date IS NOT NULL
ORDER BY i.start_date
END

##
## Input filter function.  Called with FILELABEL parameter, and
## responsible to replace STDIN by the filtered stream (see
## App::Greple::Filter).
##
sub ical_data {
    my %arg = @_;
    my $file = $arg{&FILELABEL} // croak "no filename";
    my $pid = open(STDIN, '-|') // croak "process fork failed";
    if ($pid == 0) {
	exec 'sqlite3', '-noheader', $file, $SQL or die "sqlite3: $!\n";
    }
    $pid;
}

sub print_detail {
    $_ = &print_simple . &print_desc . "\n";
    s/\n(?=.)/\r/sg;
    $_;
}

sub print_simple {
    s/\r//g;
    my $s = '';
    my(@s, @e);
    if (@s = /^DTSTART.*(\d{4})(\d\d)(\d\d)(?:T(\d\d)(\d\d))?/m) {
	$s .= "$1/$2/$3";
	$s .= " $4:$5" if defined $4;
    }
    if (@e = /^DTEND.*(\d{4})(\d\d)(\d\d)(?:T(\d\d)(\d\d))?/m) {
	if ($s[0]eq$e[0] and $s[1]eq$e[1] and $s[2]+1>=$e[2]) {
	    $s .= "-$4:$5" if defined $4;
	} else {
	    $s .= "-";
	    $s .= "$1/" if $s[0] ne $e[0];
	    $s .= "$2/$3";
	}
    }
    $s .= " ";
    /^SUMMARY:(.*)/m and $s .= $1;
    /^DESCRIPTION:/m and $s .= "*";
    /^LOCATION:(.*)/m and $s .= " \@[$1]";
    $s .= "\n";
    $s;
}

sub print_desc {
    my $desc = '';
    if (/^(DESCRIPTION.*\n(?:\s.*\n)*)/m) {
	$desc = $1;
	for ($desc) {
	    s/\n\s+//g;
	    s/\\n/\n/g;
	    s/\\\\t/\t/g;
	    s/\\,/,/g;
	}
    }
    $desc;
}

1;

__DATA__

option default \
	--chdir '~/Library/Group\ Containers/group.com.apple.calendar' \
	--glob Calendar.sqlitedb \
	--if &ical_data \
	-p

option --simple \
	--print print_simple

option --detail \
	--print print_detail --pf 'sort | tr \\015 \\012'

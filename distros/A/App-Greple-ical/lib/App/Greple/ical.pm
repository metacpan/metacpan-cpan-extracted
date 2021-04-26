=head1 NAME

ical - Module to support Apple OS X Calendar data

=head1 SYNOPSIS

greple -Mical [ options ]

    --simple  print data in on line
    --detail  print one line data with descrition if available

Exported functions

    &print_ical_simple
    &print_ical_desc
    &print_ical_detail

=head1 SAMPLES

greple -Mical ...

greple -Mical --simple ...

greple -Mical --detail ...

greple -Mical --all --print print_desc ...

=head1 DESCRIPTION

Used without options, it will search all OS X Calendar files under
user's home directory.

With B<--simple> option, summarize content in single line.
Output is not sorted.

With B<--detail> option, pirnt summrized line with description data if
it is attached.  The result is sorted.

Sample:

     BEGIN:VEVENT
     UID:19970901T130000Z-123401@host.com
     DTSTAMP:19970901T1300Z
     DTSTART:19970903T163000Z
     DTEND:19970903T190000Z
     SUMMARY:Annual Employee Review
     CLASS:PRIVATE
     CATEGORIES:BUSINESS,HUMAN RESOURCES
     END:VEVENT

=head1 TIPS

Use C<-dfn> option to observe the command running status.

Use C<-ds> option to see statistics information such as how many files
were searched.

=head1 SEE ALSO

RFC2445

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2017-2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::ical;

our $VERSION = '0.01';

use v5.14;
use warnings;
use Carp;
use Exporter 'import';

our @EXPORT = qw(&print_simple &print_detail &print_desc);

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
	--chdir=~/Library/Calendars/*.caldav/*.calendar/Events \
	--glob=*.ics

option --simple \
	--all --print print_simple

option --detail \
	--all --print print_detail --pf 'sort | tr \\015 \\012'

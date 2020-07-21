# Calendar::Schedule - Manage calendar schedules
# (c) 2002-2020 Vlado Keselj http://web.cs.dal.ca/~vlado vlado@dnlp.ca
#               and contributing authors
#
# Some parts are updated with Starfish during development, such as the version
# number: <? read_starfish_conf !>

package Calendar::Schedule;
use strict;
require Exporter;
use POSIX;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS); # Exporter vars
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( parse_time ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(new);

#<?echo "our \$VERSION = '$Meta->{version}';"!>#+
our $VERSION = '1.13';#-

use vars qw($Version $Revision);
$Version = $VERSION;
($Revision = substr(q$Revision: 239 $, 10)) =~ s/\s+$//;

# non-exported package globals
use vars qw( $REweekday3 $REmonth3 $RE1st );
$RE1st = qr/first|second|third|fourth|fifth|last|1st|2nd|3rd|4th|5th/;
$REweekday3 = qr/Mon|Tue|Wed|Thu|Fri|Sat|Sun/;
$REmonth3 = qr/Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec/;

=head1 NAME

Calendar::Schedule - manage calendar schedules

=head1 SYNOPSIS

    use Calendar::Schedule qw/:all/;

    my $TTable = Calendar::Schedule->new();

    # manually adding an entry
    $TTable->add_entry('2003-09-09 Tue 18-20 Some meeting');
                              
    # reading entries from a file
    $TTable->add_entries_from("$ENV{'HOME'}/.calendar");

    # producing entries in HTML tables, one table per week
    $TTable->set_first_week('now');
    print "<p>\n" . $TTable->generate_table();
    print "<p>\n" . $TTable->generate_table();
    print "<p>\n" . $TTable->generate_table();

    # for more examples, see EXAMPLES section

The file .calendar may look like this:

  # comments can start with #
  * lines starting with * are treated as general todo entries ...
  # empty lines are acceptable and ignored:

  Mon 9:00-10:00 this is a weekly entry
  Mon 13-14 a biweekly entry :biweekly :start Mar 8, 2004
  Mon,Wed,Fri 15:30-16:30 several-days-a-week entry
  Wed :biweekly garbage collection

  2004-03-06 Sat 14-16 fixed entry. The week day is redundant, but may\
        help to detect errors (error will be reported if a wrong\
        weekday is entered).  BTW, an entry can go for several lines as\
        long as there is a backslash at the end of each line.

  May   6      birthday (yearly entry)

  # more examples in "Example entries" section

=head1 DESCRIPTION

The module is created with a purpose to provide functionality for handling a
personal calendar schedule in a transparent and simple way.  The calendar
data is assumed to be kept in a plain file in a format easy to edit and
understand.  It was inspired by the C<calendar> program on older Unix-like
systems, which used C<~/.calendar> file to produce entries for each day
and send them in the morning by email.

Inspired by the C<~/.calendar> file, the format for recording scheduled
events is very simple, mostly contained in one line of text.

The module currently supports generation of HTML weekly tables with visual
representation of scheduled events.  The generated table is generated in
a simple HTML table, with a use of C<colspan> and C<rolspan> attributes to
represent overlapping events in parallel in the table.

=head2 Planned Future Work

In the development of the recording format for the event, there is an attempt
to model the data representation of the iCalendar standard (RFC2445).
Examples of the iCalendar fields are: DTSTART, DTEND, SUMMARY,
RRULE (e.g. RRULE:FREQ=WEEKLY, RRULE:FREQ=WEEKLY;INTERVAL=2 for
biweekly, RRULE:FREQ=WEEKLY;UNTIL=20040408 ) etc.
More examples:

  RRULE:FREQ=MONTHLY;BYDAY=TU;BYSETPOS=3

Every third Tuesday in a month.

=head1 EXAMPLES

First example:

    use Calendar::Schedule qw/:all/;

    my $TTable = Calendar::Schedule->new();

    # manually adding an entry
    $TTable->add_entry('2003-09-09 Tue 18-20 Some meeting');
                              
    # reading entries from a file
    $TTable->add_entries_from("$ENV{'HOME'}/.calendar");

    # producing entries in HTML tables
    $TTable->set_first_week('2003-12-15');
    print "<p>\n" . $TTable->generate_table();
    print "<p>\n" . $TTable->generate_table();
    print "<p>\n" . $TTable->generate_table();

Example with generating a weekly schedule (example2):

    use Calendar::Schedule;
    $TTable = Calendar::Schedule->new();
    $TTable->{'ColLabel'} = "%A";
    $TTable->add_entries(<<EOT
    Mon 15:30-16:30 Teaching (CSCI 3136)
    Tue 10-11:30 Teaching (ECMM 6014)
    Wed 13:30-14:30 DNLP
    Wed 15:30-16:30 Teaching (CSCI 3136) :until Apr 8, 2005
    Thu 10-11:30 Teaching (ECMM 6014)
    Thu 16-17 WIFL
    Fri 14:30-15:30 MALNIS
    Fri 15:30-16:30 Teaching (CSCI 3136)
    EOT
    );
    print "<p>\n" . $TTable->generate_table();

This will produce the following HTML code (if run before Apr 8, 2005):

=for html
<p>
<table width=100% border=2 cellspacing=1 cellpadding=1>
<tr>
<td valign=top>&nbsp;</td>
<th>Monday</th>
<th>Tuesday</th>
<th>Wednesday</th>
<th>Thursday</th>
<th>Friday</th>
<th>Saturday</th>
<th>Sunday</th>
</tr>
<tr><td>08:00</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>10:00</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow>Teaching (ECMM 6014)</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow>Teaching (ECMM 6014)</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>11:30</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>12:00</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>13:30</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow>DNLP</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>14:30</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow>MALNIS</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>15:30</td>
<td align=center bgcolor=yellow rowspan=2>Teaching (CSCI 3136)</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow rowspan=2>Teaching (CSCI 3136) </td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow rowspan=2>Teaching (CSCI 3136)</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>16:00</td>
<!-- continue -->
<td align=center>&nbsp;</td>
<!-- continue -->
<td align=center bgcolor=yellow rowspan=2>WIFL</td>
<!-- continue -->
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>16:30</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<!-- continue -->
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>17:00</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
</table>

=head2 Conflicts

Time conflicts are handled by producing several columns in a table for
the same day.  For example, the following code (example3):

    use Calendar::Schedule;
    $TTable = Calendar::Schedule->new();
    $TTable->{'ColLabel'} = "%A";
    $TTable->add_entries(<<EOT

    Mon 15:30-16:30 Teaching (CSCI 3136)
    Tue 10-11:30 Teaching (ECMM 6014)
    Wed 13:30-14:30 DNLP
    Wed 15:30-16:30 Teaching (CSCI 3136) :until Apr 8, 2005
    Thu 10-11:30 Teaching (ECMM 6014)
    Thu 16-17 WIFL
    Fri 14:30-15:30 MALNIS
    Fri 15:30-16:30 Teaching (CSCI 3136)
    Wed 15-16 meeting
    Wed 15:30-18 another meeting

    EOT
    );
    print "<p>\n" . $TTable->generate_table();

will produce the following table (if run before Apr 8, 2005):

=for html
<p>
<table width=100% border=2 cellspacing=1 cellpadding=1>
<tr>
<td valign=top>&nbsp;</td>
<th>Monday</th>
<th>Tuesday</th>
<th colspan=3>Wednesday</th>
<th>Thursday</th>
<th>Friday</th>
<th>Saturday</th>
<th>Sunday</th>
</tr>
<tr><td>08:00</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>10:00</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow>Teaching (ECMM 6014)</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow>Teaching (ECMM 6014)</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>11:30</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>12:00</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>13:30</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow>DNLP</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>14:30</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow rowspan=2>MALNIS</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>15:00</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow rowspan=2>meeting</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<!-- continue -->
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>15:30</td>
<td align=center bgcolor=yellow rowspan=2>Teaching (CSCI 3136)</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow rowspan=2>Teaching (CSCI 3136) </td>
<!-- continue -->
<td align=center bgcolor=yellow rowspan=4>another meeting</td>
<td align=center>&nbsp;</td>
<td align=center bgcolor=yellow rowspan=2>Teaching (CSCI 3136)</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>16:00</td>
<!-- continue -->
<td align=center>&nbsp;</td>
<!-- continue -->
<td align=center>&nbsp;</td>
<!-- continue -->
<td align=center bgcolor=yellow rowspan=2>WIFL</td>
<!-- continue -->
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>16:30</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<!-- continue -->
<!-- continue -->
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>17:00</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<!-- continue -->
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
<tr><td>18:00</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
<td align=center>&nbsp;</td>
</tr>
</table>

=head2 Example entries

These are some example of simple entries that are accepted by the
C<add_entry> function or C<add_entries_from> for reading from a file.
Each entry is on a line by itself, but it can be continued in the the
following lines by using \ (backslash) at the end of the current line.
The time specificantions are generally at the beginning of an entry.
Examples:

  # comments can start with #
  # empty lines are acceptable and ignored:

  Mon 9:00-10:00 this is a weekly entry
  Mon 13-14 a biweekly entry :biweekly :start Mar 8, 2004
  Mon,Wed,Fri 15:30-16:30 several-days-a-week entry
  Wed :biweekly garbage collection

  2004-03-06 Sat 14-16 fixed entry. The week day is redundant, but may\
        help to detect errors (error will be reported if a wrong\
        weekday is entered).  BTW, an entry can go for several lines as\
        long as there is a backslash at the end of each line.

  May 6  an example birthday (yearly entry)

  Wed 13:30-14:30 DNLP
  Wed 15:30-16:30 Teaching (CSCI 3136) :until Apr 8, 2005
  Wed 3-4:30pm meeting
  Mon,Wed,Fri 10:30-11:30 meeting (product team)
  Mon 13-14 seminar :biweekly :start Mar 8, 2004
  Tue,Thu 10-11:30 Class (ECMM 6014) Location: MCCAIN ARTS&SS 2022 :until Apr 8, 2004
  1st,3rd Tue 10-11 meeting
  1st,last Mon,Fri 4-5 meeting (4 meetings every month)
  4th Thu 11:30-13 meeting (fcm)

=head1 STATE VARIABLES

=over 4

=item StartTime

Used as C<$obj-E<gt>{StartTime}>. Start time for various uses.
Usually it is the the beginning of the first interesting week.

=item DefaultRowLabels

Used as C<$obj-E<gt>{DefaultRowLabels}>.  Includes pre-defined labels
for rows of the generated HTML schedule tables.  The pre-defined value
is:

    $self->{DefaultRowLabels} = [qw( 08:00 12:00 17:00 )];

=back

=head1 METHODS

=over 4

=item new()

Creates a new C<Calendar::Schedule> object and returns it.

=cut
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { VEvents => [ ],
               Entries => [ ],
	       Entries1 => [ ],
	       DayEntries => [ ],
	       ToDo => [ ],
               RowLabels => [ ],
               StartTime => 0,
	       ColLabel => "%A<br>%Y-%m-%d",
	       ShowDays => 'all', # 'workdays'
             };

  bless($self, $class);

  $self->{'DefaultRowLabels'} = [ qw( 08:00 12:00 17:00 ) ];
  $self->{'RowLabels'} = [ @{ $self->{'DefaultRowLabels'} } ];

  $self->set_first_week(time);

  return $self;
}

=item set_first_week(time)

sets start time at the last Monday before given date.  It is used in generate_table.
Examples:

 $TTable = Calendar::Schedule->new();
 $TTable->set_first_week('now');
 $TTable->set_first_week('2016-02-19');

See parse_time for examples for specifying time.
=cut
sub set_first_week {
    my $self = shift;
    my $arg = shift;
    my $starttime = &parse_time($arg);

    $self->{'StartTime'} = $self->{'ContextTime'} =
	&find_week_start($starttime);
}

=item set_ColLabel(pattern)

sets C<strftime> pattern for column (day) labels.  The default pattern
is "C<%AE<lt>brE<gt>%Y-%m-%d>", which produces labels like:

  Friday
  2003-12-19

In order to have just a weekday name, use "C<%A>".

=cut
sub set_ColLabel {
    my $self = shift;
    my $arg = shift;
    $self->{'ColLabel'} = $arg;
}

sub find_week_start {
    my $starttime = shift;

    while ((localtime($starttime))[6] != 1)
    { $starttime -= 86400 }

    while ((localtime($starttime))[2] != 0)
    { $starttime -= 3600 }

    while ((localtime($starttime))[1] != 0)
    { $starttime -= 60 }

    while ((localtime($starttime))[0] != 0)
    { $starttime -- }

    return $starttime;
}

=item parse_time(time_specification[,prefix])

Parses time specification and returns the calendar time (see mktime in
Perl).  The functions dies if the time cannot be completely recognized.
If prefix is set to true (1), then only a prefix of the string can be
a time specification.  If prefix is set to 1, then in an array context
it will return a 2-element list: the calendar time and the
remainder of the string.  Format examples:

  2004-03-17
  now
  Mar 8, 2004
  1-Jul-2005

=cut
#mktime(sec,min,hour,mday,mon,year,wday=0,yday=0,isdst=0)
#mon,wday,yday start with 0,wday starts with Sun,year starts with 1900
# usually set last 3 to -1
#  ('YYYY-MM-DD') now
sub parse_time {
    my $time = shift;
    my $prefix = shift;
    my $endrex = ( $prefix ? qr// : qr/\s*$/ );
    my ($ret, $ret2);
    my $monrex = $REmonth3;
    if    ($time =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d?):(\d\d)$endrex/)
    { $ret = mktime(0,$5,$4,$3,$2-1,$1-1900,-1,-1,-1) }
    elsif ($time =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$endrex/)
    { $ret = mktime(0,0,0,$3,$2-1,$1-1900,-1,-1,-1) }
    elsif ($time =~ /^(\d\d)-(\d\d)-(\d\d\d\d)$endrex/)
    { $ret = mktime(0,0,0,$1,$2-1,$3-1900,-1,-1,-1) }
    elsif ($time =~ /^(\d?\d)-($monrex)-(\d\d\d\d)\b$endrex/)
    { $ret = mktime(0,0,0,$1,&month_to_digits($2),$3-1900,-1,-1,-1) }
    elsif ($time =~ /^($monrex) (\d?\d), (\d\d\d\d)\b$endrex/)
    { $ret = mktime(0,0,0,$2,&month_to_digits($1),$3-1900,-1,-1,-1) }
    elsif ($time =~ /^\d+$endrex/) { $ret = $time }
    elsif ($time =~/^now\b$endrex/) { $ret = time }
    else { use Carp; confess "cannot parse time:($time)" }
    $ret2 = $';
    return wantarray ? ($ret, $ret2) : $ret;
}

=item add_entries_from(file_name)

Adds entries from a file.  See method add_entries and add_entry for format explanation.

=cut
sub add_entries_from {
    my $self = shift;
    my $fname = shift;
    return $self->add_entries(scalar(_getfile($fname)));
}

=item add_entries(list_of_entries)

Adds more entries.  Each entry may contain several entries separated
by a new-line, except if the line ends with \.
Empty lines and lines that start with \s*# are ignored.
See add_entry for further explanation of format.

=cut
sub add_entries {
    my $self = shift;
    while ($#_ > -1) {
	my $entries = shift;
	foreach my $en (split(/(?<!\\)\n/, $entries)) {
	    next if $en =~ /^\s*$/;
	    next if $en =~ /^\s*#/;
	    $en =~ s/\\\n/\n/g;
	    $self->add_entry($en);
	}
    }
}

=item add_entry(list_of_entries)

Adds more entries.  It is different from add_entries because this
method does not break entries on new-lines, although it does accept a
list of entries as arguments.

Examples:

  $TTable->add_entry('Mon 8-17', 'Labour Day');
  $TTable->add_entry('2003-09-09 Tue 18-20 Some meeting');

More format examples:

  Wed 3-4:30pm meeting
  Mon,Wed,Fri 15:30-16:30 meeting (product team)
  Mon 13-14 seminar :biweekly :start Mar 8, 2004
  Tue,Thu 10-11:30 Class (ECMM 6014) Location: MCCAIN ARTS&SS 2022 :until Apr 8, 2004
  1st,3rd Tue 10-11 meeting
  1st,last Mon,Fri 4-5 meeting (4 meetings every month)

More examples can be found in section "Example entries".

=cut
sub add_entry {
    my $self = shift;

    if ($#_ <= 1) {		# entry not structured, needs to be
				# parsed (string)		
	my $timeslot = shift;
	my $description;
	if ($#_ == 0) { $description = shift }
	else {
	    local $_ = $timeslot;
	    #2003-09-09 Tue 18-20
	    if (/^\d\d\d\d-\d\d-\d\d $REweekday3 \d\d?(:\d\d)?-\d\d?(:\d\d)?([ap]m)? /)
	    { $timeslot = $&; $description = $'; }
	    elsif (/^\d\d\d\d-\d\d-\d\d \d\d?(:\d\d)?-\d\d?(:\d\d)?([ap]m)? /)
	    { $timeslot = $&; $description = $'; }
	    #<? $CP.="Wed 3-4:30pm meeting\n" !>
	    elsif (/^$REweekday3(?:,$REweekday3)*\s+\d\d?(:\d\d)?-\d\d?(:\d\d)?([ap]m)? /)
	    { $timeslot = $&; $description = $'; }
	    #<? $CP.="3rd Tue 3-4:30pm meeting\n" !>
	    elsif (/^$RE1st(,$RE1st)*
                    \ $REweekday3(?:,$REweekday3)*\s+\d\d?(:\d\d)?-\d\d?(:\d\d)?([ap]m)?\ /x)
	    { $timeslot = $&; $description = $'; }
	    #iso8601 thanks to Mike Vasiljevs
	    elsif (/^(\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)-
                     (\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)?/x)
	    { $timeslot = $&; $description = $'; }
	    elsif (/^(\d\d\d\d-\d\d-\d\d) / ||
		   /^(\d?\d-\w\w\w-\d\d\d\d) /
		   )
	    {
		$timeslot = parse_time($1);
		$description = $';
		push @{ $self->{'DayEntries'}},
                     { date => $timeslot, description => $description };
		return;
	    }
	    elsif (/^\*\s*/) {
		push @{ $self->{'ToDo'}}, { desc=>$' };
		return;
	    }
	    #<? $CP.="Wed :biweekly garbage collection\n" !>
	    elsif (/^($REweekday3)\b\s*/) { $timeslot=$1; $description=$'; }
	    else { ($timeslot, $description) = parse_time($_, 1) }
	    $timeslot =~ s/\s+$//;
	}

	my ($starttime, $endtime);

	if ($timeslot =~ /^($REweekday3(?:,$REweekday3)*)\s+(\d\d?(?::\d\d)?)-(\d\d?(?::\d\d)?)((?:[ap]m)?)$/) {
	    my ($days,$stime,$etime,$ampm) = ($1, $2, $3, $4);
	    $stime .= $ampm; $etime .= $ampm;

	    my $rrule = 'FREQ=WEEKLY';
	    if ($description =~ /\s*:biweekly\b\s*/) {
		$description = "$` $'";
		$rrule .= ':INTERVAL=2';
	    }
	    if ($description =~ /\s*:until\s+/) {
		my $p1 = $`; my $p2 = $';
		my ($t, $p2n) = parse_time($p2, 1);
		$description = "$p1 $p2n";
		$rrule .= ";UNTIL=".$self->find_next_time("23:59", $t);
	    }
	    my $starttime = $self->{'StartTime'};
	    if ($description =~ /:start\s+/) {
		my $d1 = $`; my $d2 = $';
		($starttime, $d2) = parse_time($d2, 1);
		$description = "$d1$d2";
	    }
	    
	    foreach my $d (split(/,/, $days)) {
		my %vevent = ();
		$vevent{'RRULE'} = $rrule;
		$vevent{'DTSTART'} = $self->find_next_time("$d $stime", $starttime);
		$vevent{'DTEND'}   = $self->find_next_time("$d $etime", $starttime);
                while ($vevent{'DTEND'} < $vevent{'DTSTART'})
		{ $vevent{'DTEND'}   = $self->find_next_time("$d $etime", $vevent{'DTEND'}) }
		$vevent{'SUMMARY'} = $description;
		push @{ $self->{'VEvents'} }, \%vevent;
	    }
	    return;
	}
	# pattern 1:
	elsif ($timeslot =~ /^($RE1st(?:,$RE1st)*)\s+
	            ($REweekday3(?:,$REweekday3)*)\s+
	            (\d\d?(?::\d\d)?)-(\d\d?(?::\d\d)?)([ap]m)?$
	            /ix) {   # pattern 1:
	    my ($first,$days,$stime,$etime,$ampm) = ($1,$2,$3,$4,$5);
	    $stime .= $ampm; $etime .= $ampm;
	    # example: RRULE:FREQ=MONTHLY;BYDAY=+3TU
	    my $rrule = 'FREQ=MONTHLY'; my @first;
	    foreach my $f (split(/,/, $first)) {
		my $f1;
		if    ($f =~ /^first|1st$/)  { $f1 = '+1' }
		elsif ($f =~ /^second|2nd$/) { $f1 = '+2' }
		elsif ($f =~ /^third|3rd$/)  { $f1 = '+3' }
		elsif ($f =~ /^fourth|4th$/) { $f1 = '+4' }
		elsif ($f =~ /^fifth|5th$/)  { $f1 = '+5' }
		elsif ($f =~ /^last$/)       { $f1 = '-1' }
		else {die}
		push @first, $f1 unless grep {$f1 eq $_} @first;
	    }
	    my @days; $rrule.=';BYDAY=';
	    my $startime = $self->{'StartTime'}; my ($st,$et);
	    foreach my $d (split(/,/, $days)) {
		my $d1 = &weekday_to_WK($d);
		push @days, $d1 unless grep {$d1 eq $_} @days;
		for my $f (@first) {
		    $rrule.=',' unless $rrule =~ /=$/;
		    $rrule.="$f$d1";
		    my $t = $self->find_next_time("$d $stime", $starttime);
		    for (my $i=0;$i<=500;++$i,$t+=7*24*60*60) {
			if (is_week_in_month($f,$t) and
			    ($t<$st or $st==0)) {
			    $st = $t;
			    $et = $self->find_next_time("$d $etime", $st);
			}
		    }
		}
	    }
	    my %vevent = ();
	    $vevent{'RRULE'} = $rrule;
	    $vevent{'DTSTART'} = $st;
	    $vevent{'DTEND'}   = $et;
	    $vevent{'SUMMARY'} = $description;
	    push @{ $self->{'VEvents'} }, \%vevent;
	    return;
	} # end of pattern 1:
        # thanks to Mike Vasiljevs:
        # 25 may 2006, adding matching for iso8601 dates
        #
        elsif ($timeslot =~ /^(\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)-
                              (\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)$/x)	{
	    my ($hstart, $mstart, $sstart) = split(":", $2);
	    my ($hend, $mend, $send) = split(":", $4);
	    $starttime = parse_time("$1 $hstart:$mstart");
	    $endtime   = parse_time("$1 $hend:$mend");
	    ##correct is to use second date in endtime, but it may lead to time leaks!?
	    #$endtime   = parse_time("$3 $hend$mend");
	}
	elsif ($timeslot =~ /^($REweekday3(?:,$REweekday3)*)$/) {
	    my ($days) = ($1);

	    my $rrule = 'FREQ=WEEKLY';
	    if ($description =~ /\s*:biweekly\b\s*/) {
		$description = "$` $'";
		$rrule .= ':INTERVAL=2';
	    }
	    if ($description =~ /\s*:until\s+/) {
		my $p1 = $`; my $p2 = $';
		my ($t, $p2n) = parse_time($p2, 1);
		$description = "$p1 $p2n";
		$rrule .= ";UNTIL=".$self->find_next_time("23:59", $t);
	    }
	    my $starttime = $self->{'StartTime'};
	    if ($description =~ /:start\s+/) {
		my $d1 = $`; my $d2 = $';
		($starttime, $d2) = parse_time($d2, 1);
		$description = "$d1$d2";
	    }
	    
	    foreach my $d (split(/,/, $days)) {
		my %vevent = ();
		$vevent{'DTSTART'} = $self->find_next_time("$d 00:00", $starttime);
		# not DTEND signals DayEntry
		$vevent{'RRULE'} = $rrule;
		$vevent{'SUMMARY'} = $description;
		push @{ $self->{'VEvents'} }, \%vevent;
	    }
	    return;
	}
	elsif ($timeslot =~ /^(\d\d\d\d-\d\d-\d\d)((?:\ $REweekday3)?)
                             \ (\d\d?)((?::\d\d)?)-(\d\d?)((?::\d\d)?)(?:am)?$/x) {
	    my $minstart = $4; $minstart = ":00" unless $minstart ne '';
	    my $minend   = $6; $minend   = ":00" unless $minend   ne '';
	    $starttime = parse_time("$1 $3$minstart");
	    $endtime   = parse_time("$1 $5$minend");
	    my $w3 = $2; $w3 =~ s/^\s+//;
	    die "wrong weekday:($timeslot)" if $w3 ne '' &&
		(strftime("%a",localtime($starttime)) ne $w3 ||
                 strftime("%a",localtime($endtime))   ne $w3);
	}
	#2003-09-08 Mon 1-2pm
	elsif ($timeslot =~ /^(\d\d\d\d-\d\d-\d\d)((?: $REweekday3)?) (\d\d?)((?::\d\d)?)-(\d\d?)((?::\d\d)?)pm$/) {
	    my $minstart = $4; $minstart = ":00" unless $minstart ne '';
	    my $minend   = $6; $minend   = ":00" unless $minend   ne '';
	    $starttime = parse_time("$1 $3$minstart");
	    $endtime   = parse_time("$1 $5$minend");

	    if ($starttime < $endtime) { $starttime += 12*60*60 };
	    $endtime += 12*60*60;

	    my $w3 = $2; $w3 =~ s/^\s+//;
	    die "wrong weekday:($timeslot)" if $w3 ne '' &&
		(strftime("%a",localtime($starttime)) ne $w3 ||
                 strftime("%a",localtime($endtime))   ne $w3);
	}
	else { die "cannot parse timeslot:($timeslot)" }

	die "start>end: $timeslot" if $starttime > $endtime;

	push @{ $self->{'Entries1'}} , { starttime => $starttime,
				       endtime   => $endtime,
				       description => $description };

    }
    else {
	my $col = shift;
	my $start = shift;
	my $end = shift;
	my $text = shift;
	push @{ $self->{'Entries'} }, { col => $col,
					start => $start,
					end => $end,
					text => $text };
    }

} # end of add_entry

=item find_next_time(time_spec[,start_time])

Finds next time starting from start_time according to time_spec
specification and returns it.  If the start_time is not given, the
variable StartTime is used.

Examples:

    $t = $schedule->find_next_time("23:59", $t);

=cut
sub find_next_time {
    my $self = shift;
    my $timedesc = shift;

    my $starttime = ( $#_ == -1 ? $self->{'StartTime'} : shift @_ );

    my $pattern_wday = '*';
    my $pattern_hour = '*';
    my $pattern_min  = '*';
    my $pattern_sec  = 0;

    if ($timedesc =~ /^($REweekday3) (\d\d?(?::\d\d)?)((?:[ap]m)?)$/) {
	my $apm = $3;
	$pattern_wday = weekday_to_digits($1);
	$pattern_hour = $2;
	$pattern_min = 0;
	if ($pattern_hour =~ /:/) { $pattern_min=$'; $pattern_hour=$` }
	$pattern_sec = 0;

	if ($apm eq 'pm') {
	    die unless $pattern_hour <= 12;
	    if ($pattern_hour < 12) { $pattern_hour += 12 }
	}
	elsif ($apm eq 'am') {
	    die unless $pattern_hour <= 12;
	    if ($pattern_hour == 12) { $pattern_hour = 0 }
	}
    } elsif ($timedesc =~ /^(\d?\d):(\d?\d)$/) {
	$pattern_hour = $1; $pattern_min=$2;
    } else { die "cannot parse:($timedesc)" }

    # find seconds
    if ($pattern_sec ne '*') {
	while ((localtime($starttime))[0] != $pattern_sec)
	{ $starttime ++ }
    }

    # find minutes
    if ($pattern_min ne '*') {
	while ((localtime($starttime))[1] != $pattern_min)
	{ $starttime += 60 }
    }

    # find hour
    if ($pattern_hour ne '*') {
	while ((localtime($starttime))[2] != $pattern_hour)
	{ $starttime += 3600 }
    }

    # find weekday
    if ($pattern_wday ne '*') {
	while ((localtime($starttime))[6] != $pattern_wday)
	{ $starttime += 3600*24 }
    }

    return $starttime;
}

sub add_time_label {
    my $self = shift;
    my $t = shift;
    my @r = ();
    while (@{$self->{'RowLabels'}} and $t gt $self->{'RowLabels'}[0])
    { push @r, shift(@{$self->{'RowLabels'}}) }
    push @r, $t unless @{$self->{'RowLabels'}} and $t eq $self->{'RowLabels'}[0];
    push @r, @{$self->{'RowLabels'}};
    $self->{'RowLabels'} = \@r;
}

sub todo_list {
    my $self = shift;
    my $r = "TO DO list: ";
    if (! @{ $self->{'ToDo'} } ) { $r .= "<empty>" }
    else {
	$r .= "<ol>\n".
	    join('', map { "<li> $_->{'desc'}\n" }
		  @{ $self->{'ToDo'} }).
	    "</ol>\n";
    }
    return $r;
}

=item generate_table()

Returns a weekly table in HTML.  Starts with NextTableTime (or
StartTime if NextTableTime does not exist), and updates NextTableTime
so that consecutive call produces the table for the following week.

The table column headers can be can be changed by setting the field
$obj->{ColLabel} to a format as used by the standard function
strftime.  The default format is: ColLabel => "%AE<lt>E<gt>%Y-%m-%d", which
looks something like:

   Monday
 2008-09-01

The format "%A" would produce just the weekday name.

Use $obj->{ShowDays} = 'workdays'; to display only work-days; i.e.,
Monday to Friday.

The table rows include time labeles which are start times and end
times of the events that happend to fall in the table time range, with
additional labels from the variable C<$obj-E<gt>{DefaultRowLabels}>.
The default value of the variable DefaulRowLabels is defined as:

    $self->{DefaultRowLabels} = [qw( 08:00 12:00 17:00 )];

=cut
sub generate_table {
    my $self = shift;
    my (@prepareEntries, @dayEntries);

    $self->{'NextTableTime'} = $self->{'StartTime'}
      if ! exists($self->{'NextTableTime'});
    my $mondaytime = $self->{'NextTableTime'};

    my @showdays = 0..6; # ShowDays: all, workdays
    if ($self->{ShowDays} eq 'workdays') { @showdays = 0..4 }

    my @col_label;
    {
	my $p = $self->{'ColLabel'};
	@col_label = map {
	    strftime($p, localtime($mondaytime + $_*86400))
	    } @showdays;
    }

    foreach my $ve ( @{ $self->{'VEvents'} } ) {
	if (exists($ve->{'RRULE'}) &&
	    $ve->{'RRULE'} =~ /\bFREQ=WEEKLY\b/) {
	    my $d = 0;
	    my $interval = 1;
	    if ($ve->{'RRULE'} =~ /\bINTERVAL=(\d+)/) { $interval = $1 }
	    my $until = undef;	    
	    if ($ve->{'RRULE'} =~ /\bUNTIL=(\d+)/) { $until = $1 }

	    while ($d + $ve->{'DTSTART'} < $mondaytime + 86400*scalar(@showdays)) {
		if (defined($until) && $d+$ve->{'DTSTART'} > $until) { last }

		if ($d+$ve->{'DTSTART'} >= $mondaytime) {
		    if (exists($ve->{'DTEND'})) {
			push @prepareEntries,
			{ starttime => $d+$ve->{'DTSTART'},
			  endtime   => $d+$ve->{'DTEND'},
			  description => $ve->{'SUMMARY'} };
		    } else {
			push @dayEntries,
			{ date => $d+$ve->{'DTSTART'},
			  description => $ve->{'SUMMARY'} };
		    }
		}
		my @a = localtime($d+$ve->{'DTSTART'});
		$d += 86400*7*$interval;
		my @b;
		if (exists($ve->{'DTEND'})) {
		    @b = localtime($d+$ve->{'DTEND'});
		}
		else { @b = localtime($d+$ve->{'DTSTART'} + 60) }
		$d += ($a[8]-$b[8])*3600; # daylight saving
	    }
	}
	# example: RRULE:FREQ=MONTHLY;BYDAY=+3TU
	elsif (exists($ve->{'RRULE'}) &&
	    $ve->{'RRULE'} =~ /\bFREQ=MONTHLY;BYDAY=([^;]+)\b/) {
	    my $byday = $1;
	    my $interval = 1;
	    if ($ve->{'RRULE'} =~ /\bINTERVAL=(\d+)/) { $interval = $1 }
	    my $until = undef;	    
	    if ($ve->{'RRULE'} =~ /\bUNTIL=(\d+)/) { $until = $1 }
	    my @byday = split(/,/,$byday);
	    my @fwd = (); my %wds;
	    for my $bd (@byday) {
		$bd =~ /^([+-][1-5])(\w\w)$/ or die;
		my $f = $1, my $wd = $2; push @fwd, $f, $wd;
		$wds{$wd} = 1;
	    }

	    my $eventstarti = $ve->{'DTSTART'};
	    my $daysincrement = (scalar(keys %wds)==1? 7 : 1);
	    unless (defined($ve->{_cache_next}))
	    { $ve->{_cache_next} = { } }
	    while ($eventstarti < $mondaytime + 86400*scalar(@showdays)) {
		last if defined($until) && $eventstarti > $until;
		goto L1 if $eventstarti < $mondaytime;
		if ($eventstarti >= $mondaytime) {
		    if (exists($ve->{'DTEND'})) {
			push @prepareEntries,
			{ starttime => $eventstarti,
			  endtime   => $eventstarti - $ve->{'DTSTART'}
			               + $ve->{'DTEND'},
			  description => $ve->{'SUMMARY'} };
		    } else {
			push @dayEntries,
			{ date => $eventstarti,
			  description => $ve->{'SUMMARY'} };
		    }
		}
		
	      L1:
		if (defined($ve->{_cache_next}{$eventstarti}))
		{ $eventstarti = $ve->{_cache_next}{$eventstarti} }
		else {
		    my $t1 = $eventstarti;
		  L2:
		    my $t2 = days_increment_DSaware($t1,$daysincrement);
		    last unless $t2 < $mondaytime + 86400*scalar(@showdays);
		    last if defined($until) && $t2 > $until;
		    if ($interval>1) { die "TODO" }
		    my $flag = '';
		    for(my $i=0; $i<=$#fwd; $i+=2) {
			my $f = $fwd[$i]; my $wd = $fwd[$i+1];
			next unless weekday_to_digits($wd)==
			    (localtime($t2))[6];
			next unless is_week_in_month($f, $t2);
			$flag = 1; last;
		    }
		    $t1 = $t2;
		    goto L2 unless $flag;
		    $eventstarti = $ve->{_cache_next}{$eventstarti} = $t1;
		}
	    }
	} # $ve->{'RRULE'} =~ /\bFREQ=MONTHLY;BYDAY=([^;]+)\b/
    }  # foreach my $ve ( @{ $self->{'VEvents'} } ) {

    push @prepareEntries, @{ $self->{'Entries1'} };

    foreach my $entry ( @{ $self->{'Entries'} } ) {
	$self->add_time_label( $entry->{'start'} );
	$self->add_time_label( $entry->{'end'} );
    }

    foreach my $entry ( @prepareEntries ) {
	my $starttime   = $entry->{'starttime'};
	my $endtime     = $entry->{'endtime'};

	my $col = floor(($starttime - $mondaytime) / 86400);
	next if $col < 0 || $col >= scalar(@showdays);
	my $startlabel = strftime("%H:%M", localtime($starttime));
	my $endlabel   = strftime("%H:%M", localtime($endtime));

	$self->add_time_label($startlabel);
	$self->add_time_label($endlabel);
    }

    my %eprep;
    $self->{'overlap'} = [ ];

    foreach my $entry ( @{ $self->{'Entries'} } ) {
      my $col   = $entry->{'col'};
      my $start = $entry->{'start'};
      my $end   = $entry->{'end'};
      my $text  = $entry->{'text'};

      $self->_table_add(\%eprep,$col, $start, $text, $end);
    }

    foreach my $entry ( @prepareEntries ) {
      my $starttime   = $entry->{'starttime'};
      my $endtime     = $entry->{'endtime'};
      my $description = $entry->{'description'};

      my $col = floor(($starttime - $mondaytime) / 86400);
      next if $col < 0 || $col >= scalar(@showdays);
      my $startlabel = strftime("%H:%M", localtime($starttime));
      my $endlabel   = strftime("%H:%M", localtime($endtime));

      $self->_table_add(\%eprep,$col, $startlabel, $description, $endlabel);
    }

    my $r = "<table width=100% border=2 cellspacing=1 cellpadding=1>\n".
            "<tr>\n".
            "<td valign=top>\&nbsp;</td>\n";
    my @op = @{ $self->{overlap} };
    foreach my $di (0 .. $#col_label) {
	$op[$di] = 0 unless defined($op[$di]);
	if ($op[$di] > 0) { $r.= "<th colspan=$op[$di]>" } else { $r.="<th>" }
	$r .= $col_label[$di]."</th>\n";
    }
    $r .= "</tr>\n";

    # check if there are any DayEntries
    push @dayEntries, grep { $_->{'date'} - $mondaytime >=0 &&
			    $_->{'date'} - $mondaytime <= scalar(@showdays)*86400 }
                     @{ $self->{'DayEntries'} };
    if ( @dayEntries ) {
	$r .= '<tr><td>&nbsp;</td>';
	foreach my $i (0 .. $#col_label) {
	    
	    my $r1;
	    foreach my $de (grep { $_->{'date'} - $mondaytime == $i*86400 }
			    @dayEntries )
	    { $r1 .= $de->{'description'}."<br>\n" }
	    $r1 = '&nbsp;' unless $r1;
	    $r .= ($op[$i]==0 ? "<td>" : "<td colspan=$op[$i]>") . "$r1</td>";
	}
	$r .= "</tr>\n";
    }

    my $num_of_timelabels = @{$self->{'RowLabels'}};
    foreach my $ti (0 .. $num_of_timelabels - 1) {

      my $t = $self->{'RowLabels'}[$ti];
      $r.= "<tr><td>$t</td>\n";
      foreach my $di (0 .. $#col_label) {
	  foreach my $oi (0 .. $op[$di]) {
	      next if $oi == 1;
	      my @ind = (\%eprep, $di, $t);
	      @ind = (\%eprep, $di, $t, $oi) if ($oi > 0);
	      if (! $self->_table_get(@ind)) { $r .= "<td align=center>\&nbsp;</td>\n" }
	      elsif ($self->_table_get(@ind) eq 'continue') { $r.= "<!"."-- continue --".">\n" }
	      else {
		  my $counter = 1;
		  my $j=$ti+1;
		  my @ind1 = (\%eprep, $di, $self->{'RowLabels'}[$j]);
		  @ind1 = (\%eprep, $di, $self->{'RowLabels'}[$j], $oi) if $oi > 0;
		  
		  if ($oi == 0) {
		      while ($j <= $num_of_timelabels-1 &&
			     $self->_table_get(\%eprep, $di, $self->{'RowLabels'}[$j]) eq 'continue')
		      { ++ $counter; ++$j }
		  } else {
		      while ($j <= $num_of_timelabels-1 &&
			     $self->_table_get(\%eprep, $di, $self->{'RowLabels'}[$j], $oi) eq 'continue')
		      { ++ $counter; ++$j }
		  }
		  $r.= "<td align=center bgcolor=yellow".
		      ($counter > 1 ? " rowspan=$counter" : '').
		      ">".$self->_table_get(@ind)."</td>\n";
	      }
	  }
      }
      $r.= "</tr>\n";
  }

    $r.="</table>\n";

    $self->{'NextTableTime'} =	# fix for daylight saving
	&find_week_start( $self->{'NextTableTime'} + 86400 * 7 + 7200 );
    $self->{'RowLabels'} = [ @{ $self->{'DefaultRowLabels'} } ];
    return $r;
}

=back

=head1 FUNCTIONS

=cut

sub is_week_in_month {
    my $f = shift; # +1, +2, +3, +4, +5, or -1
    my $t = shift; # time in epoch sec
    my $d = (localtime($t))[3];
    my $m = (localtime($t))[4]; #0=Jan
    my ($lb,$ub);
    die if $f>5 or $f<-5;
    if ($f>0) { $lb = 7*$f-6; $ub = 7*$f; }
    elsif ($f<0) {
	my $t1=$t;
	for(;;) { # find last day in the month
	    $t1+=24*60*60;
	    last if (localtime($t1))[4] != $m;
	}
	$t1-=24*60*60;
	$ub = (localtime($t1))[3] + ($f+1)*7;
	$lb = $ub - 6;
    }
    else { return 1 }
    return 1 if $d>=$lb and $d<=$ub;
    return 0;
}

=pod

=head2 weekday_to_digits

For example, changes all words "SUNDAY", "Sunday", "SUN", or "Sun" to "00", etc.

=cut

sub weekday_to_digits {
    local $_ = shift;
    s/\b(?:SUN?(?:DAY)?|Sun(?:day)?)\b/00/g;
    s/\b(?:MON?(?:DAY)?|Mon(?:day)?)\b/01/xg;
    s/\b(?:TUE?(?:SDAY)?|Tue(?:sday)?)\b/02/xg;
    s/\b(?:WED?(?:NESDAY)?|Wed(?:nesday)?)\b/03/xg;
    s/\b(?:THU?(?:RSDAY)?|Thu(?:rsday)?)\b/04/xg;
    s/\b(?:FRI?(?:DAY)?|Fri(?:day)?)\b/05/xg;
    s/\b(?:SAT?(?:URDAY)?|Sat(?:urday)?)\b/06/xg;
    return $_;
}

# weekday to two uppercase letters
sub weekday_to_WK {
    local $_ = shift;
    s/\b(?:SUN(?:DAY)?|Sun(?:day)?)\b      /SU/xg;
    s/\b(?:MON(?:DAY)?|Mon(?:day)?)\b      /MO/xg;
    s/\b(?:TUE(?:SDAY)?|Tue(?:sday)?)\b    /TU/xg;
    s/\b(?:WED(?:NESDAY)?|Wed(?:nesday)?)\b/WE/xg;
    s/\b(?:THU(?:RSDAY)?|Thu(?:rsday)?)\b  /TH/xg;
    s/\b(?:FRI(?:DAY)?|Fri(?:day)?)\b      /FR/xg;
    s/\b(?:SAT(?:URDAY)?|Sat(?:urday)?)\b  /SA/xg;
    return $_;
}

sub month_to_digits {
    local $_ = shift;
    s/\b(?:JAN(?:UARY)?|Jan(?:uary)?)\b/00/g;
    s/\b(?:FEB(?:RUARY)?|Feb(?:ruary)?)\b/01/xg;
    s/\b(?:MAR(?:CH)?|Mar(?:ch)?)\b/02/xg;
    s/\b(?:APR(?:IL)?|Apr(?:il)?)\b/03/xg;
    s/\b(?:MAY(?:)?|May(?:)?)\b/04/xg;
    s/\b(?:JUN(?:E)?|Jun(?:e)?)\b/05/xg;
    s/\b(?:JUL(?:Y)?|Jul(?:y)?)\b/06/xg;
    s/\b(?:AUG(?:UST)?|Aug(?:ust)?)\b/07/xg;
    s/\b(?:SEP(?:TEMBER)?|Sep(?:tember)?)\b/08/xg;
    s/\b(?:OCT(?:OBER)?|Oct(?:ober)?)\b/09/xg;
    s/\b(?:NOV(?:EMBER)?|Nov(?:ember)?)\b/10/xg;
    s/\b(?:DEC(?:EMBER)?|Dec(?:ember)?)\b/11/xg;
    return $_;
}

# increment time for certain number of days, daylight saving aware
sub days_increment_DSaware {
    my $t = shift; my $i = shift;
    my $t1 = $t + 86400*$i;
    my $t2 = $t; my $t3 = $t1;
    my @a = localtime($t2);
    if ($a[2]==0 && $a[1]==0)	# problem with 0h and 23h
    { $t2 += 60; $t3 += 60; @a = localtime($t2); }
    elsif ($a[2]==23) { $t2 -= 60; $t3 -= 60; @a = localtime($t2); }

    my @b = localtime($t3);
    $t1 += ($a[8]-$b[8])*3600; # daylight saving
    return $t1;
}

sub _table_add {
    my $self = shift;
    my $epr = shift;
    my $col = shift;
    my $row = shift;
    my $des = shift;
    my $end = shift;

    my @rows = @{$self->{'RowLabels'}};
    while (@rows && $rows[0] ne $row) { shift @rows }
    die unless @rows;
    if (!$end || $row eq $end) { splice(@rows,1) }
    else {
	my @t = (shift @rows);
	while ($rows[0] ne $end) {
	    die unless @rows;
	    push @t, ( shift @rows );
	}
	@rows = @t;
    }

    my $overlap = 0;
    {
	my @trows = @rows;
	while (@trows) {
	    my $r = shift @trows;
	    my $oldoverlap = $overlap;
	    if ($overlap==0 && defined $epr->{$col, $r}) {
		#$epr->{$col, $r} .= " -CONFLICT- " . $des;
		$overlap = 2;
	    }
	    while ($overlap > 0 && defined($epr->{$col,$r,$overlap}))
	    { ++ $overlap }
	    if ($overlap > $oldoverlap) { push @trows, @rows }
	}
    }
    $self->{overlap}[$col] = 0 unless defined($self->{overlap}[$col]);
    $self->{overlap}[$col] = $overlap if $overlap > $self->{overlap}[$col];

    $row = shift @rows;
    if ($overlap == 0) {
	$epr->{$col, $row} = $des;
	foreach my $r (@rows)
	{ $epr->{$col, $r} = 'continue' }
    } else {
	$epr->{$col, $row, $overlap} = $des;
	foreach my $r (@rows)
	{ $epr->{$col, $r, $overlap } = 'continue';
	  #$epr->{$col, $r} .= " -CONFLICT- continue";
      }
    }
}

sub _table_get {
    my $self = shift;
    my $epr = shift;
    my $col = shift;
    my $row = shift;
    my $overlap = shift;
    return $overlap > 0 ? $epr->{$col, $row, $overlap} : $epr->{$col, $row};
}

=pod

=cut

sub _getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}

1;
__END__

=head1 THANKS

I would like to thank Stefan Goebel for his report and detailed
analysis of a bug and suggestions, Mike Vasiljevs for his
suggestions and patches for ISO8601 format, and Mohammad S Anwar for
correction regarding missing license field.

=head1 AUTHOR

Copyright 2002-2020 Vlado Keselj, vlado@dnlp.ca, http://web.cs.dal.ca/~vlado

This script is provided "as is" without expressed or implied warranty.
This is free software; you can redistribute it, modify it, or both under
the same terms as Perl itself.

The latest version can be found at
L<http://web.cs.dal.ca/~vlado/srcperl/Calendar-Schedule/>.

=head1 SEE ALSO

There are some Perl modules for different types of calendar, and
likely may more in other programming languages.  I could not find any
existing calendars including the particular features that I needed, so
this module was created.  Below are some modules with similar
functionality:

=over 4

=item [HTML::CalendarMonthSimple] - Perl Module for Generating HTML Calendars

The module is written as a simplifed version of HTML::CalendarMonth.
The intention for this, Calendar::Schedule module, is not to tie it essentially
for HTML.  The events specification is described in a simple textual format.

=item [HTML::CalendarMonth] - Generate and manipulate HTML calendar months

The module HTML::CalendarMonth is a subclass of HTML::ElementTable,
which makes it a part of larger project--the Date-Time Perl project at
F<http://datetime.perl.org>.

=back

=cut

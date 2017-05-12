package Biblio::COUNTER;

use Biblio::COUNTER::Report;

use warnings;
use strict;

use vars qw($VERSION);

$VERSION = '0.11';

sub report {
    my ($cls, $how, %args) = @_;
    if (ref($how) eq 'ARRAY') {
        die "Instantiating a report from an array not yet implemented";
    }
    elsif (ref($how)) {
        # Read report from a filehandle
        my $fh = $how;
        my $callbacks = delete($args{'callback'}) || {};
        my $report = Biblio::COUNTER::Report->new(
            %args,
            'fh' => $fh,
            'callback' => {
                'output' => sub {
                    my ($self, $output) = @_;
                    print $output, "\n";
                },
                %$callbacks,
            },
            'rows'     => [],
            'errors'   => 0,
            'warnings' => 0,
            # Current position within the report
            'r' => 0,
            'c' => '',
            # Current scope (REPORT, HEADER, or RECORD)
            'scope' => undef,
            # Current field (NAME, DESCRIPTION, etc. or TITLE, PUBLISHER, etc.)
            'field' => undef,
            # Containers
            'report' => undef,
            'header' => undef,
            'record' => undef,
            'container' => undef,  # Current container
        );
    }
    else {
        # Instantiate a named report, e.g., "Journal Report 1 (R2)"
        my $name = $how;
        my ($genre, $number, $release) = $cls->_parse_report_name($name);
        die "Unrecognized report type: $name"
            unless defined $genre;
        # Create the "model" object
        $cls = "Biblio::COUNTER::Report::Release${release}::${genre}Report${number}";
        die "Unimplemented report type: $name"
            unless eval "use $cls; 1";
        return $cls->new(%args);
    }
}

sub _parse_report_name {
    my ($cls, $name) = @_;
    my ($genre, $number, $release);
    if ($name =~ s/^\s*(Journal|Database|Book)\s+Report\s+(\w+)\s*//) {
        ($genre, $number) = ($1, $2);
    }
    else {
        return;
    }
    if ($name =~ /^\(R?(\d+[a-z]?)\)/) {
        $release = $1;
    }
    else {
        $release = 2;  # XXX Safe to default?
    }
    return ($genre, $number, $release);
}


1;


=pod

=head1 NAME

Biblio::COUNTER - COUNTER Codes of Practice report processing

=head1 SYNOPSIS

    # --- Process a report
    
    # (1) Using Biblio::COUNTER
    $report = Biblio::COUNTER->report(\*STDIN)->process;
    $report = Biblio::COUNTER->report($file)->process;
    
    # (2) Using Biblio::COUNTER::Processor or a subclass
    $processor = Biblio::COUNTER::Processor::Default->new;\
    $report = $processor->run(\*STDIN);
    $report = $processor->run($file);
    $report = $processor->run(Biblio::COUNTER->new(\*STDIN));
    
    # --- Access information in a processed report
    
    warn "Invalid report" unless $report->is_valid;
    
    # Access data in the report
    $name      = $report->name;
                   # e.g., "Database Report 2 (R2)"
    $descrip   = $report->description;
                   # e.g., "Turnaways by Month and Database"
    $date_run  = $report->date_run;
                   # e.g., "2008-04-11"
    $criteria  = $report->criteria;
    $publisher = $report->publisher;
    $platform  = $report->platform;
    $periods   = $report->periods;
                   # e.g., [ "2008-01", "2008-02", "2008-03" ]
    
    foreach $rec ($report->records) {
        $title     = $rec->{title};
        $publisher = $rec->{publisher};
        $platform  = $rec->{platform};
        $count     = $rec->{count};
        foreach $period (@periods) {
            $period_count = $count->{$period};
            while (($metric, $n) = each %$period_count) {
                # e.g., ("turnaways", 3)
            }
        }
    }

=head1 NOTE

Because the COUNTER Codes of Practice are so poorly written and
documented, with incomplete specifications and inconsistent
terminology, it has been necessary to make certain assumptions and
normalizations in the code and documentation of this module.

First, all reports must be in plain text, tab- or comma-delimited
format; Excel spreadsheets are not allowed.  (To convert an Excel
spreadsheet to tab-delimited text, consider using
L<Spreadsheet::ParseExcel::Simple|Spreadsheet::ParseExcel::Simple>.

(XML formats may be handled in a future version of this module.)

Some terminology notes are in order:

=over 4

=item B<name>

The B<name> of a report fully denotes the report's type and the version
of the COUNTER Codes of Practice that defines it.  For example,
C<Journal Report 1 (R2)>. COUNTER sometimes refers to this as the
report I<title>.

=item B<description>

This is the phrase, also defined by the COUNTER Codes of Practice, that
describes the contents of a report.  For example, B<Journal Report 1>
is described as C<Number of Successful Full-Text Article Requests by
Month and Journal>.

=item B<code>

This is the term I use for the short name that identifies the type,
B<but not the version>, of a COUNTER report.  For example, C<JR1> is the code
for B<Journal Report 1> reports.

=item B<metric>

A metric is a particular measure of usage (or non-usage), including the
number of searches or sessions in a database or the number of full-text
articles in a journal downloaded successfully.

=back

=head1 METHODS

=over 4

=item B<report>(I<$how>, [I<%args>])

Create a new report instance.

Set I<$how> to a glob ref (e.g., C<\*STDIN>) to specify a filehandle
from which an existing report will be read.

Specify a report name in I<$how> (e.g., C<Database Report 2 (R2)>) to
instantiate a new, empty report.  (Report generation is not yet implemented.)

I<%args> may contain any of the following:

=over 4

=item B<treat_blank_counts_as_zero>

If set to a true value, a blank cell where a count was expected is
treated as if it contained a zero; otherwise, blank counts are silently
ignored (the default).

=item B<change_not_available_to_blank>

If set to a true value (the default), the value C<n/a>) in a count
field will be changed to the empty string.  It will B<never> be treated
as if it were zero, regardless of the B<treat_blank_counts_as_zero>
setting.

=item B<callback>

Get or set a reference to a hash of (I<$event>, I<$code>) pairs
specifying what to do for each of the events described under
L<CALLBACKS>.

Each I<$code> must be a coderef, not the name of a function or method.

If an event is not specified in this hash, then the default action for the
event will be taken.

=back

=item B<name>

Get or set the report's name: this is the official name defined by the COUNTER
codes of practice.  See L<REPORTS SUPPORTED> for a complete list of the
reports supported by this verison of L<Biblio::COUNTER|Biblio::COUNTER>.

=item B<code>

Get or set the report's code: this is the short string (e.g., C<JR1>)
that identifies the type, B<but not the version>, of a COUNTER report.

=item B<description>

Get or set the report's description: this is the official description
defined by the COUNTER codes of practice.  For example, the C<Journal
Report 1 (R2)> report has the description C<Number of Successful
Full-Text Article Requests by Month and Journal>.

=item B<date_run>

Get or set the date on which the report was run.  The date, if valid, is in
the ISO8601 standard form C<YYYY-MM-DD>.

=item B<criteria>

Get or set the report criteria.  This is a free text field.

=item B<periods>

Get or set the periods for which the report contains counts.  To
simplify things, periods are returned (and must be set) in the ISO 8601
standard form C<YYYY-MM>.

=item B<publisher>

Get or set the publisher common to all of the resources in the report.

=item B<platform>

Get or set the platform common to all of the resources in the report.

=back

=head1 CALLBACKS

While processing a report, a number of different B<events> occur. For
example,  a B<fixed> event occurs when a field whose value is invalid
is corrected.  For event different kind of event, a B<callback> may be
specified that is triggered each time the event occurs; see the B<report>
method for how to specify a callback.

Callbacks must be coderefs, not function or method names.

For example, the following callbacks may be used to provide an indication of
the progress in processing it:

    $record_number = 0;
    %callbacks = (
        'begin_report' => sub {
            print STDERR "Beginning report: ";
        },
        'end_header' => sub {
            my ($report, $header) = @_;
            print STDERR $report->name, "\n";
        }
        'end_record' => sub {
            my ($report, $record) = @_;
            ++$record_number;
            print STDERR "$record_number "
                if $record_number % 20 == 0;
            print STDERR "\n"
                if $record_number % 200 == 0;
        },
        'end_report' => sub {
            my ($report) = @_;
            if ($report->is_valid) {
                print STDERR "OK\n";
            }
            else {
                print STDERR "INVALID\n";
            }
        },
    );

By default, the only callback defined is for B<output>; it prints each
line of input (corrected, if there were correctable problems) to
standard output. (Spurious blank lines are not printed.)

Events fall into four broad categories: B<structure>, B<validation>,
B<tracing>, and B<data>.

=head2 Structure

Logically, a COUNTER report has the following structure:

    report
        header
        body
            record
            record
            ...

=over 4

=item B<begin_file>(I<$report>, I<$file>)

Parsing of the given file is beginning. This is always the first event
triggered.  At the time this callback is invoked, the report has not yet been
identified.

=item B<end_file>(I<$report>, I<$file>)

Parsing of the given file has ended. This is always the last event
triggered.

=item B<begin_report>(I<$report>)

Processing of the report is beginning.  At the time this callback is invoked,
the report has not yet been identified.

=item B<end_report>(I<$report>)

Processing of the report has ended.  This is always the last event
triggered.

=item B<begin_header>(I<$report>, I<$header>)

Processing of the report's header is beginning.  The header is everything
before the first data row.

I<$header> is a reference to an empty hash; the callback code may, if it wishes,
put something into this hash.

=item B<end_header>(I<$report>, I<$header>)

Processing of the report's header is complete.

I<$header> is a reference to the same hash referenced in the B<begin_header>
callback, but which now contains one or more of the elements listed below.
(These elements are described under B<METHODS> above):

=over 4

=item B<date_run>

The date on which the report was run, in the ISO8601 standard form
C<YYYY-MM-DD>.

=item B<criteria>

The report criteria.

=item B<description>

The report's description (e.g., C<Turnaways by Month and Database>).

=item B<periods>

The periods for which the report contains counts, in the ISO 8601
standard form C<YYYY-MM>.

=item B<publisher>

The publisher common to all of the resources in the report.

=item B<platform>

The platform common to all of the resources in the report.

=back

=item B<begin_body>(I<$report>)

Processing of the report's body is beginning.  The body is the part of the
report that contains data rows.

=item B<end_body>(I<$report>)

Processing of the report's body is complete.

=item B<begin_record>(I<$report>, I<$record>)

Processing of a new record is beginning.  (In some COUNTER reports, a record
occupies more than one row.)

I<$record> is a reference to a hash, which is empty at the time the
event is triggered.

=item B<end_record>(I<$report>, I<$record>)

I<$record> is a reference to a hash that contains the data found in the
record (title, publisher, counts, etc.).  Fields that are invalid and
uncorrectable will B<not> be represented in the hash -- e.g., if a title is
blank then there will be no B<title> element in the hash.

=back

=head2 Validation

Each of these events is triggered when a cell (or, in the case of
B<skip_blank_row>, a row) is validated.

The cell's row and column (e.g., C<D7>) may be retrieved by calling
C<< $report-E<gt>current_position >>.

Note that a single cell may trigger more than one validation event --
e.g., a cell may be trimmed and then deleted -- and there is no guarantee
that these events will occur in any particular order.

=over 4

=item B<ok>(I<$report>, I<$field_name>, I<$value>)

A cell's value is valid.

=item B<trimmed>(I<$report>, I<$field_name>, I<$value>)

Whitespace has been trimmed from the beginning and/or end of a cell.

=item B<fixed>(I<$report>, I<$field_name>, I<$old_value>, I<$new_value>)

A cell's value was invalid but has been corrected.

=item B<cant_fix>(I<$report>, I<$field_name>, I<$value>, I<$expected>)

A cell's value is invalid and cannot be corrected.  The expected value may
be an exact string (e.g., C<EBSCOhost>) or merely a general hint (e.g.,
C<< E<lt>issnE<gt> >>).

=item B<deleted>(I<$report>, I<$value>)

A spurious cell has been deleted.  (A this time, this only occurs for
blank cells at the end of a row.)

=item B<skip_blank_row>(I<$report>)

A blank row that doesn't belong here has been skipped.

=back

=head2 Tracing

=over 4

=item B<input>(I<$line>)

A line of input has been read.

=item B<line>(I<$line_number>)

The report processor has moved to the next line of input.

=item B<output>(I<$line>)

A new line of output is ready.  The default is to print the line to
standard output.  Both valid and invalid lines, including invalid lines
that could not be corrected as well as those that could be corrected,
trigger an output event.  Blank lines that have been skipped do not.

=back

=head2 Data

=over 4

=item B<count>(I<$report>, I<$scope>, I<$metric>, I<$period>, I<$value>)

A valid count has been identified within the report.

I<$scope> is either C<report> (for summary counts that appear at the
top of the report) or C<record> (for counts that occur within the body
of the report).

I<$metric> is the type of event being counted, and is always one of the following:

=over 4

=item C<requests>

=item C<searches>

=item C<sessions>

=item C<turnaways>

=back

I<$period> is a year and month, in the ISO8601 form C<YYYY-MM>.

I<$value> is the number of requests (or searches, or whatever).

B<count> events are B<not> triggered for blank counts unless the
B<treat_blank_counts_as_zero> option was set to a true value when the
report was instantiated.

=item B<count_ytd>(I<$report>, I<$scope>, I<$metric>, I<$value>)
=item B<count_ytd_html>(I<$report>, I<$scope>, I<$metric>, I<$value>)
=item B<count_ytd_pdf>(I<$report>, I<$scope>, I<$metric>, I<$value>)

A valid YTD count has been identified.

I<$scope> is either C<report> (for summary counts that appear at the
top of the report) or C<record> (for counts that occur within the body
of the report).

=back

=head1 REPORTS SUPPORTED

Biblio::COUNTER implements processing of text-format (comma- or tab-delimited)
COUNTER reports only.  XML formats are not supported at this time.

The following is a list of COUNTER reports, with full name and description,
that are supported by this version of L<Biblio::COUNTER|Biblio::COUNTER>:

=over 4

=item C<Journal Report 1 (R2)>

Number of Successful Full-Text Article Requests by Month and Journal

=item C<Journal Report 1a (R2)>

Number of Successful Full-Text Article Requests from an Archive by Month and Journal

=item C<Journal Report 2 (R2)>

Turnaways by Month and Journal

=item C<Database Report 1 (R2)>

Total Searches and Sessions by Month and Database

=item C<Database Report 2 (R2)>

Turnaways by Month and Database

=item C<Database Report 3 (R2)>

Total Searches and Sessions by Month and Service

=back

Other reports, including Release 3 reports, will be supported in the future.

=head1 SEE ALSO

L<http://www.projectcounter.org/>

=head1 AUTHOR

Paul Hoffman (nkuitse AT cpan DOT org).

=head1 COPYRIGHT

Copyright 2008 Paul M. Hoffman.

This is free software, and is made available under the same terms as Perl
itself.

=cut

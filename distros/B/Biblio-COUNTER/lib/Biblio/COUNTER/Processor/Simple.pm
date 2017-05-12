package Biblio::COUNTER::Processor::Simple;

use warnings;
use strict;

use Biblio::COUNTER::Processor;

# Simple processor -- just spits out a lot of lines to STDERR
# and prints [corrected] output to STDOUT

@Biblio::COUNTER::Processor::Simple::ISA = qw(Biblio::COUNTER::Processor);

sub line {
    my ($self, $report, $line) = @_;
    print STDERR "LINE $line\n";
}

sub input {
    my ($self, $report, $input) = @_;
    print STDERR "INPUT $input\n";
}

sub begin_row {
    my ($self, $report, $row) = @_;
    print STDERR "BEGIN row\n";
}

sub end_row {
    my ($self, $report, $row) = @_;
    print STDERR "END row\n";
}

sub output {
    my ($self, $report, $output) = @_;
    print STDERR "OUTPUT $output\n";
    print $output, "\n";
}

sub ok {
    my ($self, $report, $field, $val) = @_;
    my $pos = $report->current_position;
    if ($field eq 'label') {
        print STDERR "OK $pos LABEL $val\n";
    }
    else {
        print STDERR "OK $pos FIELD $field IS $val\n";
    }
}

sub fixed {
    my ($self, $report, $field, $from, $to) = @_;
    my $pos = $report->current_position;
    print STDERR "WARNING $pos CORRECTED $field FROM $from TO $to\n";
}

sub cant_fix {
    my ($self, $report, $field, $is, $expected) = @_;
    my $pos = $report->current_position;
    print STDERR "ERROR $pos IN $field FOUND $is EXPECTED $expected\n";
}

sub trimmed {
    my ($self, $report, $field) = @_;
    my $pos = $report->current_position;
    print STDERR "WARNING $pos TRIMMED $field\n";
}

sub begin_file {
    my ($self, $file) = @_;
    print STDERR "BEGIN file $file\n";
}

sub end_file {
    my ($self, $file) = @_;
    print STDERR "END file $file\n";
}

sub begin_report {
    my ($self, $report) = @_;
    print STDERR "BEGIN report\n";
}

sub end_report {
    my ($self, $report) = @_;
    print STDERR "BEGIN summary\n";
    if ($report->{'errors'}) {
        print STDERR "RESULT not valid\n";
    }
    else {
        print STDERR "RESULT valid\n";
    }
    print STDERR "ERRORS $report->{'errors'}\n";
    print STDERR "WARNINGS $report->{'warnings'}\n";
    print STDERR "END summary\n";
    print STDERR "END report\n";
}

sub begin_header {
    my ($self, $report) = @_;
    print STDERR "BEGIN header\n";
}

sub end_header {
    my ($self, $report, $hdr) = @_;
    my $periods = $report->{'periods'};
    print STDERR "BEGIN metadata\n";
    print STDERR "FIELD $_ $hdr->{$_}\n" for sort keys %$hdr;
    foreach my $m (@$periods) {
        print STDERR "PERIOD $m\n";
    }
    print STDERR "END metadata\n";
    print STDERR "END header\n";
}

sub begin_body {
    my ($self, $report) = @_;
    print STDERR "BEGIN body\n";
}

sub end_body {
    my ($self, $report) = @_;
    print STDERR "END body\n";
}

sub begin_record {
    my ($self, $report, $rec) = @_;
    print STDERR "BEGIN record\n";
}

sub count {
    my ($self, $report, $scope, $field, $period, $val) = @_;
    my ($ok, $normalized_period);
    ($ok, $period, $normalized_period) = $report->parse_period($period);
    my $pos = $report->current_position;
    if ($scope eq 'record') {
        print STDERR "OK $pos COUNT $val METRIC $field PERIOD $normalized_period\n";
    }
    elsif ($scope eq 'report') {
        print STDERR "OK $pos TOTAL $val METRIC $field PERIOD $normalized_period\n";
    }
}

sub end_record {
    my ($self, $report, $rec) = @_;
    print STDERR "BEGIN data\n";
    my $count = delete $rec->{'count'};
    print STDERR "FIELD $_ $rec->{$_}\n" for sort keys %$rec;
    foreach my $m (sort keys %$count) {
        my $period_counts = $count->{$m};
        if (ref $period_counts) {
            while (my ($metric, $val) = each %$period_counts) {
                print STDERR "COUNT $val METRIC $metric PERIOD $m\n";
            }
        }
        else {
            print STDERR "COUNT $period_counts PERIOD $m\n";
        }
    }
    print STDERR "END data\n";
    print STDERR "END record\n";
}

sub skip_blank_row {
    my ($self, $report) = @_;
    my $r = $report->{'r'};
    print STDERR "SKIP $r blank\n";
}


1;

=pod

=head1 NAME

Biblio::COUNTER::Processor::Simple - simple COUNTER report processor

=head1 SYNOPSIS

    use Biblio::COUNTER::Processor::Simple;
    $processor = Biblio::COUNTER::Processor::Simple->new;
    $processor->ignore(@events);
    $report = $processor->run;

=head1 DESCRIPTION

B<Biblio::COUNTER::Processor::Simple> processes a COUNTER report and prints
a verbose stream of data from the report to standard error, while printing
the report B<with corrections> to standard output.

=head1 PUBLIC METHODS

=over 4

=item B<new>(I<%args>)

    $foo = Biblio::COUNTER::Processor::Simple->new;

=item B<run>(I<$file>)

    $report = $processor->run($what);

Process the given report.

I<$what> may be a file handle, the name of a file, or an instance of
(a subclass of) L<Biblio::COUNTER::Report|Biblio::COUNTER::Report>.

=item B<ignore>(I<@events>)

    $processor->ignore(qw/line input output/);

Specify the events to ignore.  The various events are documented in
L<Biblio::COUNTER>.

=back

=head1 INHERITANCE

B<Biblio::COUNTER::Processor::Simple> is designed to be inheritable.

=head1 BUGS

There are no known bugs.  Please report bugs to the author via e-mail
(see below).

=head1 TO DO

Document in detail the output that's produced.

=head1 AUTHOR

Paul Hoffman (nkuitse AT cpan DOT org)

=head1 COPYRIGHT

Copyright 2008 Paul M. Hoffman.

This is free software, and is made available under the same terms as Perl
itself.

=head1 SEE ALSO

L<Biblio::COUNTER>

L<Biblio::COUNTER::Report>

L<Biblio::COUNTER::Report::Processor>


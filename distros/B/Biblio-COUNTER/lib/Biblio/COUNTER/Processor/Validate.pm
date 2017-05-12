package Biblio::COUNTER::Processor::Validate;

use warnings;
use strict;

use Biblio::COUNTER::Processor;

# Validate processor -- just spits out a lot of lines to STDERR
# and prints [corrected] output to STDOUT

@Biblio::COUNTER::Processor::Validate::ISA = qw(Biblio::COUNTER::Processor);

sub verbose { @_ > 1 ? $_[0]->{'verbose'} = $_[1] : $_[0]->{'verbose'} }
sub silent { @_ > 1 ? $_[0]->{'silent'} = $_[1] : $_[0]->{'silent'} }

sub output {
    my ($self, $report, $output) = @_;
    print $output, "\n";
}

sub fixed {
    my ($self, $report, $field, $from, $to) = @_;
    return unless $self->verbose;
    my $pos = $report->current_position;
    print STDERR "warning ($pos): corrected $field from $from to $to\n";
}

sub cant_fix {
    my ($self, $report, $field, $is, $expected) = @_;
    return unless $self->verbose;
    my $pos = $report->current_position;
    print STDERR "error ($pos): in $field, found $is expected $expected\n";
}

sub trimmed {
    my ($self, $report, $field) = @_;
    return unless $self->verbose;
    my $pos = $report->current_position;
    print STDERR "warning ($pos): trimmed $field\n";
}

sub end_report {
    my ($self, $report) = @_;
    my $errors = $report->{'errors'};
    my $warnings = $report->{'warnings'};
    unless ($self->silent) {
        print STDERR "$report->{'errors'} errors\n";
        print STDERR "$report->{'warnings'} warnings\n";
    }
    print( ($errors + $warnings) ? "Report is not valid\n" : "Report is valid\n" )
        if $self->verbose;
    exit 3 if $errors;
    exit 2 if $warnings;
    exit 0;
}


1;

=pod

=head1 NAME

Biblio::COUNTER::Processor::Validate - simple COUNTER report validator

=head1 SYNOPSIS

    use Biblio::COUNTER::Processor::Validate;
    $processor = Biblio::COUNTER::Processor::Validate->new;
    $report = $processor->run;

=head1 DESCRIPTION

B<Biblio::COUNTER::Processor::Validate> processes a COUNTER report and prints
a verbose stream of data from the report to standard error, while printing
the report B<with corrections> to standard output.

=head1 PUBLIC METHODS

=over 4

=item B<new>(I<%args>)

    $processor = Biblio::COUNTER::Processor::Validate->new;

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

B<Biblio::COUNTER::Processor::Validate> is designed to be inheritable.

=head1 BUGS

There are no known bugs.  Please report bugs to the author via e-mail
(see below).

=head1 TO DO

Document in detail the output that's produced.

=head1 AUTHOR

Paul Hoffman (nkuitse AT cpan DOT org)

=head1 COPYRIGHT

Copyright 2008-2009 Paul M. Hoffman.

This is free software, and is made available under the same terms as Perl
itself.

=head1 SEE ALSO

L<Biblio::COUNTER>

L<Biblio::COUNTER::Report>

L<Biblio::COUNTER::Report::Processor>


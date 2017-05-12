package Biblio::COUNTER::Processor;

use strict;
use warnings;

use Biblio::COUNTER;

# A class designed to be inherited from for OO-style event handling

sub new {
    my ($cls, %args) = @_;
    my $self = bless {
        'ignore' => {},
        %args,
    }, $cls;
    return $self;
}

sub ignore {
    my ($self, @what) = @_;
    $self->{'ignore'}->{$_} = 1 for @what;
}

sub run {
    my ($self, $report) = @_;
    my $fh;
    $self->{'file'} = $report;
    if (ref($report) eq '') {
        # Assume $report is a file name
        if ($report eq '-') {
            $fh = \*STDIN;
        }
        else {
        open $fh, '<', $report
            or die "Can't open report '$report': $!";
        }
        $report = Biblio::COUNTER->report($fh);
    }
    elsif ($report->isa('Biblio::COUNTER::Report')) {
        # Nothing special to do
    }
    else {
        # Assume it's a filehandle
        $report = Biblio::COUNTER->report($report);
    }
    $report->{'file'} = $self->{'file'};
    my $ignore = $self->{'ignore'};
    $report->{'callback'} = {
        '*' => sub {
            my ($report, $callback_name, @args) = @_;
            if (!$ignore->{$callback_name}
                    && defined(my $code = $self->can($callback_name))) {
                $code->($self, $report, @args);
            }
        },
    };
    $report->process;
    close $fh if defined $fh;
    return $report;
}


1;

=pod

=head1 NAME

Biblio::COUNTER::Processor - superclass for Biblio::COUNTER processors

=head1 SYNOPSIS

    # Use
    use Biblio::COUNTER::Processor;
    $processor = Biblio::COUNTER::Processor->new;
    $processor->ignore(@events);
    $report = $processor->run;

    # Subclass
    use MyProcessor;
    @MyProcessor::ISA = qw(Biblio::COUNTER::Processor);
    # Event handlers
    sub begin_report {
        my ($self, $report) = @_;
        # etc.
    }
    sub count {
        my ($self, $report, $scope, $field, $period, $val) = @_;
        # etc.
    }
    # etc.
    
=head1 DESCRIPTION

B<Biblio::COUNTER::Processor> is an inheritable class that provides an
intermediate interface to L<Biblio::COUNTER|Biblio::COUNTER>.  When used on
its own, it does nothing; subclasses must define handlers for the various
events (e.g., C<begin_report> or C<count>) that are triggered as a report
is processed.

Event-handling methods (if defined) are invoked with the arguments
documented in L<Biblio::COUNTER>, except that an additional argument (the
instance of the L<Biblio::COUNTER::Processor|Biblio::COUNTER::Processor>
subclass) is prepended.

For a class that actually B<does> something when events are triggered, see
L<Biblio::COUNTER::Processor::Simple|Biblio::COUNTER::Processor::Simple>.

=head1 METHODS

=over 4

=item B<new>

    $processor = Biblio::COUNTER::Processor->new;

Create a new processor.

=item B<run>(I<$file>)

    $report = $processor->run($what);

Process the given report.

I<$what> may be a file handle, the name of a file, or an instance of
(a subclass of) L<Biblio::COUNTER::Report|Biblio::COUNTER::Report>.

A L<Biblio::COUNTER::Report|Biblio::COUNTER::Report> object will be
instantiated and its B<process> method invoked; each time an event is
triggered, a method with the event's name (e.g., C<begin_record> or
C<cant_fix>) is invoked B<if it is defined>.  Since this class doesn't
define any such methods, the default behavior when an event is triggered is
to do nothing.

=item B<ignore>(I<@events>)

    $processor->ignore(qw/line input output/);

Specify the events to ignore.  The various events are documented in
L<Biblio::COUNTER>.

=back

=head1 INHERITANCE

B<Biblio::COUNTER::Processor> is designed to be inheritable; in fact, it
doesn't do anything on its own (unless you count I<ignoring events> as
doing something).

=head1 BUGS

There are no known bugs.  Please report bugs to the author via e-mail
(see below).

=head1 AUTHOR

Paul Hoffman (nkuitse AT cpan DOT org)

=head1 COPYRIGHT

Copyright 2008 Paul M. Hoffman.

This is free software, and is made available under the same terms as Perl
itself.

=head1 SEE ALSO

L<Biblio::COUNTER>

L<Biblio::COUNTER::Report>

L<Biblio::COUNTER::Report::Processor::Simple>


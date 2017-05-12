package Biblio::COUNTER::Processor::Atomize;

use warnings;
use strict;

use Biblio::COUNTER::Processor;

@Biblio::COUNTER::Processor::Atomize::ISA = qw(Biblio::COUNTER::Processor);

sub begin_report {
    my ($self, $report) = @_;
    $self->{'number'} = 1;
}

sub end_report {
    my ($self, $report) = @_;
    undef $self->{'number'};
}

sub end_record {
    my ($self, $report, $rec) = @_;
    my $cb = $self->{'callback'} ||= \&_default_callback;
    my $count = delete $rec->{'count'};
    foreach my $period (sort keys %$count) {
        my $period_counts = $count->{$period};
        if (ref $period_counts) {
            while (my ($metric, $count) = each %$period_counts) {
                $cb->(
                    'processor' => $self,
                    'report'    => $report,
                    'recnum'    => $self->{'number'}++,
                    %$rec,
                    'period'    => $period,
                    'metric'    => $metric,
                    'count'     => $count,
                );
            }
        }
        else {
            die "Huh?";
        }
    }
}

sub _default_callback {
    my %data = @_;
    my $code = $data{'code'} = $data{'report'}->canonical_report_code;
    $data{'file'} = $data{'processor'}->{'file'};
    my @header = qw(Type File Platform Period Metric Count Title Publisher);
    my @data = @data{qw(code file platform period metric count title publisher)};
    if ($code =~ /^J/) {
        push @header, "Print ISSN", "Online ISSN";
        push @data, @data{qw(print_issn online_issn)};
    }
    elsif ($code =~ /^B/) {
        push @header, "ISBN";
        push @data, @data{qw(isbn)};
    }
    if ($data{'recnum'} == 1) {
        print join("\t", @header), "\n";
    }
    print join("\t", map { defined $_ ? $_ : '' } @data), "\n";
}


1;

=pod

=head1 NAME

Biblio::COUNTER::Processor::Atomize - break a COUNTER report into itsy pieces

=head1 SYNOPSIS

    use Biblio::COUNTER::Processor::Atomize;
    $processor = Biblio::COUNTER::Processor::Atomize->new;
    $report = $processor->run($file_or_filehandle);

=head1 DESCRIPTION

B<Biblio::COUNTER::Processor::Atomize> breaks a COUNTER report into
tiny pieces (figuratively speaking) and executes a callback for each
valid usage number it finds.

The callback function should look something like this:

    sub my_callback {
        my %data = @_;
        $title  = $data{title};
        $count  = $data{count};
        $metric = $data{metric};
        $period = $data{period};
        # etc.
    }

The following elements may appear in the hash passed to the callback function:

=over 4

=item B<code>

The short code that indicates the type of the report (e.g., C<JR1> or C<DB3>).

=item B<file>

The name of the file containing the report.  Set to C<-> if processing
standard input.

=item B<processor>

The Biblio::COUNTER::Processor::Atomize instance.

=item B<report>

The instance of the appropriate subclass of Biblio::COUNTER::Report

=item B<period>

A string of the form I<YYYY-mm> denoting the period in question.

=item B<metric>

The type of event counted (C<requests>, C<sessions>, C<searches>, or
C<turnaways>).

=item B<count>

The count itself.  The callback is B<not> executed for a blank or invalid count.

=item B<platform>

The platform on which the resource was provided.

=item B<title>

The resource title.

=item B<publisher>

The resource's publisher.  May be the empty string.

=item B<print_issn> (journal reports only)

The journal's print ISSN.

=item B<online_issn> (journal reports only)

The journal's online ISSN.

=item B<isbn> (book reports only)

The book's ISBN.

=back

=head1 PUBLIC METHODS

=over 4

=item B<new>(I<%args>)

    $foo = Biblio::COUNTER::Processor::Atomize->new;

I<%args> is a list of (key, value) pairs.  The only key that means
anything is B<callback>; the value associated with it is a reference to
the desired callback function.

The desired callback function prints (to standard output) a single
tab-delimited line for each datum, with a header.  Each line of output has
the following elements, in the order listed:

=over 4

=item B<code>

=item B<file>

=item B<platform>

=item B<period>

=item B<metric>

=item B<count>

=item B<title>

=item B<publisher>

=item B<print_issn> (journal reports only)

=item B<online_issn> (journal reports only)

=item B<isbn> (book reports only)

=back

=item B<run>(I<$file>)

    $report = $processor->run($what);

Process the given report.

I<$what> may be a file handle, the name of a file, or an instance of
(a subclass of) L<Biblio::COUNTER::Report|Biblio::COUNTER::Report>.

=back

=head1 INHERITANCE

B<Biblio::COUNTER::Processor::Atomize> is designed to be inheritable.

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

L<Biblio::COUNTER::Report::Processor>


package App::GnuplotUtils;

our $DATE = '2018-05-07'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{xyplot} = {
    v => 1.1,
    summary => "Plot XY data using gnuplot",
    description => <<'_',

Example `input.txt`:

    1 1
    2 3
    3 5.5
    4 7.9
    6 11.5

Example using `xyplot`:

    % xyplot < input.txt

Keywords: xychart, XY chart, XY plot

_
    args => {
        delimiter => {
            summary => 'Supply field delimiter character instead of the default whitespace(s)',
            schema => 'str*',
            cmdline_aliases => {d=>{}},
        },
        # XXX more options
    },
    deps => {
        prog => 'gnuplot',
    },
};
sub xyplot {
    my %args = @_;

    my $fieldsep_re = qr/\s+/;
    if (defined $args{delimited}) {
        $fieldsep_re = qr/\Q$args{delimited}\E/;
    }

    my (@x, @y);
    while (<STDIN>) {
        chomp;
        my @f = split $fieldsep_re, $_;
        push @x, $f[0];
        push @y, $f[0];
    }

    require Chart::Gnuplot;
    require File::Temp;
    my ($fh, $filename) = File::Temp::tempfile();
    $filename .= ".png";
    log_trace "Output filename: %s", $filename;
    my $chart = Chart::Gnuplot->new(
        output => $filename,
        title => "(No title)",
        xlabel => "x",
        ylabel => "y",
    );
    my $dataset = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => \@y,
        title => "(Untitled dataset)",
        style => "points", # "linespoints",
    );
    $chart->plot2d($dataset);

    require Browser::Open;
    Browser::Open::open_browser("file:$filename");

    [200];
}

1;
# ABSTRACT: Utilities related to plotting data using gnuplot

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GnuplotUtils - Utilities related to plotting data using gnuplot

=head1 VERSION

This document describes version 0.001 of App::GnuplotUtils (from Perl distribution App-GnuplotUtils), released on 2018-05-07.

=head1 DESCRIPTION

This distributions provides the following command-line utilities. They are
mostly simple/convenience wrappers for gnuplot:

=over

=item * L<xyplot>

=back

=head1 FUNCTIONS


=head2 xyplot

Usage:

 xyplot(%args) -> [status, msg, result, meta]

Plot XY data using gnuplot.

Example C<input.txt>:

 1 1
 2 3
 3 5.5
 4 7.9
 6 11.5

Example using C<xyplot>:

 % xyplot < input.txt

Keywords: xychart, XY chart, XY plot

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<delimiter> => I<str>

Supply field delimiter character instead of the default whitespace(s).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GnuplotUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GnuplotUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GnuplotUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

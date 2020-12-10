package App::GnuplotUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-10'; # DATE
our $DIST = 'App-GnuplotUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{xyplot} = {
    v => 1.1,
    summary => "Plot XY dataset(s) using gnuplot",
    description => <<'_',

Example `input1.txt`, each line contains whitespace-separated values of X data
(number), Y data (number):

    1 1
    2 3
    3 5.5
    4 7.9
    6 11.5

Example using `xyplot` (one data-set):

    % xyplot < input1.txt

Example `input2.txt`:

    1 8
    2 12
    3 5
    4 4
    6 8

Using two datasets:

    % xyplot --dataset-file  input1.txt  --dataset-file  input2.txt \
             --dataset-color red         --dataset-color blue \
             --dataset-style linespoints --dataset-style points

Keywords: xychart, XY chart, XY plot

_
    args => {
        chart_title => {
            schema => 'str*',
        },
        field_delimiter => {
            summary => 'Supply field delimiter character in dataset file instead of the default whitespace(s)',
            schema => 'str*',
            cmdline_aliases => {d=>{}},
        },
        datasets => {
            summary => 'Dataset(s)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dataset',
            'schema' => ['array*', of=>'array*'],
        },
        dataset_files => {
            summary => 'Dataset(s) from file(s)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dataset_file',
            'schema' => ['array*', of=>'filename*'],
        },
        dataset_titles => {
            summary => 'Dataset title(s)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dataset_title',
            schema => ['array*', of=>'str*'],
        },
        dataset_styles => {
            summary => 'Dataset plot style(s)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dataset_style',
            schema => ['array*', of=>['str*', in=>[
                'lines', 'points', 'linespoints', 'dots', 'impluses', 'steps',
                'boxes', 'xerrorbars', 'yerrorbars', 'xyerrorbars',
                'xerrorlines', 'yerrorlines', 'xyerrorlines', 'boxerrorbars',
                'boxxyerrorbars', 'financebars', 'candlesticks', 'hbars',
                'hlines', 'vectors', 'circles', 'histograms',
            ]]],
        },
    },
    args_rels => {
        req_one => [qw/datasets dataset_files/],
    },
    deps => {
        prog => 'gnuplot',
    },
};
sub xyplot {
    require Chart::Gnuplot;
    require File::Slurper::Dash;
    require File::Temp;

    my %args = @_;

    my $fieldsep_re = qr/\s+/;
    if (defined $args{delimited}) {
        $fieldsep_re = qr/\Q$args{delimited}\E/;
    }

    my $chart;
    my ($tempfh, $tempfilename);
    my $n;
    if ($args{datasets}) {
        $n = $#{ $args{datasets} };
    } else {
        $n = $#{ $args{dataset_files} };
    }
    for my $i (0..$n) {
        my (@x, @y);
        if ($args{datasets}) {
            my $dataset = $args{datasets}[$i];
            @x          = map { $_->{x} }      @$dataset;
            @y          = map { $_->{y} }      @$dataset;
        } else {
            my $filename = $args{dataset_files}[$i];
            my $content = File::Slurper::Dash::read_text($filename);

            for my $line (split /^/m, $content) {
                chomp $line;
                my @f = split $fieldsep_re, $line;
                push @x, $f[0];
                push @y, $f[1];
            }
        }

        unless ($tempfh) {
            ($tempfh, $tempfilename) = File::Temp::tempfile();
            $tempfilename .= ".png";
            log_trace "Output filename: %s", $tempfilename;
            $chart = Chart::Gnuplot->new(
                output => $tempfilename,
                title => $args{chart_title} // "(No title)",
                xlabel => "x",
                ylabel => "y",
            );
        }

        my $dataset = Chart::Gnuplot::DataSet->new(
            xdata => \@x,
            ydata => \@y,
            title => $args{dataset_titles}[$i] // "(Untitled dataset #$i)",
            style => $args{dataset_styles}[$i] // 'points',
        );
        $chart->plot2d($dataset);
    }

    require Browser::Open;
    Browser::Open::open_browser("file:$tempfilename");

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

This document describes version 0.002 of App::GnuplotUtils (from Perl distribution App-GnuplotUtils), released on 2020-12-10.

=head1 DESCRIPTION

This distributions provides the following command-line utilities. They are
mostly simple/convenience wrappers for gnuplot:

=over

=item * L<xyplot>

=back

=head1 FUNCTIONS


=head2 xyplot

Usage:

 xyplot(%args) -> [status, msg, payload, meta]

Plot XY dataset(s) using gnuplot.

Example C<input1.txt>, each line contains whitespace-separated values of X data
(number), Y data (number):

 1 1
 2 3
 3 5.5
 4 7.9
 6 11.5

Example using C<xyplot> (one data-set):

 % xyplot < input1.txt

Example C<input2.txt>:

 1 8
 2 12
 3 5
 4 4
 6 8

Using two datasets:

 % xyplot --dataset-file  input1.txt  --dataset-file  input2.txt \
          --dataset-color red         --dataset-color blue \
          --dataset-style linespoints --dataset-style points

Keywords: xychart, XY chart, XY plot

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<chart_title> => I<str>

=item * B<dataset_files> => I<array[filename]>

Dataset(s) from file(s).

=item * B<dataset_styles> => I<array[str]>

Dataset plot style(s).

=item * B<dataset_titles> => I<array[str]>

Dataset title(s).

=item * B<datasets> => I<array[array]>

Dataset(s).

=item * B<field_delimiter> => I<str>

Supply field delimiter character in dataset file instead of the default whitespace(s).


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GnuplotUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GnuplotUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-GnuplotUtils/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package App::GnuplotUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-21'; # DATE
our $DIST = 'App-GnuplotUtils'; # DIST
our $VERSION = '0.006'; # VERSION

our %SPEC;

$SPEC{xyplot} = {
    v => 1.1,
    summary => "Plot XY dataset(s) using gnuplot",
    description => <<'_',

This utility is a wrapper for gnuplot to quickly generate a graph from the
command-line and view it using an image viewer program or a browser.

**Specifying dataset**

You can specify the dataset to plot directly from the command-line or specify
filename to read the dataset from.

To plot directly from the command-line, specify comma-separated list of X & Y
number pairs using `--dataset-data` option:

    % xyplot --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' ; # whitespaces are optional

To add more datasets, specify more `--dataset-data` options:

    % xyplot --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' \
             --dataset-data '1,4,2,4,3,2,4,9,5,3,6,6';         # will plot two lines

To add a title to your chart and every dataset, use `--dataset-title`:

    % xyplot --chart-title "my chart" \
             --dataset-title "foo" --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' \
             --dataset-title "bar" --dataset-data '1,4,2,4,3,2,4,9,5,3,6,6'

To specify dataset from files, use one or more `--dataset-file` options (or
specify the filenames as arguments):

    % xyplot --dataset-file ds1.txt --dataset-file ds2.txt
    % xyplot ds1.txt ds2.txt

`ds1.txt` should contain comma, or whitespace-separated list of X & Y numbers.
You can put one number per line or more.

 1 1
 2 3
 3 5.5
 4 7.9
 6 11.5
 8
 13.5
 9 14.2 10 14.8

To accept data from stdin, you can specify `-` as the filename:

 % tabulate-drug-concentration ... | xyplot -


**Seeing plot result**

`xyplot` uses <pm:Desktop::Open> to view the resulting plot. The module will
first find a suitable application, and failing that will use the web browser. If
you specify `--output-file` (`-o`), the plot is written to the specified image
file.

To see in a viewer program or browser and set the image format:

    % xyplot --output-format svg ...

If you want to use to force the browser:

    % PERL_DESKTOP_OPEN_USE_BROWSER=1 xyplot ...

If you want to set the program to use to open:

    % PERL_DESKTOP_OPEN_PROGRAM=google-chrome xyplot --output-format svg ...


**Tips & Tricks**

**CSV format.** If you have your data in CSV format, you can use
<prog:csv-unquote> to make sure your numbers are not quoted with double quotes,
or you can use <prog:csv2tsv> to convert your CSV to TSV first. Both utilities
are included in <pm:App::CSVUtils>.


**Keywords**

xychart, XY chart, XY plot

_
    args => {
        chart_title => {
            schema => 'str*',
        },
        output_format => {
            description => <<'MARKDOWN',

The output format is normally determined from the output filename's extension,
e.g. `foo.jpg`. This option is for when you do not specify output filename and
want to change the format from the default `png`.

MARKDOWN
            schema => ['str*', in=>[qw/bmp gif jpg png webp
                                       pdf ps svg/]],
            default => 'png',
        },
        output_file => {
            schema => 'filename*',
            cmdline_aliases => {o=>{}},
            tags => ['category:output'],
        },
        overwrite => {
            schema => 'bool*',
            cmdline_aliases => {O=>{}},
            tags => ['category:output'],
        },

        field_delimiter => {
            summary => 'Supply field delimiter character in dataset file instead of the default whitespace(s) or comma(s)',
            schema => 'str*',
            cmdline_aliases => {d=>{}},
        },
        dataset_datas => {
            summary => 'Dataset(s)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dataset_data',
            'schema' => ['array*', of=>'str*'],
        },
        dataset_files => {
            summary => 'Dataset(s) from file(s)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dataset_file',
            'schema' => ['array*', of=>'filename*'],
            pos => 0,
            slurpy => 1,
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
        req_one => [qw/dataset_datas dataset_files/],
    },
    deps => {
        prog => 'gnuplot',
    },
    links => [
        {url=>'prog:tchart', summary=>'From App::tchart Perl module, to quickly create ASCII chart, currently sparklines'},
        {url=>'prog:asciichart', summary=>'From App::AsciiChart Perl module, to quickly create ASCII chart'},
    ],
};
sub xyplot {
    require Chart::Gnuplot;
    require File::Slurper::Dash;
    require File::Temp;
    require Scalar::Util;

    my %args = @_;

    my $output_format = $args{output_format} // 'png';

    my $fieldsep_re = qr/\s*,\s*|\s+/s;
    if (defined $args{delimited}) {
        $fieldsep_re = qr/\Q$args{delimited}\E/;
    }

    my ($outputfilename);
    if (defined $args{output_file}) {
        $outputfilename = $args{output_file};
        if (-f $outputfilename && !$args{overwrite}) {
            return [412, "Not overwriting existing file '$outputfilename', use --overwrite (-O) to overwrite"];
        }
    } else {
        my $tempfh;
        ($tempfh, $outputfilename) = File::Temp::tempfile();
        $outputfilename .= ".$output_format";
    }
    log_trace "Output filename: %s", $outputfilename;

    my $chart = Chart::Gnuplot->new(
        output => $outputfilename,
        title => $args{chart_title} // "(chart created by xyplot on ".scalar(localtime).")",
        xlabel => "x",
        ylabel => "y",
    );

    my $n;
    if ($args{dataset_datas}) {
        $n = $#{ $args{dataset_datas} };
    } else {
        $n = $#{ $args{dataset_files} };
    }

    my @datasets;
    for my $i (0..$n) {
        my (@x, @y);
        if ($args{dataset_datas}) {
            my $dataset = [split $fieldsep_re, $args{dataset_datas}[$i]];
            while (@$dataset) {
                my $item = shift @$dataset;
                warn "Not a number in --dataset-data: '$item'" unless Scalar::Util::looks_like_number($item);
                push @x, $item;

                warn "Odd number of numbers in --dataset-data" unless @$dataset;
                $item = shift @$dataset;
                warn "Not a number in --dataset-data: '$item'" unless Scalar::Util::looks_like_number($item);
                push @y, $item;
            }
        } else {
            my $filename = $args{dataset_files}[$i];
            my $content = File::Slurper::Dash::read_text($filename);

            chomp $content;
            my @numbers = split $fieldsep_re, $content;
            warn "Odd number of numbers in dataset file '$filename'" unless @numbers % 2 == 0;
            while (@numbers) {
                my $item = shift @numbers;
                warn "Not a number in dataset file '$filename': '$item'" unless Scalar::Util::looks_like_number($item);
                push @x, $item;

                $item = shift @numbers;
                warn "Not a number in dataset file '$filename': '$item'" unless Scalar::Util::looks_like_number($item);
                push @y, $item;
            }
        }

        my $dataset = Chart::Gnuplot::DataSet->new(
            xdata => \@x,
            ydata => \@y,
            title => $args{dataset_titles}[$i] // "(dataset #$i)",
            style => $args{dataset_styles}[$i] // 'linespoints',
        );
        push @datasets, $dataset;
    }
    $chart->plot2d(@datasets);

    if (defined $args{output_file}) {
        return [200];
    } else {
        require Desktop::Open;
        my $res = Desktop::Open::open_desktop("file:$outputfilename");
        if (defined $res && $res == 0) {
            return [200];
        } else {
            return [500, "Can't open $outputfilename"];
        }
    }
}

1;
# ABSTRACT: Utilities related to plotting data using gnuplot

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GnuplotUtils - Utilities related to plotting data using gnuplot

=head1 VERSION

This document describes version 0.006 of App::GnuplotUtils (from Perl distribution App-GnuplotUtils), released on 2023-10-21.

=head1 DESCRIPTION

This distributions provides the following command-line utilities. They are
mostly simple/convenience wrappers for gnuplot:

=over

=item * L<xyplot>

=back

=head1 FUNCTIONS


=head2 xyplot

Usage:

 xyplot(%args) -> [$status_code, $reason, $payload, \%result_meta]

Plot XY dataset(s) using gnuplot.

This utility is a wrapper for gnuplot to quickly generate a graph from the
command-line and view it using an image viewer program or a browser.

B<Specifying dataset>

You can specify the dataset to plot directly from the command-line or specify
filename to read the dataset from.

To plot directly from the command-line, specify comma-separated list of X & Y
number pairs using C<--dataset-data> option:

 % xyplot --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' ; # whitespaces are optional

To add more datasets, specify more C<--dataset-data> options:

 % xyplot --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' \
          --dataset-data '1,4,2,4,3,2,4,9,5,3,6,6';         # will plot two lines

To add a title to your chart and every dataset, use C<--dataset-title>:

 % xyplot --chart-title "my chart" \
          --dataset-title "foo" --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' \
          --dataset-title "bar" --dataset-data '1,4,2,4,3,2,4,9,5,3,6,6'

To specify dataset from files, use one or more C<--dataset-file> options (or
specify the filenames as arguments):

 % xyplot --dataset-file ds1.txt --dataset-file ds2.txt
 % xyplot ds1.txt ds2.txt

C<ds1.txt> should contain comma, or whitespace-separated list of X & Y numbers.
You can put one number per line or more.

 1 1
 2 3
 3 5.5
 4 7.9
 6 11.5
 8
 13.5
 9 14.2 10 14.8

To accept data from stdin, you can specify C<-> as the filename:

 % tabulate-drug-concentration ... | xyplot -

B<Seeing plot result>

C<xyplot> uses L<Desktop::Open> to view the resulting plot. The module will
first find a suitable application, and failing that will use the web browser. If
you specify C<--output-file> (C<-o>), the plot is written to the specified image
file.

To see in a viewer program or browser and set the image format:

 % xyplot --output-format svg ...

If you want to use to force the browser:

 % PERL_DESKTOP_OPEN_USE_BROWSER=1 xyplot ...

If you want to set the program to use to open:

 % PERL_DESKTOP_OPEN_PROGRAM=google-chrome xyplot --output-format svg ...

B<Tips & Tricks>

B<CSV format.> If you have your data in CSV format, you can use
L<csv-unquote> to make sure your numbers are not quoted with double quotes,
or you can use L<csv2tsv> to convert your CSV to TSV first. Both utilities
are included in L<App::CSVUtils>.

B<Keywords>

xychart, XY chart, XY plot

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<chart_title> => I<str>

(No description)

=item * B<dataset_datas> => I<array[str]>

Dataset(s).

=item * B<dataset_files> => I<array[filename]>

Dataset(s) from file(s).

=item * B<dataset_styles> => I<array[str]>

Dataset plot style(s).

=item * B<dataset_titles> => I<array[str]>

Dataset title(s).

=item * B<field_delimiter> => I<str>

Supply field delimiter character in dataset file instead of the default whitespace(s) or comma(s).

=item * B<output_file> => I<filename>

(No description)

=item * B<output_format> => I<str> (default: "png")

The output format is normally determined from the output filename's extension,
e.g. C<foo.jpg>. This option is for when you do not specify output filename and
want to change the format from the default C<png>.

=item * B<overwrite> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GnuplotUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GnuplotUtils>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GnuplotUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

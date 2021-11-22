package App::GnuplotUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-02'; # DATE
our $DIST = 'App-GnuplotUtils'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{xyplot} = {
    v => 1.1,
    summary => "Plot XY dataset(s) using gnuplot",
    description => <<'_',

This utility is a wrapper for gnuplot to quickly generate a graph from the
command-line and view it using a browser or an image viewer program. You can
specify the dataset to plot directly from the command-line or specify filename
to read the dataset from.

To plot directly from the command-line:

    % xyplot --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' ; # whitespaces are optional

To add more datasets, specify more `--dataset-data` options:

    % xyplot --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' \
             --dataset-data '1,4,2,4,3,2,4,9,5,3,6,6'

To add a title to your chart and every dataset:

    % xyplot --chart-title "my chart" \
             --dataset-title "foo" --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' \
             --dataset-title "bar" --dataset-data '1,4,2,4,3,2,4,9,5,3,6,6'

To specify dataset from a file, use `--dataset-file` option (or specify as
arguments):

    % xyplot --dataset-file ds1.txt --dataset-file ds2.txt
    % xyplot ds1.txt ds2.txt

`ds1.txt` contains these lines:

 1 1
 2 3
 3 5.5
 4 7.9
 6 11.5

Keywords: xychart, XY chart, XY plot

_
    args => {
        chart_title => {
            schema => 'str*',
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
};
sub xyplot {
    require Chart::Gnuplot;
    require File::Slurper::Dash;
    require File::Temp;

    my %args = @_;

    my $fieldsep_re = qr/\s+|\s*,\s*/;
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
        $outputfilename .= ".png";
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
                push @x, shift @$dataset;
                push @y, shift @$dataset;
            }
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

This document describes version 0.003 of App::GnuplotUtils (from Perl distribution App-GnuplotUtils), released on 2021-07-02.

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
command-line and view it using a browser or an image viewer program. You can
specify the dataset to plot directly from the command-line or specify filename
to read the dataset from.

To plot directly from the command-line:

 % xyplot --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' ; # whitespaces are optional

To add more datasets, specify more C<--dataset-data> options:

 % xyplot --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' \
          --dataset-data '1,4,2,4,3,2,4,9,5,3,6,6'

To add a title to your chart and every dataset:

 % xyplot --chart-title "my chart" \
          --dataset-title "foo" --dataset-data '1,1, 2,3, 3,5.5, 4,7.9, 6,11.5' \
          --dataset-title "bar" --dataset-data '1,4,2,4,3,2,4,9,5,3,6,6'

To specify dataset from a file, use C<--dataset-file> option (or specify as
arguments):

 % xyplot --dataset-file ds1.txt --dataset-file ds2.txt
 % xyplot ds1.txt ds2.txt

C<ds1.txt> contains these lines:

 1 1
 2 3
 3 5.5
 4 7.9
 6 11.5

Keywords: xychart, XY chart, XY plot

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<chart_title> => I<str>

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

=item * B<overwrite> => I<bool>


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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GnuplotUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package App::CSVUtils::paras2csv;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.031'; # VERSION

use App::CSVUtils qw(gen_csv_util);

sub _unescape_field {
    my $val = shift;
    $val =~ s/(\\:|\\n|\\\\|[^\\:]+)/$1 eq "\\\\" ? "\\" : $1 eq "\\n" ? "\n" : $1 eq "\\:" ? ":" : $1/eg;
    $val;
}

sub _unescape_value {
    my $val = shift;
    $val =~ s/(\\n|\\\\|[^\\]+)/$1 eq "\\\\" ? "\\" : $1 eq "\\n" ? "\n" : $1/eg;
    $val;
}

sub _parse_line {
    my $line = shift;
    $line =~ s/\R //g;
    $line =~ /((?:[^\\:]+|\\n|\\\\|\\:)+): (.*)/ or return;
    my $field = _unescape_field($1);
    my $value = _unescape_value($2);
    ($field, $value);
}

sub _parse_para {
    my ($r, $para, $idx) = @_;

    my @h;
    while ($para =~ s/\A(.+(?:\R .*)*)(?:\R|\z)//g) {
        #say "D:line=<$1>, para=<$para>";
        my ($field, $val) = _parse_line($1);
        defined $field or die [400, "Paragraph[$idx]: Can't parse line $1"];
        if ($r->{util_args}{trim_header}) {
            $field =~ s/\A\s+//;
            $field =~ s/\s+\z//;
        } elsif ($r->{util_args}{ltrim_header}) {
            $field =~ s/\A\s+//;
        } elsif ($r->{util_args}{rtrim_header}) {
            $field =~ s/\s+\z//;
        }
        push @h, $field, $val;
    }
    @h;
}

gen_csv_util(
    name => 'paras2csv',
    summary => 'Convert paragraphs to CSV',
    description => <<'_',

This utility is the counterpart of the <prog:csv2paras> utility. See its
documentation for more details.

Keywords: paragraphs, cards, pages, headers

_
    add_args => {
        input_file => {
            schema => 'filename*',
            default => '-',
            pos => 0,
        },
        trim_header => {
            schema => 'bool*',
        },
        rtrim_header => {
            schema => 'bool*',
        },
        ltrim_header => {
            schema => 'bool*',
        },
    },
    add_args_rels => {
        'choose_one&' => [ [qw/trim_header rtrim_header ltrim_header/] ],
    },
    links => [
        {url=>'prog:csv2paras'},
    ],
    tags => ['category:converting'],

    examples => [
        {
            summary => 'Convert paragraphs format to CSV',
            src => '[[prog]] - OUTPUT.csv',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    reads_csv => 0,

    after_read_input => sub {
        my $r = shift;

        my $fh;
        if ($r->{util_args}{input_file} eq '-') {
            $fh = \*STDIN;
        } else {
            open $fh, "<", $r->{util_args}{input_file}
                or die [500, "Can't read file '$r->{util_args}{input_file}: $!"];
        }

        local $/ = "";
        my $i = 0;
        while (my $para = <$fh>) {
            $para =~ s/\R{2}\z//;
            #say "D:para=<$para>";
            my @h = _parse_para($r, $para, $i);
            $i++;
            if ($i == 1) {
                my @h2 = @h;
                my $j = 0;
                while (my ($field, $value) = splice @h2, 0, 2) {
                    $r->{output_fields}[$j] = $field;
                    $r->{output_fields_idx}{$field} = $j;
                    $j++;
                }
            }
            my @vals;
            while (my ($field, $value) = splice @h, 0, 2) {
                push @vals, $value;
            }
            $r->{code_print_row}->(\@vals);
        }
    },
);

1;
# ABSTRACT: Convert paragraphs to CSV

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::paras2csv - Convert paragraphs to CSV

=head1 VERSION

This document describes version 1.031 of App::CSVUtils::paras2csv (from Perl distribution App-CSVUtils), released on 2023-08-06.

=head1 FUNCTIONS


=head2 paras2csv

Usage:

 paras2csv(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert paragraphs to CSV.

This utility is the counterpart of the L<csv2paras> utility. See its
documentation for more details.

Keywords: paragraphs, cards, pages, headers

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input_file> => I<filename> (default: "-")

(No description)

=item * B<ltrim_header> => I<bool>

(No description)

=item * B<output_always_quote> => I<bool> (default: 0)

Whether to always quote values.

When set to false (the default), values are quoted only when necessary:

 field1,field2,"field three contains comma (,)",field4

When set to true, then all values will be quoted:

 "field1","field2","field three contains comma (,)","field4"

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--input-escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename.

Use C<-> to output to stdout (the default if you don't specify this option).

Encoding of output file is assumed to be UTF-8.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--input-quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_quote_empty> => I<bool> (default: 0)

Whether to quote empty values.

When set to false (the default), empty values are not quoted:

 field1,field2,,field4

When set to true, then empty values will be quoted:

 field1,field2,"",field4

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--input-sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--input-tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<rtrim_header> => I<bool>

(No description)

=item * B<trim_header> => I<bool>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CSVUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CSVUtils>.

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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

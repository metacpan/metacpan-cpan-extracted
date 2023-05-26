package App::CSVUtils::csv2paras;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-04-01'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.024'; # VERSION

use App::CSVUtils qw(gen_csv_util);
use String::Pad qw(pad);

sub _escape_value {
    my $val = shift;
    $val =~ s/(\\|\n)/$1 eq "\\" ? "\\\\" : "\\n\n "/eg;
    $val;
}

sub _escape_header {
    my $val = shift;
    $val =~ s/(\\|\n|:)/$1 eq "\\" ? "\\\\" : $1 eq ":" ? "\\:" : "\\n\n "/eg;
    $val;
}

gen_csv_util(
    name => 'csv2paras',
    summary => 'Convert CSV to paragraphs',
    description => <<'_',

This utility converts CSV format like this:

    name,email,phone,notes
    bill,bill@example.com,555-1236,+
    lisa,lisa@example.com,555-1235,from work
    jimmy,jimmy@example.com,555-1237,

into paragraphs format like this, which resembles (but not strictly follows)
email headers (RFC-822) or internet message headers (RFC-5322):

    name: bill
    email: bill@example.com
    phone: 555-1236
    notes: +

    name: lisa
    email: lisa@example.com
    phone: 555-1235
    notes: from work

    name: jimmy
    email: jimmy@example.com
    phone: 555-1237
    notes:

Why display in this format? It might be more visually readable or diff-able
especially if there are a lot of fields and/or there are long values.

If a CSV value contains newline, it will escaped "\n", e.g.:

    # CSV
    name,email,phone,notes
    beth,beth@example.com,555-1231,"Has no last name
    Might be adopted sometime by Jimmy"
    matthew,matthew@example.com,555-1239,"Quit

      or fired?"

    # paragraph
    name: beth
    email: beth@example.com
    phone: 555-1231
    notes: Has no last name\nMight be adopted sometime by Jimmy

    name: matthew
    email: matthew@example.com
    phone: 555-1239
    notes: Quit\n\n  or fired?

If a CSV value contains literal "\" (backslash) it will be escaped as "\\".

Long lines are also by default folded at 78 columns (but you can customize with
the `--width` option); if a line is folded a literal backslash is added to the
end of each physical line and the next line will be indented by two spaces:

    notes: This is a long note. This is a long note. This is a long note. This is
      a long note. This is a long note.

A long word is also folded and the next line will be indented by one space:

    notes: Thisisalongwordthisisalongwordthisisalongwordthisisalongwordthisisalongw
     ord

Newline and backslash are also escaped in header; additionally a literal ":"
(colon) is escaped into "\:".

There is option to skip displaying empty fields (`--hide-empty-values`) and to
align the ":" header separator.

Keywords: paragraphs, cards, pages, headers

_
    add_args => {
        width => {
            summary => 'The width at which to fold long lines, -1 means to never fold',
            schema => ['int*', 'clset|'=>[{is=>-1, "is.err_msg"=>"Must be >0 or -1"}, {min=>1}]],
            default => 78,
        },
        hide_empty_values => {
            summary => 'Whether to skip showing empty values',
            schema => 'bool*',
        },
        align => {
            summary => 'Whether to align header separator across lines',
            schema => 'bool*',
            description => <<'_',

Note that if you want to convert the paragraphs back to CSV later using
<prog:paras2csv>, the padding spaces added by this option will become part of
header value, unless you use its `--trim-header` or `--rtrim-header` option.

_
        },
    },
    links => [
        {url=>'prog:paras2csv'},
    ],
    tags => ['category:converting'],

    examples => [
        {
            summary => 'Convert to paragraphs format, show fields alphabetically, do not fold, hide empty values',
            src => 'csv-sort-fields INPUT.csv | [[prog]] --width=-1 --hide-empty-values',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],

    on_input_header_row => sub {
        my $r = shift;

        # these are the keys we add to the stash
        $r->{escaped_headers} = [];
        $r->{longest_header_len} = 0;

        for my $field (@{ $r->{input_fields} }) {
            push @{ $r->{escaped_headers} }, _escape_header($field);
            my $l = length($r->{escaped_headers}[-1]);
            $r->{longest_header_len} = $l if $r->{longest_header_len} < $l;
        }
    },

    on_input_data_row => sub {
        my $r = shift;

        print "\n" if $r->{input_data_rownum} > 1;

        for my $i (0 .. $#{ $r->{input_fields} }) {
            my $val = $r->{input_row}[$i];
            next if $r->{util_args}{hide_empty_values} && length $val == 0;
            my $line =
                ($r->{util_args}{align} ? pad($r->{escaped_headers}[$i], $r->{longest_header_len}, "r") : $r->{escaped_headers}[$i]).
                ": ".
                _escape_value($val);
            if ($r->{util_args}{width} == -1 || length($line) <= $r->{util_args}{width}) {
                print $line, "\n";
            } else {
                require Text::Wrap::NoStrip;
                local $Text::Wrap::NoStrip::columns = $r->{util_args}{width};
                my $wrapped_line = Text::Wrap::NoStrip::wrap("", " ", $line);
                print $wrapped_line, "\n";
            }
        }
    },

    writes_csv => 0,
);

1;
# ABSTRACT: Convert CSV to paragraphs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils::csv2paras - Convert CSV to paragraphs

=head1 VERSION

This document describes version 1.024 of App::CSVUtils::csv2paras (from Perl distribution App-CSVUtils), released on 2023-04-01.

=head1 FUNCTIONS


=head2 csv2paras

Usage:

 csv2paras(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert CSV to paragraphs.

This utility converts CSV format like this:

 name,email,phone,notes
 bill,bill@example.com,555-1236,+
 lisa,lisa@example.com,555-1235,from work
 jimmy,jimmy@example.com,555-1237,

into paragraphs format like this, which resembles (but not strictly follows)
email headers (RFC-822) or internet message headers (RFC-5322):

 name: bill
 email: bill@example.com
 phone: 555-1236
 notes: +
 
 name: lisa
 email: lisa@example.com
 phone: 555-1235
 notes: from work
 
 name: jimmy
 email: jimmy@example.com
 phone: 555-1237
 notes:

Why display in this format? It might be more visually readable or diff-able
especially if there are a lot of fields and/or there are long values.

If a CSV value contains newline, it will escaped "\n", e.g.:

 # CSV
 name,email,phone,notes
 beth,beth@example.com,555-1231,"Has no last name
 Might be adopted sometime by Jimmy"
 matthew,matthew@example.com,555-1239,"Quit
 
   or fired?"
 
 # paragraph
 name: beth
 email: beth@example.com
 phone: 555-1231
 notes: Has no last name\nMight be adopted sometime by Jimmy
 
 name: matthew
 email: matthew@example.com
 phone: 555-1239
 notes: Quit\n\n  or fired?

If a CSV value contains literal "\" (backslash) it will be escaped as "\".

Long lines are also by default folded at 78 columns (but you can customize with
the C<--width> option); if a line is folded a literal backslash is added to the
end of each physical line and the next line will be indented by two spaces:

 notes: This is a long note. This is a long note. This is a long note. This is
   a long note. This is a long note.

A long word is also folded and the next line will be indented by one space:

 notes: Thisisalongwordthisisalongwordthisisalongwordthisisalongwordthisisalongw
  ord

Newline and backslash are also escaped in header; additionally a literal ":"
(colon) is escaped into "\:".

There is option to skip displaying empty fields (C<--hide-empty-values>) and to
align the ":" header separator.

Keywords: paragraphs, cards, pages, headers

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<align> => I<bool>

Whether to align header separator across lines.

Note that if you want to convert the paragraphs back to CSV later using
L<paras2csv>, the padding spaces added by this option will become part of
header value, unless you use its C<--trim-header> or C<--rtrim-header> option.

=item * B<hide_empty_values> => I<bool>

Whether to skip showing empty values.

=item * B<input_escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--input-tsv> option.

=item * B<input_filename> => I<filename> (default: "-")

Input CSV file.

Use C<-> to read from stdin.

Encoding of input file is assumed to be UTF-8.

=item * B<input_header> => I<bool> (default: 1)

Specify whether input CSV has a header row.

By default, the first row of the input CSV will be assumed to contain field
names (and the second row contains the first data row). When you declare that
input CSV does not have header row (C<--no-input-header>), the first row of the
CSV is assumed to contain the first data row. Fields will be named C<field1>,
C<field2>, and so on.

=item * B<input_quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--input-tsv> option.

=item * B<input_sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--input-tsv> option.

=item * B<input_tsv> => I<true>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--input-sep-char>, C<--input-quote-char>, C<--input-escape-char>
options. If one of those options is specified, then C<--input-tsv> will be
ignored.

=item * B<width> => I<int> (default: 78)

The width at which to fold long lines, -1 means to never fold.


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

=head1 SEE ALSO

L<Acme::MetaSyntactic::newsradio>

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

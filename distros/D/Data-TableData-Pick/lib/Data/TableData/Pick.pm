package Data::TableData::Pick;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-20'; # DATE
our $DIST = 'Data-TableData-Pick'; # DIST
our $VERSION = '0.001'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(pick_table_rows);

our %SPEC;

$SPEC{pick_table_rows} = {
    v => 1.1,
    summary => 'Pick randomly one or more table rows, with some options',
    description => <<'_',

This function takes `table`, a table data (either aos, aoaos, aohos, or a
<pm:Data::TableData::Object> instance) and picks one or more random rows from it
and return the rows in the form of of aoaos or aohos.

No duplicates are picked (i.e. no resampling a.k.a. sampling without
replacement), but of course duplicate rows can still happen if the input table
itself contain duplicate rows.

If the requested number of rows (`n`) exceed the number of rows of the table,
only up to the number of rows of the table are returned.

Weighting option. You can specify the name of column that contains weight.

_
    args => {
        table => {
            summary => 'A table data (either aos, aoaos, aohos, or a Data::TableData::Object instance)',
            schema => 'any*',
            req => 1,
        },
        n => {
            summary => 'Number of rows to pick',
            schema => 'posint*',
            default => 1,
        },
        weight_column => {
            summary => 'Specify column name that contains weight',
            schema => 'str*',
            description => <<'_',

If not specified, all rows will have the equal weight of 1.

Weight must be a non-negative real number.

_
        },
    },
};
sub pick_table_rows {
    require Array::Sample::WeightedRandom;
    require Data::TableData::Object;

    my %args = @_;
    my $weight_column = $args{weight_column};
    my $n = $args{n} // 1;

    my $td = Data::TableData::Object->new($args{table});
    my @ary = map { [$_, defined($weight_column) ? (ref $_ eq 'ARRAY' ? $_->[$weight_column] : $_->{$weight_column}) : 1] } @{ $td->rows };
    [Array::Sample::WeightedRandom::sample_weighted_random_no_replacement(\@ary, $n)];
}

1;
# ABSTRACT: Pick randomly one or more table rows, with some options

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableData::Pick - Pick randomly one or more table rows, with some options

=head1 VERSION

This document describes version 0.001 of Data::TableData::Pick (from Perl distribution Data-TableData-Pick), released on 2022-05-20.

=head1 FUNCTIONS


=head2 pick_table_rows

Usage:

 pick_table_rows(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pick randomly one or more table rows, with some options.

This function takes C<table>, a table data (either aos, aoaos, aohos, or a
L<Data::TableData::Object> instance) and picks one or more random rows from it
and return the rows in the form of of aoaos or aohos.

No duplicates are picked (i.e. no resampling a.k.a. sampling without
replacement), but of course duplicate rows can still happen if the input table
itself contain duplicate rows.

If the requested number of rows (C<n>) exceed the number of rows of the table,
only up to the number of rows of the table are returned.

Weighting option. You can specify the name of column that contains weight.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<n> => I<posint> (default: 1)

Number of rows to pick.

=item * B<table>* => I<any>

A table data (either aos, aoaos, aohos, or a Data::TableData::Object instance).

=item * B<weight_column> => I<str>

Specify column name that contains weight.

If not specified, all rows will have the equal weight of 1.

Weight must be a non-negative real number.


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

Please visit the project's homepage at L<https://metacpan.org/release/Data-TableData-Pick>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-TableData-Pick>.

=head1 SEE ALSO

L<Data::TableData::Object>

L<Array::Sample::WeightedRandom>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-TableData-Pick>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

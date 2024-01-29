package App::TableDataUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-23'; # DATE
our $DIST = 'App-TableDataUtils'; # DIST
our $VERSION = '0.052'; # VERSION

our %SPEC;

$SPEC{gen_rand_hash} = {
    v => 1.1,
    summary => 'Generate hash with random keys/values',
    args => {
        num_keys => {
            summary => 'Number of keys',
            schema => ['int*', min=>0],
            default => 10,
            cmdline_aliases => {n=>{}},
            pos => 0,
        },
    },
};
sub gen_rand_hash {
    my %args = @_;

    my $hash = {};

    for my $i (1..$args{num_keys}) {
        my $key;
        while (1) {
            $key = join("", map {["a".."z"]->[26*rand()]} 1..8);
            last unless exists $hash->{$key};
        }
        $hash->{$key} = $i;
    }
    [200, "OK", $hash];
}

$SPEC{gen_rand_aos} = {
    v => 1.1,
    summary => 'Generate array of scalars with random values',
    args => {
        num_elems => {
            summary => 'Number of elements',
            schema => ['int*', min=>0],
            default => 10,
            cmdline_aliases => {n=>{}},
            pos => 0,
        },
    },
};
sub gen_rand_aos {
    my %args = @_;

    my $aos = [];

    for my $i (1..$args{num_elems}) {
        push @$aos, $i;
    }
    [200, "OK", $aos];
}

$SPEC{gen_rand_aoaos} = {
    v => 1.1,
    summary => 'Generate array of (array of scalars) with random values',
    args => {
        num_rows => {
            summary => 'Number of rows',
            schema => ['int*', min=>0],
            default => 10,
            cmdline_aliases => {r=>{}},
            pos => 0,
        },
        num_columns => {
            summary => 'Number of columns',
            schema => ['int*', min=>0, max=>255],
            default => 3,
            cmdline_aliases => {c=>{}},
            pos => 1,
        },
    },
};
sub gen_rand_aoaos {
    my %args = @_;

    my $aoaos = [];

    for my $i (1..$args{num_rows}) {
        my $row = [];
        for my $j (1..$args{num_columns}) {
            push @$row, ($i-1)*$args{num_columns} + $j;
        }
        push @$aoaos, $row;
    }
    [200, "OK", $aoaos];
}

$SPEC{gen_rand_aohos} = {
    v => 1.1,
    summary => 'Generate array of (hash of scalars) with random values',
    args => {
        num_rows => {
            summary => 'Number of rows',
            schema => ['int*', min=>0],
            default => 10,
            cmdline_aliases => {r=>{}},
            pos => 0,
        },
        num_columns => {
            summary => 'Number of columns',
            schema => ['int*', min=>0, max=>255],
            default => 3,
            cmdline_aliases => {c=>{}},
            pos => 1,
        },
    },
};
sub gen_rand_aohos {
    my %args = @_;

    my $aohos = [];

    my @columns;
    {
        my $gen_hash_res = gen_rand_hash(num_keys => $args{num_columns});
        @columns = keys %{ $gen_hash_res->[2] };
    }

    for my $i (1..$args{num_rows}) {
        my $row = {};
        for my $j (0..$#columns) {
            $row->{$columns[$j]} = ($i-1)*$args{num_columns} + $j;
        }
        push @$aohos, $row;
    }
    [200, "OK", $aohos];
}

$SPEC{td2csv} = {
    v => 1.1,
    summary => 'Convert table data in STDIN to CSV',
    description => <<'_',

Actually alias for `td as-csv`.

_
    args => {
    },
};
sub td2csv {
    require App::td;

    my %args = @_;

    App::td::td(action => 'as-csv');
}

1;
# ABSTRACT: Routines related to table data

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TableDataUtils - Routines related to table data

=head1 VERSION

This document describes version 0.052 of App::TableDataUtils (from Perl distribution App-TableDataUtils), released on 2023-09-23.

=head1 DESCRIPTION

This distribution includes a few utility scripts related to table data.

=over

=item * L<gen-rand-table>

=item * L<td2csv>

=item * L<this-tabledata-mod>

=back

=head1 FUNCTIONS


=head2 gen_rand_aoaos

Usage:

 gen_rand_aoaos(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate array of (array of scalars) with random values.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num_columns> => I<int> (default: 3)

Number of columns.

=item * B<num_rows> => I<int> (default: 10)

Number of rows.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 gen_rand_aohos

Usage:

 gen_rand_aohos(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate array of (hash of scalars) with random values.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num_columns> => I<int> (default: 3)

Number of columns.

=item * B<num_rows> => I<int> (default: 10)

Number of rows.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 gen_rand_aos

Usage:

 gen_rand_aos(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate array of scalars with random values.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num_elems> => I<int> (default: 10)

Number of elements.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 gen_rand_hash

Usage:

 gen_rand_hash(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate hash with random keysE<sol>values.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num_keys> => I<int> (default: 10)

Number of keys.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 td2csv

Usage:

 td2csv() -> [$status_code, $reason, $payload, \%result_meta]

Convert table data in STDIN to CSV.

Actually alias for C<td as-csv>.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-TableDataUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TableDataUtils>.

=head1 SEE ALSO

L<td> from L<App::td>

L<TableDef>

L<tabledata> from L<App::tabledata>, L<TableData>, C<TableData::*> modules.

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

This software is copyright (c) 2023, 2020, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TableDataUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package App::TableDataUtils;

our $DATE = '2015-09-13'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

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

1;
# ABSTRACT: Routines related to table data

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TableDataUtils - Routines related to table data

=head1 VERSION

This document describes version 0.03 of App::TableDataUtils (from Perl distribution App-TableDataUtils), released on 2015-09-13.

=head1 DESCRIPTION

This distribution includes a few utility scripts related to table data.

=over

=item * L<gen-rand-table>

=back

The main CLI, L<tabledata>, is currently split into its own distribution.

=head1 FUNCTIONS


=head2 gen_rand_aoaos(%args) -> [status, msg, result, meta]

Generate array of (array of scalars) with random values.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num_columns> => I<int> (default: 3)

Number of columns.

=item * B<num_rows> => I<int> (default: 10)

Number of rows.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 gen_rand_aohos(%args) -> [status, msg, result, meta]

Generate array of (hash of scalars) with random values.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num_columns> => I<int> (default: 3)

Number of columns.

=item * B<num_rows> => I<int> (default: 10)

Number of rows.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 gen_rand_aos(%args) -> [status, msg, result, meta]

Generate array of scalars with random values.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num_elems> => I<int> (default: 10)

Number of elements.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 gen_rand_hash(%args) -> [status, msg, result, meta]

Generate hash with random keys/values.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num_keys> => I<int> (default: 10)

Number of keys.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 SEE ALSO

L<App::tabledata>

L<TableDef>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-TableDataUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TableDataUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TableDataUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

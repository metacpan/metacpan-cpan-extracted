package App::LTSVUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-19'; # DATE
our $DIST = 'App-LTSVUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

my %args_common = (
);

my %arg_filename_0 = (
    filename => {
        summary => 'Input LTSV file',
        schema => 'filename*',
        description => <<'_',

Use `-` to read from stdin.

_
        req => 1,
        pos => 0,
        cmdline_aliases => {f=>{}},
    },
);

my %arg_filename_1 = (
    filename => {
        summary => 'Input LTSV file',
        description => <<'_',

Use `-` to read from stdin.

_
        schema => 'filename*',
        req => 1,
        pos => 1,
        cmdline_aliases => {f=>{}},
    },
);

$SPEC{ltsvutil} = {
    v => 1.1,
    summary => 'Perform action on a LTSV file',
    'x.no_index' => 1,
    args => {
        %args_common,
        action => {
            schema => ['str*', in=>[
                'dump',
                '2csv',
            ]],
            req => 1,
            pos => 0,
            cmdline_aliases => {a=>{}},
        },
        %arg_filename_1,
    },
    args_rels => {
    },
};
sub ltsvutil {
    my %args = @_;
    my $action = $args{action};

    my $res = "";
    my $i = 0;

    my $fh;
    if ($args{filename} eq '-') {
        $fh = *STDIN;
    } else {
        open $fh, "<", $args{filename} or
            return [500, "Can't open input filename '$args{filename}': $!"];
    }
    binmode $fh, ":encoding(utf8)";

    my $code_getline = sub {
        my $row0 = <$fh>;
        return undef unless defined $row0;
        chomp($row0);
        my $row = {};
        for my $col0 (split /\t/, $row0) {
            $col0 =~ /(.+):(.*)/ or die "Row $i: Invalid column '$col0': must be in LABEL:VAL format\n";
            $row->{$1} = $2;
        }
        $row;
    };

    my $rows = [];
    my %col_idxs;

    while (my $row = $code_getline->()) {
        $i++;
        if ($action eq 'dump') {
            push @$rows, $row;
        } elsif ($action eq '2csv' || $action eq '2tsv') {
            push @$rows, $row;
            for my $k (sort keys %$row) {
                next if defined $col_idxs{$k};
                $col_idxs{$k} = keys(%col_idxs);
            }
        } else {
            return [400, "Unknown action '$action'"];
        }
    } # while getline()

    my @cols = sort { $col_idxs{$a} <=> $col_idxs{$b} } keys %col_idxs;

    if ($action eq 'dump') {
        return [200, "OK", $rows];
    } elsif ($action eq '2csv') {
        require Text::CSV_XS;
        my $csv = Text::CSV_XS->new({binary=>1});
        $csv->print(\*STDOUT, \@cols);
        print "\n";
        for my $row (@$rows) {
            $csv->print(\*STDOUT, [map {$row->{$_} // ''} @cols]);
            print "\n";
        }
    } elsif ($action eq '2tsv') {
        if (@cols) {
            print join("\t", @cols) . "\n";
            for my $row (@$rows) {
                print join("\t", map { $row->{$_} // '' } @cols) . "\n";
            }
        }
    } else {
        return [500, "Unknown action '$action'"];
    }

    [200, "OK", $res, {"cmdline.skip_format"=>1}];
} # ltsvutil

$SPEC{ltsv_dump} = {
    v => 1.1,
    summary => 'Dump LTSV as data structure (array of hashes)',
    args => {
        %args_common,
        %arg_filename_0,
    },
};
sub ltsv_dump {
    my %args = @_;
    ltsvutil(%args, action=>'dump');
}

$SPEC{ltsv2csv} = {
    v => 1.1,
    summary => 'Convert LTSV to CSV',
    args => {
        %args_common,
        %arg_filename_0,
    },
};
sub ltsv2csv {
    my %args = @_;
    ltsvutil(%args, action=>'2csv');
}

$SPEC{ltsv2tsv} = {
    v => 1.1,
    summary => 'Convert LTSV to TSV',
    args => {
        %args_common,
        %arg_filename_0,
    },
};
sub ltsv2tsv {
    my %args = @_;
    ltsvutil(%args, action=>'2tsv');
}

1;
# ABSTRACT: CLI utilities related to LTSV

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LTSVUtils - CLI utilities related to LTSV

=head1 VERSION

This document describes version 0.001 of App::LTSVUtils (from Perl distribution App-LTSVUtils), released on 2019-12-19.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<dump-ltsv>

=item * L<ltsv-dump>

=item * L<ltsv2csv>

=item * L<ltsv2tsv>

=back

=head1 FUNCTIONS


=head2 ltsv2csv

Usage:

 ltsv2csv(%args) -> [status, msg, payload, meta]

Convert LTSV to CSV.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input LTSV file.

Use C<-> to read from stdin.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 ltsv2tsv

Usage:

 ltsv2tsv(%args) -> [status, msg, payload, meta]

Convert LTSV to TSV.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input LTSV file.

Use C<-> to read from stdin.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 ltsv_dump

Usage:

 ltsv_dump(%args) -> [status, msg, payload, meta]

Dump LTSV as data structure (array of hashes).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input LTSV file.

Use C<-> to read from stdin.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(ltsvutil)$

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-LTSVUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LTSVUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LTSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://ltsv.org>

L<App::TSVUtils>

L<App::CSVUtils>

L<App::SerializeUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

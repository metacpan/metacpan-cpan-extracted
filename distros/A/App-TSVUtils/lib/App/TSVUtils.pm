package App::TSVUtils;

our $DATE = '2019-12-19'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

my %args_common = (
);

my %arg_filename_0 = (
    filename => {
        summary => 'Input TSV file',
        schema => 'filename*',
        req => 1,
        pos => 0,
        cmdline_aliases => {f=>{}},
    },
);

my %arg_filename_1 = (
    filename => {
        summary => 'Input TSV file',
        description => <<'_',

Use `-` to read from stdin.

_
        schema => 'filename*',
        req => 1,
        pos => 1,
        cmdline_aliases => {f=>{}},
    },
);

$SPEC{tsvutil} = {
    v => 1.1,
    summary => 'Perform action on a TSV file',
    'x.no_index' => 1,
    args => {
        %args_common,
        action => {
            schema => ['str*', in=>[
                'dump',
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
sub tsvutil {
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
        ;
    my $code_getline = sub {
        my $row0 = <$fh>;
        return undef unless defined $row0;
        chomp($row0);
        [split /\t/, $row0];
    };

    my $rows = [];

    while (my $row = $code_getline->()) {
        $i++;
        if ($action eq 'dump') {
            push @$rows, $row;
        } else {
            return [400, "Unknown action '$action'"];
        }
    } # while getline()

    if ($action eq 'dump') {
        return [200, "OK", $rows];
    }

    [200, "OK", $res, {"cmdline.skip_format"=>1}];
} # tsvutil

$SPEC{tsv_dump} = {
    v => 1.1,
    summary => 'Dump TSV as data structure (array of arrays)',
    args => {
        %args_common,
        %arg_filename_0,
    },
};
sub tsv_dump {
    my %args = @_;
    tsvutil(%args, action=>'dump');
}

1;
# ABSTRACT: CLI utilities related to TSV

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TSVUtils - CLI utilities related to TSV

=head1 VERSION

This document describes version 0.004 of App::TSVUtils (from Perl distribution App-TSVUtils), released on 2019-12-19.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<dump-tsv>

=item * L<tsv-dump>

=back

=head1 FUNCTIONS


=head2 tsv_dump

Usage:

 tsv_dump(%args) -> [status, msg, payload, meta]

Dump TSV as data structure (array of arrays).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input TSV file.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(tsvutil)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-TSVUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TSVUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::SerializeUtils>

L<App::LTSVUtils>, which includes utilities like L<ltsv2tsv>, L<tsv2ltsv>, among
others.

L<App::CSVUtils>, which includes L<csv2tsv>, L<tsv2csv> among others. Scripts
included in App::CSVUtils also support reading TSV via C<--tsv> flag.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

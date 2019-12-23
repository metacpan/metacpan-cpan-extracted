package App::sorted;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-15'; # DATE
our $DIST = 'App-sorted'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Sort::Sub ();

our %SPEC;

$Sort::Sub::argsopt_sortsub{sort_sub}{cmdline_aliases} = {S=>{}};
$Sort::Sub::argsopt_sortsub{sort_args}{cmdline_aliases} = {A=>{}};

$SPEC{sorted} = {
    v => 1.1,
    summary => 'Check if lines of a file are sorted',
    description => <<'_',

Assuming `file.txt`'s content is:

    1
    2
    3

These will return success:

    % sorted file.txt
    % sorted -S numerically file.txt

But these will not:

    % sorted -S 'numerically<r>' file.txt
    % sorted -S 'asciibetically<r>' file.txt

Another example, assuming `file.txt`'s content is:

    1
    zz
    AAA
    cccc

then this will return success:

    % sorted -S by_length file.txt
    % sorted -q -S by_length file.txt  ;# -q silences output, it just returns appropriate exit code

while these will not:

    % sorted file.txt
    % sorted -S 'asciibetically<i>' file.txt
    % sorted -S 'by_length<r>' file.txt

_
    args => {
        file => {
            schema => 'filename*',
            default => '-',
            pos => 0,
        },
        %Sort::Sub::argsopt_sortsub,
        quiet => {
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
    },
    links => [
        {
            url => 'prog:is-sorted',
            description => <<'_',

The <prog:sorted> script is inspired by, and an alternative for,
<prog:is-sorted> from <pm:File::IsSorted> by SHLOMIF. `sorted` adds the ability
to use <pm:Sort::Sub> routines.

_
        }
    ],
};
sub sorted {
    my %args = @_;

    my $fh;
    if ($args{file} eq '-') {
        $fh = *STDIN;
    } else {
        open $fh, "<", $args{file}
            or return [500, "Can't open '$args{file}': $!"];
    }

    my $sort_sub  = $args{sort_sub}  // 'asciibetically';
    my $sort_args = $args{sort_args} // {};
    my $cmp = Sort::Sub::get_sorter($sort_sub, $sort_args);

    my $sorted = 1;
    my ($prev_line, $cur_line);
    my $line_num = 0;
    while (defined (my $cur_line = <$fh>)) {
        $line_num++;
        unless (defined $prev_line) {
            $prev_line = $cur_line;
            next;
        }
        if ($cmp->($prev_line, $cur_line) > 0) {
            $sorted = 0;
            last;
        }
        $prev_line = $cur_line;
    }

    my $msg = "File is ".($sorted ? "" : "NOT ")."sorted";
    [
        200,
        "OK",
        $msg,
        {
            'cmdline.exit_code' => $sorted ? 0:1,
            ($args{quiet} ? ('cmdline.result' => '') : ()),
            'func.line_num' => $line_num,
            'func.line1' => $prev_line,,
            'func.line2' => $cur_line,
        },
    ];
}

1;
# ABSTRACT: Check if lines of a file are sorted

__END__

=pod

=encoding UTF-8

=head1 NAME

App::sorted - Check if lines of a file are sorted

=head1 VERSION

This document describes version 0.001 of App::sorted (from Perl distribution App-sorted), released on 2019-12-15.

=head1 SYNOPSIS

See L<sorted>.

=head1 FUNCTIONS


=head2 sorted

Usage:

 sorted(%args) -> [status, msg, payload, meta]

Check if lines of a file are sorted.

Assuming C<file.txt>'s content is:

 1
 2
 3

These will return success:

 % sorted file.txt
 % sorted -S numerically file.txt

But these will not:

 % sorted -S 'numerically<r>' file.txt
 % sorted -S 'asciibetically<r>' file.txt

Another example, assuming C<file.txt>'s content is:

 1
 zz
 AAA
 cccc

then this will return success:

 % sorted -S by_length file.txt
 % sorted -q -S by_length file.txt  ;# -q silences output, it just returns appropriate exit code

while these will not:

 % sorted file.txt
 % sorted -S 'asciibetically<i>' file.txt
 % sorted -S 'by_length<r>' file.txt

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file> => I<filename> (default: "-")

=item * B<quiet> => I<bool>

=item * B<sort_args> => I<hash>

Arguments to pass to the Sort::Sub::* routine.

=item * B<sort_sub> => I<sortsub::spec>

Name of a Sort::Sub::* module (without the prefix).

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

Please visit the project's homepage at L<https://metacpan.org/release/App-sorted>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-sorted>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-sorted>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<is-sorted>. The L<sorted> script is inspired by, and an alternative for,
L<is-sorted> from L<File::IsSorted> by SHLOMIF. C<sorted> adds the ability
to use L<Sort::Sub> routines.

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

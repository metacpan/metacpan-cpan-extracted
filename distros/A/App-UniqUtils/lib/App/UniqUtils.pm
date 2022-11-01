package App::UniqUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-08'; # DATE
our $DIST = 'App-UniqUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to unique lines and/or Unix uniq utility',
};

$SPEC{lookup_lines} = {
    v => 1.1,
    summary => 'Report or omit lines found in another "reference" file',
    args => {
        reference_file => {
            summary => 'Path to reference file',
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        test_files => {
            schema => ['array*', {of=>'filename*'}],
            pos => 1,
            slurpy => 1,
        },
        # XXX option: ci
        invert_match => {
            schema => 'bool*',
            description => <<'_',

By default the utility will report lines that are found in the reference file.
If this option is specified, then will instead report lines that are *not* found
in reference file.

_
            cmdline_aliases => {v=>{}},
        },
    },
    description => <<'_',

By default will report lines that are found in the reference file (unless when
`-v` a.k.a. `--invert-match` option is specified, in which case will report
lines that are *not* found in reference file).

_
};
sub lookup_lines {
    my %args = @_;

    open my $fh, "<", $args{reference_file}
        or return [500, "Cannot open reference file '$args{reference_file}': $!"];
    my %mem;
    while (my $line = <$fh>) {
        chomp $line;
        $mem{$line}++;
    }

  FILE:
    for my $file (@{ $args{test_files} // ["-"] }) {
        my $fh;
        if ($file eq '-') {
            $fh = \*STDIN;
        } else {
            open $fh, "<", $file or do {
                warn "Cannot open test file '$file': $!, skipped";
                next FILE;
            };
        }

        while (my $line = <$fh>) {
            chomp $line;
            if ($mem{$line}) {
                if (!$args{invert_match}) { say $line }
            } else {
                if ( $args{invert_match}) { say $line }
            }
        }
    }

    [200];
}

1;
# ABSTRACT: Utilities related to unique lines and/or Unix uniq utility

__END__

=pod

=encoding UTF-8

=head1 NAME

App::UniqUtils - Utilities related to unique lines and/or Unix uniq utility

=head1 VERSION

This document describes version 0.001 of App::UniqUtils (from Perl distribution App-UniqUtils), released on 2022-08-08.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<lookup-lines>

=back

=head1 FUNCTIONS


=head2 lookup_lines

Usage:

 lookup_lines(%args) -> [$status_code, $reason, $payload, \%result_meta]

Report or omit lines found in another "reference" file.

By default will report lines that are found in the reference file (unless when
C<-v> a.k.a. C<--invert-match> option is specified, in which case will report
lines that are I<not> found in reference file).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<invert_match> => I<bool>

By default the utility will report lines that are found in the reference file.
If this option is specified, then will instead report lines that are I<not> found
in reference file.

=item * B<reference_file>* => I<filename>

Path to reference file.

=item * B<test_files> => I<array[filename]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-UniqUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-UniqUtils>.

=head1 SEE ALSO

L<nauniq> from L<App::nauniq>

L<setop> from L<App::setop>, especially C<setop --diff>.

L<csv-lookup-fields> from L<App::CSVUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar (on netbook-dell-xps13)

perlancar (on netbook-dell-xps13) <perlancar@gmail.com>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-UniqUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package App::podtohtml;

our $DATE = '2017-02-06'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{podtohtml} = {
    v => 1.1,
    summary => 'Convert POD to HTML',
    description => <<'_',

This is a thin wrapper for <pm:Pod::Html> and an alternative CLI to
<prog:pod2html> to remove some annoyances that I experience with `pod2html`,
e.g. the default cache directory being `.` (so it leaves `.tmp` files around).
This CLI also offers tab completion.

It does not yet offer as many options as `pod2html`.

_
    args => {
        infile => {
            summary => 'Input file (POD)',
            description => <<'_',

If not found, will search in for .pod or .pm files in `@INC`.

_
            schema => 'perl::pod_or_pm_filename*',
            default => '-',
            pos => 0,
        },
        outfile => {
            schema => 'filename*',
            pos => 1,
        },
        browser => {
            summary => 'Instead of outputing HTML to STDOUT/file, '.
                'view it in browser',
            schema => ['bool*', is=>1],
        },
    },
    args_rels => {
        choose_one => [qw/outfile browser/],
    },
    examples => [
        {
            argv => [qw/some.pod/],
            summary => 'Convert POD file to HTML, print result to STDOUT',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/some.pod --browser/],
            summary => 'Convert POD file to HTML, show result in browser',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub podtohtml {
    require File::Temp;
    require Pod::Html;

    my %args = @_;

    my $infile  = $args{infile} // '-';
    my $outfile = $args{outfile} // '-';
    my $browser = $args{browser};

    my $cachedir = File::Temp::tempdir(CLEANUP => 1);

    my ($fh, $tempoutfile) = File::Temp::tempfile();

    unless (-f $infile) {
        return [404, "No such file '$infile'"];
    }

    Pod::Html::pod2html(
        ($infile eq '-' ? () : ("--infile=$infile")),
        "--outfile=$tempoutfile.html",
        "--cachedir=$cachedir",
    );

    if ($browser) {
        require Browser::Open;
        my $err = Browser::Open::open_browser("file:$tempoutfile.html");
        return [500, "Can't open browser"] if $err;
        [200];
    } elsif ($outfile eq '-') {
        local $/;
        open my $ofh, "<", "$tempoutfile.html";
        my $content = <$ofh>;
        [200, "OK", $content, {'cmdline.skip_format' => 1}];
    } else {
        [200, "OK"];
    }
}

1;
# ABSTRACT: Convert POD to HTML

__END__

=pod

=encoding UTF-8

=head1 NAME

App::podtohtml - Convert POD to HTML

=head1 VERSION

This document describes version 0.002 of App::podtohtml (from Perl distribution App-podtohtml), released on 2017-02-06.

=head1 FUNCTIONS


=head2 podtohtml

Usage:

 podtohtml(%args) -> [status, msg, result, meta]

Convert POD to HTML.

Examples:

=over

=item * Convert POD file to HTML, print result to STDOUT:

 podtohtml( infile => "some.pod");

=item * Convert POD file to HTML, show result in browser:

 podtohtml( infile => "some.pod", browser => 1);

=back

This is a thin wrapper for L<Pod::Html> and an alternative CLI to
L<pod2html> to remove some annoyances that I experience with C<pod2html>,
e.g. the default cache directory being C<.> (so it leaves C<.tmp> files around).
This CLI also offers tab completion.

It does not yet offer as many options as C<pod2html>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<browser> => I<bool>

Instead of outputing HTML to STDOUT/file, view it in browser.

=item * B<infile> => I<perl::pod_or_pm_filename> (default: "-")

Input file (POD).

If not found, will search in for .pod or .pm files in C<@INC>.

=item * B<outfile> => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-podtohtml>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-podtohtml>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-podtohtml>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<pod2html>, L<Pod::Html>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

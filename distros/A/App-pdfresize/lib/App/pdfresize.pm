package App::pdfresize;

use 5.014;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
use File::chdir;
use File::Temp;
use IPC::System::Options -log=>1, -die=>1, 'system';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-20'; # DATE
our $DIST = 'App-pdfresize'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(pdfsize);

our %SPEC;

$SPEC{pdfresize} = {
    v => 1.1,
    summary => 'Resize each page of PDF file to a new dimension',
    description => <<'MARKDOWN',

This utility first splits a PDF to individual pages (using <prog:pdftk>), then
converts each page to JPEG and resizes it (using ImageMagick's <prog:convert>),
then converts back each page to PDF and reassembles the resized pages to a new
PDF.

MARKDOWN
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        resize => {
            summary => 'ImagaMagick resize notation, e.g. "50%x50%", "x720>"',
            schema => 'filename*',
            req => 1,
            pos => 1,
            description => <<'MARKDOWN',

See ImageMagick documentation (e.g. <prog:convert>) for more details, or the
documentation of <prog:calc-image-resized-size>,
<prog:image-resize-notation-to-human> for lots of examples.

MARKDOWN
        },
        quality => {
            schema => ['int*', min=>1, max=>100],
            cmdline_aliases => {q=>{}},
        },
        output_filename => {
            schema => 'filename*',
            pos => 2,
        },
    },
    examples => [
        {
            summary => 'Shrink PDF dimension to 25% original size (half the width, half the height)',
            argv => ['foo.pdf', '50%x50%'],
            test => 0,
        },
        {
            summary => 'Shrink PDF page height to 720p, and use quality 40, name an output',
            argv => ['foo.pdf', 'x720>', '-q40', 'foo-resized.pdf'],
            test => 0,
        },
    ],
    links => [
        {url=>'prog:imgsize'},
    ],
    deps => {
        all => [
            {prog=>'pdftk'},
            {prog=>'convert'},
        ],
    },
};
sub pdfresize {
    my %args = @_;

    my $tempdir = File::Temp::tempdir(CLEANUP => !log_is_debug());
    log_debug "Temporary directory is $tempdir (not cleaned up, for debugging)";

    my $abs_filename = Cwd::abs_path($args{filename})
        or die "Can't convert $args{filename} to absolute path: $!";

    my @pdf_pages;
    my @abs_pdf_resized_pages;
  LOCAL:
    {
        local $CWD = $tempdir;

        log_debug "Splitting PDF to individual pages ...";
        system "pdftk", $abs_filename, "burst";

        @pdf_pages = glob "*.pdf";
        log_debug "Number of pages: %d", scalar(@pdf_pages);

        log_debug "Converting PDF pages to JPGs and resizing  ...";
        for my $pdf_page (@pdf_pages) {
            system "convert", ($args{quality} ? ("-quality", int($args{quality})) : ()), "-resize", $args{resize}, $pdf_page, "$pdf_page.jpg";
        }

        log_debug "Converting resized JPGs back to PDFs ...";
        for my $pdf_page (@pdf_pages) {
            system "convert", "$pdf_page.jpg", "$pdf_page.resized.pdf";
            push @abs_pdf_resized_pages, Cwd::abs_path("$pdf_page.resized.pdf");
        }
    } # LOCAL

    my $output_filename = $args{output_filename} // ($args{filename} =~ s/(\.pdf)?$/-resized.pdf/ir);
    log_debug "Merging individual PDFs to output ...";
    system "pdftk", @abs_pdf_resized_pages, "cat", "output", $output_filename;

    [200];
}

1;
# ABSTRACT: Resize each page of PDF file to a new dimension

__END__

=pod

=encoding UTF-8

=head1 NAME

App::pdfresize - Resize each page of PDF file to a new dimension

=head1 VERSION

This document describes version 0.001 of App::pdfresize (from Perl distribution App-pdfresize), released on 2024-08-20.

=head1 SYNOPSIS

 # Use via pdfsize CLI script

=head1 FUNCTIONS


=head2 pdfresize

Usage:

 pdfresize(%args) -> [$status_code, $reason, $payload, \%result_meta]

Resize each page of PDF file to a new dimension.

Examples:

=over

=item * Shrink PDF dimension to 25% original size (half the width, half the height):

 pdfresize(filename => "foo.pdf", resize => "50%x50%");

Result:

 [
   500,
   "Function died: system(pdftk /home/u1/repos/perl-App-pdfresize/foo.pdf burst) failed: 256 (exited with code 1) at /home/u1/perl5/perlbrew/perls/perl-5.38.2/lib/site_perl/5.38.2/IPC/System/Options.pm line 440.\n",
   undef,
   {
     logs => [
       {
         file    => "/home/u1/perl5/perlbrew/perls/perl-5.38.2/lib/site_perl/5.38.2/Perinci/Access/Schemeless.pm",
         func    => "Perinci::Access::Schemeless::action_call",
         line    => 499,
         package => "Perinci::Access::Schemeless",
         time    => 1724149492,
         type    => "create",
       },
     ],
   },
 ]

=item * Shrink PDF page height to 720p, and use quality 40, name an output:

 pdfresize(
     filename => "foo.pdf",
   resize => "x720>",
   output_filename => "foo-resized.pdf",
   quality => 40
 );

Result:

 [
   500,
   "Function died: system(pdftk /home/u1/repos/perl-App-pdfresize/foo.pdf burst) failed: 256 (exited with code 1) at /home/u1/perl5/perlbrew/perls/perl-5.38.2/lib/site_perl/5.38.2/IPC/System/Options.pm line 440.\n",
   undef,
   {
     logs => [
       {
         file    => "/home/u1/perl5/perlbrew/perls/perl-5.38.2/lib/site_perl/5.38.2/Perinci/Access/Schemeless.pm",
         func    => "Perinci::Access::Schemeless::action_call",
         line    => 499,
         package => "Perinci::Access::Schemeless",
         time    => 1724149492,
         type    => "create",
       },
     ],
   },
 ]

=back

This utility first splits a PDF to individual pages (using L<pdftk>), then
converts each page to JPEG and resizes it (using ImageMagick's L<convert>),
then converts back each page to PDF and reassembles the resized pages to a new
PDF.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

(No description)

=item * B<output_filename> => I<filename>

(No description)

=item * B<quality> => I<int>

(No description)

=item * B<resize>* => I<filename>

ImagaMagick resize notation, e.g. "50%x50%", "x720E<gt>".

See ImageMagick documentation (e.g. L<convert>) for more details, or the
documentation of L<calc-image-resized-size>,
L<image-resize-notation-to-human> for lots of examples.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-pdfresize>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-pdfresize>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-pdfresize>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

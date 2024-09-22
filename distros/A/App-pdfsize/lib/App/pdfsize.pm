package App::pdfsize;

use strict;
use warnings;

use App::imgsize ();
use Exporter qw(import);
use File::Temp;
use IPC::System::Options -log=>1, 'system';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-20'; # DATE
our $DIST = 'App-pdfsize'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(pdfsize);

our %SPEC;

$SPEC{pdfsize} = {
    v => 1.1,
    summary => 'Show dimensions of PDF files',
    description => <<'MARKDOWN',

This is basically just a thin wrapper for <prog:imgsize>. It extracts the first
page of a PDF (currently using <prog:pdftk>: `pdftk IN.pdf cat 1 output
/tmp/SOMEOUT.pdf`), then convert the 1-page PDF to JPEG using ImageMagick's
<prog:convert> utility, then run *imgsize* on the JPEG.

MARKDOWN
    args => {
        %{ $App::imgsize::SPEC{imgsize}{args} },
    },
    examples => [
        {
            args => {filenames => ['foo.pdf']},
            result => [200, "OK", '640x480'],
            test => 0,
        },
        {
            args => {filenames => ['foo.pdf'], detail=>1},
            result => [200, "OK", [
                {filename => '/tmp/foo.pdf.jpg', filesize => 23844, width => 640, height => 480, res_name => "VGA"},
            ], $App::imgsize::res_meta],
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
sub pdfsize {
    my %args = @_;

    my @jpg_filenames;
    for my $filename (@{ delete $args{filenames} }) {
        unless (-f $filename) {
            warn "No such file or not a file: $filename, skipped\n";
            next;
        }

        my ($temp1_fh, $temp1_filename) = File::Temp::tempfile(undef, SUFFIX=>".pdf");
        my ($temp2_fh, $temp2_filename) = File::Temp::tempfile(undef, SUFFIX=>".jpg");

        system "pdftk", $filename, "cat", 1, "output", $temp1_filename;
        if ($?) {
            warn "Can't extract first page using pdftk $filename: $!";
            next;
        }

        system "convert", $temp1_filename, $temp2_filename;
        if ($?) {
            warn "Can't convert $temp1_filename to $temp2_filename: $!";
            next;
        }

        push @jpg_filenames, $temp2_filename;
    }

    App::imgsize::imgsize(%args, filenames => \@jpg_filenames);
}

1;
# ABSTRACT: Show dimensions of PDF files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::pdfsize - Show dimensions of PDF files

=head1 VERSION

This document describes version 0.001 of App::pdfsize (from Perl distribution App-pdfsize), released on 2024-08-20.

=head1 SYNOPSIS

 # Use via pdfsize CLI script

=head1 FUNCTIONS


=head2 pdfsize

Usage:

 pdfsize(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show dimensions of PDF files.

Examples:

=over

=item * Example #1:

 pdfsize(filenames => ["foo.pdf"]); # -> [200, "OK", "640x480", {}]

=item * Example #2:

 pdfsize(filenames => ["foo.pdf"], detail => 1);

Result:

 [
   200,
   "OK",
   [
     {
       filename => "/tmp/foo.pdf.jpg",
       filesize => 23844,
       width    => 640,
       height   => 480,
       res_name => "VGA",
     },
   ],
   {
     "table.fields" => ["filename", "filesize", "width", "height", "res_name"],
   },
 ]

=back

This is basically just a thin wrapper for L<imgsize>. It extracts the first
page of a PDF (currently using L<pdftk>: C<pdftk IN.pdf cat 1 output
/tmp/SOMEOUT.pdf>), then convert the 1-page PDF to JPEG using ImageMagick's
L<convert> utility, then run I<imgsize> on the JPEG.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Whether to show detailed records.

The default is to show detailed records when there are more than 1 filenames
specified; when there is only 1 filename, will only show dimension in WxH format
(e.g. 640x480). If this option is specified, will show detailed records even if
there is only one filename specified.

=item * B<filenames>* => I<array[filename]>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-pdfsize>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-pdfsize>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-pdfsize>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package App::imgsize;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-20'; # DATE
our $DIST = 'App-imgsize'; # DIST
our $VERSION = '0.006'; # VERSION

our @EXPORT_OK = qw(imgsize);

our %SPEC;

our $res_meta = {'table.fields' => [qw/filename filesize width height res_name/]};

$SPEC{imgsize} = {
    v => 1.1,
    summary =>
        'Show dimensions of image files',
    args => {
        filenames => {
            'x.name.is_plural' => 1,
            schema => ['array*' => {of => 'filename*'}],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        detail => {
            summary => 'Whether to show detailed records',
            schema => 'bool*',
            description => <<'MARKDOWN',

The default is to show detailed records when there are more than 1 filenames
specified; when there is only 1 filename, will only show dimension in WxH format
(e.g. 640x480). If this option is specified, will show detailed records even if
there is only one filename specified.

MARKDOWN
            cmdline_aliases => {l=>{}},
        },
    },
    examples => [
        {
            args => {filenames => ['foo.jpg']},
            result => [200, "OK", '640x480'],
            test => 0,
        },
        {
            args => {filenames => ['foo.jpg'], detail=>1},
            result => [200, "OK", [
                {filename => 'foo.jpg', filesize => 23844, width => 640, height => 480, res_name => "VGA"},
            ], $res_meta],
            test => 0,
        },
        {
            args => {filenames => ['foo.jpg', 'bar.png', 'baz.txt']},
            result => [200, "OK", [
                {filename => 'foo.jpg', filesize => 23844, width => 640, height => 480, res_name => "VGA"},
                {filename => 'bar.png', filesize => 87374, width => 400, height => 200, res_name => undef},
                {filename => 'baz.txt', filesize =>  2393, width =>   0, height =>   0, res_name => undef},
            ], $res_meta],
            test => 0,
        },
    ],
    links => [
        {url=>'prog:calc-image-resized-size'},
        {url=>'prog:pdfsize'},
    ],
};
sub imgsize {
    require Display::Resolution;
    require Image::Size;

    my %args = @_;

    my @res;
    for my $filename (@{ $args{filenames} }) {
        unless (-f $filename) {
            warn "No such file or not a file: $filename, skipped\n";
            next;
        }

        my ($x, $y) = Image::Size::imgsize($filename);

        $x ||= 0;
        $y ||= 0;

        my $res_names = Display::Resolution::get_display_resolution_name(
            width => $x, height => $y, all => 1);

        push @res, {
            filename => $filename,
            filesize => (-s $filename),
            width => $x,
            height => $y,
            res_name => $res_names ? join(", ", @$res_names) : undef,
        };
    }

    if ($args{detail} || @res > 1) {
        [200, "OK", \@res, $res_meta];
    } else {
        [200, "OK", sprintf("%dx%d", $res[0]{width}, $res[0]{height})];
    }
}

1;
# ABSTRACT: Show dimensions of image files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::imgsize - Show dimensions of image files

=head1 VERSION

This document describes version 0.006 of App::imgsize (from Perl distribution App-imgsize), released on 2024-08-20.

=head1 SYNOPSIS

 # Use via imgsize CLI script

=head1 FUNCTIONS


=head2 imgsize

Usage:

 imgsize(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show dimensions of image files.

Examples:

=over

=item * Example #1:

 imgsize(filenames => ["foo.jpg"]); # -> [200, "OK", "640x480", {}]

=item * Example #2:

 imgsize(filenames => ["foo.jpg"], detail => 1);

Result:

 [
   200,
   "OK",
   [
     {
       filename => "foo.jpg",
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

=item * Example #3:

 imgsize(filenames => ["foo.jpg", "bar.png", "baz.txt"]);

Result:

 [
   200,
   "OK",
   [
     {
       filename => "foo.jpg",
       filesize => 23844,
       width    => 640,
       height   => 480,
       res_name => "VGA",
     },
     {
       filename => "bar.png",
       filesize => 87374,
       width    => 400,
       height   => 200,
       res_name => undef,
     },
     {
       filename => "baz.txt",
       filesize => 2393,
       width    => 0,
       height   => 0,
       res_name => undef,
     },
   ],
   {
     "table.fields" => ["filename", "filesize", "width", "height", "res_name"],
   },
 ]

=back

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

Please visit the project's homepage at L<https://metacpan.org/release/App-imgsize>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-imgsize>.

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

This software is copyright (c) 2024, 2020, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-imgsize>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

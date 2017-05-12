package App::imgsize;

our $DATE = '2016-10-07'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(imgsize);

my $res_meta = {'table.fields' => [qw/filename filesize width height res_name/]};

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
            greedy => 1,
        },
    },
    examples => [
        {
            args => {filenames => ['foo.jpg', 'bar.png', 'baz.txt']},
            result => [200, "OK", [
                {filename => 'foo.jpg', filesize => 23844, width => 640, height => 480, res_name => "VGA"},
                {filename => 'bar.png', filesize => 87374, width => 400, height => 200, res_name => undef},
                {filename => 'baz.txt', filesize =>  2393, width =>   0, height =>   0, res_name => undef},
            ], $res_meta],
            test => 0,
        }
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

    [200, "OK", \@res, $res_meta];
}

1;
# ABSTRACT: Show dimensions of image files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::imgsize - Show dimensions of image files

=head1 VERSION

This document describes version 0.002 of App::imgsize (from Perl distribution App-imgsize), released on 2016-10-07.

=head1 SYNOPSIS

 # Use via imgsize CLI script

=head1 FUNCTIONS


=head2 imgsize(%args) -> [status, msg, result, meta]

Show dimensions of image files.

Examples:

=over

=item * Example #1:

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

=item * B<filenames>* => I<array[filename]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-imgsize>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-imgsize>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-imgsize>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package App::ImageInfoUtils;

our $DATE = '2021-05-25'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to getting (metadata) information from '.
        'images',
};

our %arg0_files = (
    files => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*' => of => 'filename*', min_len=>1],
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

our %arg0_file = (
    file => {
        schema => ['filename*'],
        req => 1,
        pos => 0,
    },
);

our %argopt_quiet = (
    quiet => {
        summary => "Don't output anything on command-line, ".
            "just return appropriate exit code",
        schema => 'true*',
        cmdline_aliases => {q=>{}, silent=>{}},
    },
);

$SPEC{image_info} = {
    v => 1.1,
    summary => 'Get information about image files',
    args => {
        %arg0_files,
    },
};
sub image_info {
    require Image::Info;

    my %args = @_;

    my @rows;
    for my $file (@{$args{files}}) {
        my $res = Image::Info::image_info($file);
        if ($res->{error}) {
            warn "Can't get image info for '$file': $res->{error}\n";
            next;
        }
        push @rows, { file => $file, %$res };
    }

    return [500, "All failed"] unless @rows;
    if (@{ $args{files} } == 1) {
        return [200, "OK", $rows[0]];
    } else {
        return [200, "OK", \@rows];
    }
}

$SPEC{image_is_portrait} = {
    v => 1.1,
    summary => 'Return exit code 0 if image is portrait',
    description => <<'_',

_
    args => {
        %arg0_file,
        %argopt_quiet,
    },
    examples => [
        {
            summary => 'Produce smaller version of portrait images',
            src => 'for f in *[0-9].jpg;do [[prog]] -q "$f" && convert "$f" -resize 20% "${f/.jpg/.small.jpg}"; done',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub image_is_portrait {
    my %args = @_;

    my $res = image_info(files => [$args{file}]);
    return $res unless $res->[0] == 200;

    my $orientation = $res->[2]{Orientation} // '';
    my $width  = $res->[2]{width};
    my $height = $res->[2]{height};
    return [412, "Can't determine image orientation"] unless $orientation;
    return [412, "Can't determine image width x height"] unless $width && $height;
    my $is_portrait = ($orientation =~ /\A(left|right)_/ ? 1:0) ^ ($width <= $height ? 1:0) ? 1:0;

    [200, "OK", $is_portrait, {
        'cmdline.exit_code' => $is_portrait ? 0:1,
        'cmdline.result' => $args{quiet} ? '' :
            'Image is '.
            ($is_portrait ? "portrait" : "NOT portrait (landscape)"),
    }];
}

$SPEC{image_is_landscape} = {
    v => 1.1,
    summary => 'Return exit code 0 if image is landscape',
    description => <<'_',

_
    args => {
        %arg0_file,
        %argopt_quiet,
    },
    examples => [
        {
            summary => 'Move all landscape images to landscape/',
            src => 'for f in *.jpg;do [[prog]] -q "$f" && mv "$f" landscape/; done',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub image_is_landscape {
    my %args = @_;

    my $res = image_info(files => [$args{file}]);
    return $res unless $res->[0] == 200;

    my $orientation = $res->[2]{Orientation} // '';
    my $width  = $res->[2]{width};
    my $height = $res->[2]{height};
    return [412, "Can't determine image orientation"] unless $orientation;
    return [412, "Can't determine image width x height"] unless $width && $height;
    my $is_landscape = ($orientation =~ /\A(left|right)_/ ? 1:0) ^ ($width <= $height ? 1:0) ? 0:1;

    [200, "OK", $is_landscape, {
        'cmdline.exit_code' => $is_landscape ? 0:1,
        'cmdline.result' => $args{quiet} ? '' :
            'Image is '.
            ($is_landscape ? "landscape" : "NOT landscape (portrait)"),
    }];
}

$SPEC{image_orientation} = {
    v => 1.1,
    summary => "Return orientation of image",
    args => {
        %arg0_file,
    },
};
sub image_orientation {
    my %args = @_;

    my $res = image_info(files => [$args{file}]);
    return $res unless $res->[0] == 200;

    [200, "OK", $res->[2]{Orientation}];
}

1;
# ABSTRACT: Utilities related to getting (metadata) information from images

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ImageInfoUtils - Utilities related to getting (metadata) information from images

=head1 VERSION

This document describes version 0.004 of App::ImageInfoUtils (from Perl distribution App-ImageInfoUtils), released on 2021-05-25.

=head1 FUNCTIONS


=head2 image_info

Usage:

 image_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get information about image files.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[filename]>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or "OK" if status is
200. Third element ($payload) is optional, the actual result. Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 image_is_landscape

Usage:

 image_is_landscape(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return exit code 0 if image is landscape.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file>* => I<filename>

=item * B<quiet> => I<true>

Don't output anything on command-line, just return appropriate exit code.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or "OK" if status is
200. Third element ($payload) is optional, the actual result. Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 image_is_portrait

Usage:

 image_is_portrait(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return exit code 0 if image is portrait.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file>* => I<filename>

=item * B<quiet> => I<true>

Don't output anything on command-line, just return appropriate exit code.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or "OK" if status is
200. Third element ($payload) is optional, the actual result. Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 image_orientation

Usage:

 image_orientation(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return orientation of image.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file>* => I<filename>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or "OK" if status is
200. Third element ($payload) is optional, the actual result. Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ImageInfoUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ImageInfoUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ImageInfoUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

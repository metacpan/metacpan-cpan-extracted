package App::ImageInfoUtils;

our $DATE = '2019-01-28'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

our %SPEC;

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
    },
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

    [200, "OK", $is_portrait, {'cmdline.exit_code' => $is_portrait ? 0:1, 'cmdline.result' => ''}];
}

$SPEC{image_is_landscape} = {
    v => 1.1,
    summary => 'Return exit code 0 if image is landscape',
    description => <<'_',

_
    args => {
        %arg0_file,
    },
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

    [200, "OK", $is_landscape, {'cmdline.exit_code' => $is_landscape ? 0:1, 'cmdline.result' => ''}];
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
# ABSTRACT: Get information about image files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ImageInfoUtils - Get information about image files

=head1 VERSION

This document describes version 0.001 of App::ImageInfoUtils (from Perl distribution App-ImageInfoUtils), released on 2019-01-28.

=head1 FUNCTIONS


=head2 image_info

Usage:

 image_info(%args) -> [status, msg, payload, meta]

Get information about image files.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[filename]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 image_is_landscape

Usage:

 image_is_landscape(%args) -> [status, msg, payload, meta]

Return exit code 0 if image is landscape.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file>* => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 image_is_portrait

Usage:

 image_is_portrait(%args) -> [status, msg, payload, meta]

Return exit code 0 if image is portrait.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file>* => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 image_orientation

Usage:

 image_orientation(%args) -> [status, msg, payload, meta]

Return orientation of image.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file>* => I<filename>

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

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

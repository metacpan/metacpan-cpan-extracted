package App::MediaInfo;

our $DATE = '2019-08-15'; # DATE
our $VERSION = '0.124'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Exporter;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to getting (metadata) information from '.
        'media files',
};

our %arg0_media_multiple = (
    media => {
        summary => 'Media files/URLs',
        schema => ['array*' => of => 'str*'],
        req => 1,
        pos => 0,
        greedy => 1,
        #'x.schema.entity' => 'filename_or_url',
        'x.schema.entity' => 'filename', # temp
    },
);

our %arg0_media_single = (
    media => {
        summary => 'Media file/URL',
        schema => ['str*'],
        req => 1,
        pos => 0,
        #'x.schema.entity' => 'filename_or_url',
        'x.schema.entity' => 'filename', # temp
    },
);

our %argopt_backend = (
    backend => {
        summary => 'Choose a specific backend',
        schema  => ['str*', match => '\A\w+\z'],
        completion => sub {
            require Complete::Module;
            my %args = @_;
            Complete::Module::complete_module(
                word => $args{word},
                ns_prefix => "Media::Info",
            );
        },
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

$SPEC{media_info} = {
    v => 1.1,
    summary => 'Get information about media files/URLs',
    args => {
        %arg0_media_multiple,
        %argopt_backend,
    },
};
sub media_info {
    require Media::Info;

    my %args = @_;

    my $media = $args{media};

    if (@$media == 1) {
        return Media::Info::get_media_info(
            media => $media->[0],
            (backend => $args{backend}) x !!(defined $args{backend}),
        );
    } else {
        my @res;
        for (@$media) {
            my $res = Media::Info::get_media_info(
                media => $_,
                (backend => $args{backend}) x !!(defined $args{backend}),
            );
            unless ($res->[0] == 200) {
                warn "Can't get media info for '$_': $res->[1] ($res->[0])\n";
                next;
            }
            push @res, { media => $_, %{$res->[2]} };
        }
        [200, "OK", \@res];
    }
}

$SPEC{media_is_portrait} = {
    v => 1.1,
    summary => 'Return exit code 0 if media is portrait',
    description => <<'_',

Portrait is defined as having 'rotate' metadata of 90 or 270 when the width >
height. Otherwise, media is assumed to be 'landscape'.

_
    args => {
        %arg0_media_single,
        %argopt_backend,
        %argopt_quiet,
    },
    examples => [
        {
            summary => 'Move all portrait videos to portrait/',
            src => 'for f in *.mp4;do [[prog]] -q "$f" && mv "$f" portrait/; done',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub media_is_portrait {
    my %args = @_;

    my $res = media_info(media => [$args{media}], backend=>$args{backend});
    return $res unless $res->[0] == 200;

    my $rotate = $res->[2]{rotate} // 0;
    my $width  = $res->[2]{video_width}  // $res->[2]{width};
    my $height = $res->[2]{video_height} // $res->[2]{height};
    return [412, "Can't determine video width x height"] unless $width && $height;
    my $is_portrait = ($rotate == 90 || $rotate == 270 ? 1:0) ^ ($width <= $height ? 1:0) ? 1:0;

    [200, "OK", $is_portrait, {
        'cmdline.exit_code' => $is_portrait ? 0:1,
        'cmdline.result' => $args{quiet} ? '' :
            "Media is ".
            ($is_portrait ? "portrait" : "NOT portrait (landscape)"),
    }];
}

$SPEC{media_is_landscape} = {
    v => 1.1,
    summary => 'Return exit code 0 if media is landscape',
    description => <<'_',

Portrait is defined as having 'rotate' metadata of 90 or 270. Otherwise, media
is assumed to be 'landscape'.

_
    args => {
        %arg0_media_single,
        %argopt_backend,
        %argopt_quiet,
    },
    examples => [
        {
            summary => 'Convert all landscape mkv videos to mp4',
            src => 'for f in *.mkv;do [[prog]] -q "$f" && ffmpeg -i "$f" "$f.mp4"; done',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub media_is_landscape {
    my %args = @_;

    my $res = media_info(media => [$args{media}], backend=>$args{backend});
    return $res unless $res->[0] == 200;

    my $rotate = $res->[2]{rotate} // 0;
    my $width  = $res->[2]{video_width}  // $res->[2]{width};
    my $height = $res->[2]{video_height} // $res->[2]{height};
    return [412, "Can't determine video width x height"] unless $width && $height;
    my $is_landscape = ($rotate == 90 || $rotate == 270 ? 1:0) ^ ($width <= $height ? 1:0) ? 0:1;

    [200, "OK", $is_landscape, {
        'cmdline.exit_code' => $is_landscape ? 0:1,
        'cmdline.result' => $args{quiet} ? '' :
            "Media is ".
            ($is_landscape ? "landscape" : "NOT landscape (portrait)"),
    }];
}

$SPEC{media_orientation} = {
    v => 1.1,
    summary => "Return orientation of media ('portrait' or 'landscape')",
    description => <<'_',

Portrait is defined as having 'rotate' metadata of 90 or 270. Otherwise, media
is assumed to be 'landscape'.

_
    args => {
        %arg0_media_single,
        %argopt_backend,
    },
};
sub media_orientation {
    my %args = @_;

    my $res = media_info(media => [$args{media}], backend=>$args{backend});
    return $res unless $res->[0] == 200;

    my $rotate = $res->[2]{rotate} // 0;
    my $width  = $res->[2]{video_width}  // $res->[2]{width};
    my $height = $res->[2]{video_height} // $res->[2]{height};
    return [412, "Can't determine video width x height"] unless $width && $height;
    my $orientation = ($rotate == 90 || $rotate == 270 ? 1:0) ^ ($width <= $height ? 1:0) ? "portrait" : "landscape";

    [200, "OK", $orientation];
}

1;
# ABSTRACT: Utilities related to getting (metadata) information from media files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MediaInfo - Utilities related to getting (metadata) information from media files

=head1 VERSION

This document describes version 0.124 of App::MediaInfo (from Perl distribution App-MediaInfo), released on 2019-08-15.

=head1 FUNCTIONS


=head2 media_info

Usage:

 media_info(%args) -> [status, msg, payload, meta]

Get information about media files/URLs.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backend> => I<str>

Choose a specific backend.

=item * B<media>* => I<array[str]>

Media files/URLs.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 media_is_landscape

Usage:

 media_is_landscape(%args) -> [status, msg, payload, meta]

Return exit code 0 if media is landscape.

Portrait is defined as having 'rotate' metadata of 90 or 270. Otherwise, media
is assumed to be 'landscape'.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backend> => I<str>

Choose a specific backend.

=item * B<media>* => I<str>

Media file/URL.

=item * B<quiet> => I<true>

Don't output anything on command-line, just return appropriate exit code.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 media_is_portrait

Usage:

 media_is_portrait(%args) -> [status, msg, payload, meta]

Return exit code 0 if media is portrait.

Portrait is defined as having 'rotate' metadata of 90 or 270 when the width >
height. Otherwise, media is assumed to be 'landscape'.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backend> => I<str>

Choose a specific backend.

=item * B<media>* => I<str>

Media file/URL.

=item * B<quiet> => I<true>

Don't output anything on command-line, just return appropriate exit code.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 media_orientation

Usage:

 media_orientation(%args) -> [status, msg, payload, meta]

Return orientation of media ('portrait' or 'landscape').

Portrait is defined as having 'rotate' metadata of 90 or 270. Otherwise, media
is assumed to be 'landscape'.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backend> => I<str>

Choose a specific backend.

=item * B<media>* => I<str>

Media file/URL.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-MediaInfo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-MediaInfo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-MediaInfo>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

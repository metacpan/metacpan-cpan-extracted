package App::FfmpegUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Exporter;
use Perinci::Object;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-21'; # DATE
our $DIST = 'App-FfmpegUtils'; # DIST
our $VERSION = '0.011'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to ffmpeg',
};

our %argspec0_file = (
    file => {
        schema => 'filename*',
        req => 1,
        pos => 0,
    },
);

our %argspec0_files = (
    files => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*' => of => 'filename*'],
        req => 1,
        pos => 0,
        slurpy => 1,
    },
);

our %argspecopt_ffmpeg_path = (
    ffmpeg_path => {
        schema => 'filename*',
    },
);

our %argspecopt_copy = (
    copy => {
        summary => 'Whether to use the "copy" codec (fast but produces inaccurate timings)',
        schema => 'bool*',
    },
);

my @presets = qw/ultrafast superfast veryfast faster fast medium slow slower veryslow/;

sub _nearest {
    sprintf("%d", $_[0]/$_[1]) * $_[1];
}

$SPEC{reencode_video_with_libx264} = {
    v => 1.1,
    summary => 'Re-encode video (using ffmpeg and libx264)',
    description => <<'_',

This utility runs *ffmpeg* to re-encode your video files using the libx264
codec. It is a wrapper to simplify invocation of ffmpeg. It selects the
appropriate ffmpeg options for you, allows you to specify multiple files, and
picks appropriate output filenames. It also sports a `--dry-run` option to let
you see ffmpeg options to be used without actually running ffmpeg.

This utility is usually used to reduce the file size (and optionally video
width/height) of videos so they are smaller, while minimizing quality loss.
Smartphone-produced videos are often high bitrate (e.g. >10-20Mbit) and not yet
well compressed, so they make a good input for this utility. The default setting
is roughly similar to how Google Photos encodes videos (max 1080p).

The default settings are:

    -v:c libx264
    -preset veryslow (to get the best compression rate, but with the slowest encoding time)
    -crf 28 (0-51, subjectively sane is 18-28, 18 ~ visually lossless, 28 ~ visually acceptable)

when a downsizing is requested (using the `--downsize-to` option), this utility
first checks each input video if it is indeed larger than the requested final
size. If it is, then the `-vf scale` option is added. This utility also
calculates a valid size for ffmpeg, since using `-vf scale=-1:720` sometimes
results in failure due to odd number.

Audio streams are copied, not re-encoded.

Output filenames are:

    ORIGINAL_NAME.crf28.mp4

or (if downsizing is done):

    ORIGINAL_NAME.480p-crf28.mp4

_
    args => {
        %argspec0_files,
        %argspecopt_ffmpeg_path,
        crf => {
            schema => ['int*', between=>[0,51]],
        },
        scale => {
            schema => 'str*',
            default => '1080^>',
            description => <<'_',

Scale video to specified size. See <pm:Math::Image::CalcResized> or
<prog:calc-image-resized-size> for more details on scale specification. Some
examples include:

The default is `1080^>` which means to shrink to 1080p if video size is larger
than 1080p.

To disable scaling, set `--scale` to '' (empty string), or specify
`--dont-scale` on the CLI.

_
            cmdline_aliases => {
                dont_scale => {summary=>"Alias for --scale ''", is_flag=>1, code=>sub {$_[0]{scale} = ''}},
                no_scale   => {summary=>"Alias for --scale ''", is_flag=>1, code=>sub {$_[0]{scale} = ''}},
            },
        },
        preset => {
            schema => ['str*', in=>\@presets],
            default => 'veryslow',
            cmdline_aliases => {
                (map {($_ => {is_flag=>1, summary=>"Shortcut for --preset=$_", code=>do { my $p = $_; sub { $_[0]{preset} = $p }}})} @presets),
            },
        },
        frame_rate => {
            summary => 'Set frame rate, in fps',
            schema => 'ufloat*',
            cmdline_aliases => {r=>{}},
        },
        audio_sample_rate => {
            summary => 'Set audio sample rate, in Hz',
            schema => 'uint*',
            cmdline_aliases => {sample_rate=>{}},
        },
    },
    features => {
        dry_run => 1,
    },
    examples => [
        {
            summary => 'The default setting is to shrink to 1080p if video is larger than 1080p',
            src => '[[prog]] *',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Do not scale/shrink',
            src => '[[prog]] --dont-scale *',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Shrink to 480p if video is larger than 480p, but make the reencoding "visually lossless"',
            src => "[[prog]] --scale '480^>' --crf 18 *",
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub reencode_video_with_libx264 {
    require File::Which;
    require IPC::System::Options;
    require Media::Info;

    my %args = @_;

    my $ffmpeg_path = $args{ffmpeg_path} // File::Which::which("ffmpeg");
    my $scale = $args{scale};

    unless ($args{-dry_run}) {
        return [400, "Cannot find ffmpeg in path"] unless defined $ffmpeg_path;
        return [400, "ffmpeg path $ffmpeg_path is not executable"] unless -f $ffmpeg_path;
    }

    for my $file (@{$args{files}}) {
        log_info "Processing file %s ...", $file;

        unless (-f $file) {
            log_error "No such file %s, skipped", $file;
            next;
        }

        my $res = Media::Info::get_media_info(media => $file);
        unless ($res->[0] == 200) {
            log_error "Can't get media information fod %s: %s - %s, skipped",
                $file, $res->[0], $res->[1];
            next;
        }
        my $video_info = $res->[2];

        my $crf = $args{crf} // 28;
        my @ffmpeg_args = (
            "-i", $file,
        );

        my $scale_suffix;
      SCALE: {
            last unless defined $scale && length $scale;
            require Math::Image::CalcResized;
            my $calcres = Math::Image::CalcResized::calc_image_resized_size(
                size => "$video_info->{video_width}x$video_info->{video_height}",
                resize => $scale,
            );
            return [400, "Can't scale using '$scale': $calcres->[0] - $calcres->[1]"]
                unless $calcres->[0] == 200;

            my ($scaled_width, $scaled_height) = $calcres->[2] =~ /(.+)x(.+)/
                or return [500, "calc_image_resized_size() doesn't return new WxH ($calcres->[2])"];
            last unless $scaled_width != $video_info->{video_width} ||
                $scaled_height != $video_info->{video_height};
            ($scale_suffix = $calcres->[3]{'func.human_specific'}) =~ s/\W+/_/g;
            push @ffmpeg_args, "-vf", sprintf(
                "scale=%d:%d",
                _nearest($scaled_width, 2),  # make sure divisible by 2 (optimum is divisible by 16, then 8, then 4)
                _nearest($scaled_height, 2),
            );
        } # SCALE

        my $output_file = $file;
        my $ext = $scale_suffix ? ".$scale_suffix-crf$crf.mp4" : ".crf$crf.mp4";
        $output_file =~ s/(\.\w{3,4})?\z/($1 eq ".mp4" ? "" : $1) . $ext/e;

        my $audio_is_copy = 1;
        $audio_is_copy = 0 if defined $args{audio_sample_rate};

        push @ffmpeg_args, (
            "-c:v", "libx264",
            "-crf", $crf,
            "-preset", ($args{preset} // 'veryslow'),
            (defined $args{frame_rate} ? ("-r", $args{frame_rate}) : ()),
            "-c:a", ($audio_is_copy ? "copy" : "aac"),
            (defined $args{audio_sample_rate} ? ("-ar", $args{audio_sample_rate}) : ()),
            $output_file,
        );

        if ($args{-dry_run}) {
            log_info "[DRY-RUN] Running $ffmpeg_path with args %s ...", \@ffmpeg_args;
            next;
        }

        IPC::System::Options::system(
            {log=>1},
            $ffmpeg_path, @ffmpeg_args,
        );
        if ($?) {
            my ($exit_code, $signal, $core_dump) = ($? < 0 ? $? : $? >> 8, $? & 127, $? & 128);
            log_error "ffmpeg for $file failed: exit_code=$exit_code, signal=$signal, core_dump=$core_dump";
        }
    }

    [200];
}

$SPEC{split_video_by_duration} = {
    v => 1.1,
    summary => 'Split video by duration into parts',
    description => <<'_',

This utility uses *ffmpeg* (particularly the `-t` and `-ss`) option to split a
longer video into shorter videos. For example, if you have `long.mp4` with
duration of 1h12m and you run it through this utility with `--every 15min` then
you will have 5 new video files: `long.1of5.mp4` (15min), `long.2of5.mp4`
(15min), `long.3of5.mp4` (15min), `long.4of5.mp4` (15min), and `long.5of5.mp4`
(12min).

_
    args => {
        %argspec0_files,
        # XXX start => {},
        every => {
            schema => 'duration*',
            req => 1,
        },
        %argspecopt_copy,
        # XXX merge_if_last_part_is_shorter_than => {},
        # XXX output_filename_pattern
    },
    examples => [
        {
            summary => 'Split video per 15 minutes',
            src_plang => 'bash',
            src => '[[prog]] --every 15min foo.mp4',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Split video per 30s for WhatsApp status',
            src_plang => 'bash',
            src => '[[prog]] foo.mp4 30s',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    features => {
        dry_run => 1,
    },
    deps => {
        prog => "ffmpeg", # XXX allow FFMPEG_PATH
    },
    links => [
        {url=>'prog:srtsplit', summary=>'Split .srt by duration, much like this utility'},
    ],
};
sub split_video_by_duration {
    require POSIX;

    my %args = @_;
    my $files = $args{files};
    my $part_dur = $args{every};
    $part_dur > 0 or return [400, "Please specify a non-zero --every"];

    my $envres = envresmulti();
    my $j = -1;
    for my $file (@$files) {

        $j++;
        log_info "Processing file %s ...", $file;

        require Media::Info;
        my $res = Media::Info::get_media_info(media => $file);
        unless ($res->[0] == 200) {
            $envres->add_result($res->[0], "Can't get info for video $file: $res->[1]", {item_id=>$j});
            next;
        }

        my $total_dur = $res->[2]{duration};
        unless ($total_dur) {
            $envres->add_result(412, "Duration of video $file is zero", {item_id=>$j});
            next;
        }

        my $num_parts = POSIX::ceil($total_dur / $part_dur);
        my $fmt = $num_parts >= 1000 ? "%04d" : $num_parts >= 100 ? "%03d" : $num_parts >= 10 ? "%02d" : "%d";

        unless ($num_parts >= 2) {
            $envres->add_result(304, "No split necessary for video $file", {item_id=>$j});
            next;
        }

        require IPC::System::Options;
        for my $i (1..$num_parts) {
            my $part_label = sprintf "${fmt}of%d", $i, $num_parts;
            my $ofile = $file;
            if ($ofile =~ /\.\w+\z/) { $ofile =~ s/(\.\w+)\z/.$part_label$1/ } else { $ofile .= ".$part_label" }
            my $time_start = ($i-1)*$part_dur;
            IPC::System::Options::system(
                {log=>1, dry_run=>$args{-dry_run}},
                "ffmpeg", "-i", $file, ($args{copy} ? ("-c", "copy") : ()), "-ss", $time_start, "-t", $part_dur, $ofile);
            my ($exit_code, $signal, $core_dump) = ($? < 0 ? $? : $? >> 8, $? & 127, $? & 128);
            if ($exit_code) {
                $envres->add_result(500, "ffmpeg exited $exit_code (sig $signal) for video $file: $!", {item_id=>$j});
            } else {
                $envres->add_result(200, "Video $file successfully split", {item_id=>$j});
            }
        }

    } # for $file

    $envres->as_struct;
}

$SPEC{cut_video_by_duration} = {
    v => 1.1,
    summary => 'Get a portion (time range) of a video',
    description => <<'_',

This utility uses *ffmpeg* (particularly the `-t` and `-ss`) option to get a
portion (time range) of a video. It is a convenient wrapper of ffmpeg for this
particular task. You can specify start time and end time, or start time and
duration. It automatically chooses a filename if you don't specify one.

_
    args => {
        %argspec0_file,
        start => {
            schema => 'duration*',
            req => 1,
            pos => 1,
        },
    },
    examples => [
    ],
    features => {
        dry_run => 1,
    },
    deps => {
        prog => "ffmpeg", # XXX allow FFMPEG_PATH
    },
    links => [
        {url=>'prog:srtsplit', summary=>'Split .srt by duration, much like this utility'},
    ],
};
sub cut_video_by_duration {
    require POSIX;

    my %args = @_;
    my $file = $args{file};
    my $part_dur = $args{every};
    $part_dur > 0 or return [400, "Please specify a non-zero --every"];

    require Media::Info;
    my $res = Media::Info::get_media_info(media => $file);
    return $res unless $res->[0] == 200;

    my $total_dur = $res->[2]{duration}
        or return [412, "Duration of video is zero"];

    my $num_parts = POSIX::ceil($total_dur / $part_dur);
    my $fmt = $num_parts >= 1000 ? "%04d" : $num_parts >= 100 ? "%03d" : $num_parts >= 10 ? "%02d" : "%d";

    return [304, "No split necessary"] if $num_parts < 2;

    require IPC::System::Options;
    for my $i (1..$num_parts) {
        my $part_label = sprintf "${fmt}of%d", $i, $num_parts;
        my $ofile = $file;
        if ($ofile =~ /\.\w+\z/) { $ofile =~ s/(\.\w+)\z/.$part_label$1/ } else { $ofile .= ".$part_label" }
        my $time_start = ($i-1)*$part_dur;
        IPC::System::Options::system(
            {log=>1, dry_run=>$args{-dry_run}},
            "ffmpeg", "-i", $file, ($args{copy} ? ("-c", "copy") : ()), "-ss", $time_start, "-t", $part_dur, $ofile);
    }
    [200];
}

1;
# ABSTRACT: Utilities related to ffmpeg

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FfmpegUtils - Utilities related to ffmpeg

=head1 VERSION

This document describes version 0.011 of App::FfmpegUtils (from Perl distribution App-FfmpegUtils), released on 2022-09-21.

=head1 FUNCTIONS


=head2 cut_video_by_duration

Usage:

 cut_video_by_duration(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get a portion (time range) of a video.

This utility uses I<ffmpeg> (particularly the C<-t> and C<-ss>) option to get a
portion (time range) of a video. It is a convenient wrapper of ffmpeg for this
particular task. You can specify start time and end time, or start time and
duration. It automatically chooses a filename if you don't specify one.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<file>* => I<filename>

=item * B<start>* => I<duration>


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 reencode_video_with_libx264

Usage:

 reencode_video_with_libx264(%args) -> [$status_code, $reason, $payload, \%result_meta]

Re-encode video (using ffmpeg and libx264).

This utility runs I<ffmpeg> to re-encode your video files using the libx264
codec. It is a wrapper to simplify invocation of ffmpeg. It selects the
appropriate ffmpeg options for you, allows you to specify multiple files, and
picks appropriate output filenames. It also sports a C<--dry-run> option to let
you see ffmpeg options to be used without actually running ffmpeg.

This utility is usually used to reduce the file size (and optionally video
width/height) of videos so they are smaller, while minimizing quality loss.
Smartphone-produced videos are often high bitrate (e.g. >10-20Mbit) and not yet
well compressed, so they make a good input for this utility. The default setting
is roughly similar to how Google Photos encodes videos (max 1080p).

The default settings are:

 -v:c libx264
 -preset veryslow (to get the best compression rate, but with the slowest encoding time)
 -crf 28 (0-51, subjectively sane is 18-28, 18 ~ visually lossless, 28 ~ visually acceptable)

when a downsizing is requested (using the C<--downsize-to> option), this utility
first checks each input video if it is indeed larger than the requested final
size. If it is, then the C<-vf scale> option is added. This utility also
calculates a valid size for ffmpeg, since using C<-vf scale=-1:720> sometimes
results in failure due to odd number.

Audio streams are copied, not re-encoded.

Output filenames are:

 ORIGINAL_NAME.crf28.mp4

or (if downsizing is done):

 ORIGINAL_NAME.480p-crf28.mp4

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<audio_sample_rate> => I<uint>

Set audio sample rate, in Hz.

=item * B<crf> => I<int>

=item * B<ffmpeg_path> => I<filename>

=item * B<files>* => I<array[filename]>

=item * B<frame_rate> => I<ufloat>

Set frame rate, in fps.

=item * B<preset> => I<str> (default: "veryslow")

=item * B<scale> => I<str> (default: "1080^>")

Scale video to specified size. See L<Math::Image::CalcResized> or
L<calc-image-resized-size> for more details on scale specification. Some
examples include:

The default is C<< 1080^E<gt> >> which means to shrink to 1080p if video size is larger
than 1080p.

To disable scaling, set C<--scale> to '' (empty string), or specify
C<--dont-scale> on the CLI.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 split_video_by_duration

Usage:

 split_video_by_duration(%args) -> [$status_code, $reason, $payload, \%result_meta]

Split video by duration into parts.

This utility uses I<ffmpeg> (particularly the C<-t> and C<-ss>) option to split a
longer video into shorter videos. For example, if you have C<long.mp4> with
duration of 1h12m and you run it through this utility with C<--every 15min> then
you will have 5 new video files: C<long.1of5.mp4> (15min), C<long.2of5.mp4>
(15min), C<long.3of5.mp4> (15min), C<long.4of5.mp4> (15min), and C<long.5of5.mp4>
(12min).

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<copy> => I<bool>

Whether to use the "copy" codec (fast but produces inaccurate timings).

=item * B<every>* => I<duration>

=item * B<files>* => I<array[filename]>


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FfmpegUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FfmpegUtils>.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FfmpegUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

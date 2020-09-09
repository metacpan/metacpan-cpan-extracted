package CLI::Meta::YoutubeDl;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-09'; # DATE
our $DIST = 'CLI-Meta-YoutubeDl'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

my $comp_country_code = sub {
    require Complete::Country;
    my %args = @_;
    Complete::Country::complete_country_code(word=>$args{word});
};

my $comp_dir = sub {
    require Complete::File;
    my %args = @_;
    Complete::File::complete_file(word=>$args{word}, filter=>'d');
};

my $comp_exec_file = sub {
    require Complete::File;
    my %args = @_;
    Complete::File::complete_file(word=>$args{word}, filter=>'dx');
};

my $comp_file = sub {
    require Complete::File;
    my %args = @_;
    Complete::File::complete_file(word=>$args{word});
};

our $META = {
    opts => {
        # General Options:
        'help|h' => undef,
        'version' => undef,
        'update|U' => undef,
        'ignore-errors|i' => undef,
        'abort-on-error' => undef,
        'dump-user-agent' => undef,
        'list-extractors' => undef,
        'extractor-descriptions' => undef,
        'force-generic-extractor' => undef,
        'default-search=s' => {completion=>["gvsearch2:", "auto", "auto_warning", "error", "fixup_error"]},
        'ignore-config' => undef,
        'config-location=s' => {completion => $comp_file},
        'flat-playlist' => undef,
        'mark-watched!' => undef,
        'no-color' => undef,

        # Network Options:
        'proxy=s' => undef,
        'socket-timeout=i' => undef,
        'source-address=s' => undef,
        'force-ipv4|4' => undef,
        'force-ipv6|6' => undef,
        'geo-verification-proxy=s' => undef,
        'geo-bypass' => undef,
        'no-geo-bypass' => undef,
        'geo-bypass-country=s' => {completion=>$comp_country_code},
        'geo-bypass-ip-block=s' => undef,

        # Video Selection:
        'playlist-start=i' => undef,
        'playlist-end=i' => undef,
        'playlist-items=s' => undef, # e.g. 1,2,3,10-13
        'match-title=s' => undef, # regex or substr
        'reject-title=s' => undef, # regex or substr
        'max-downloads=i' => undef,
        'min-filesize=s' => undef, # number or number with prefix
        'max-filesize=s' => undef, # number or number with prefix
        'date=s' => undef,
        'datebefore=s' => undef,
        'dateafter=s' => undef,
        'min-views=i' => undef,
        'max-views=i' => undef,
        'match-filter=s' => undef, # e.g. "like_count > 100 & dislike_count <? 50 & description"
        'no-playlist' => undef,
        'yes-playlist' => undef,
        'age-limit=i' => undef,
        'download-archive=s' => {completion=>$comp_file},
        'include-ads' => undef,

        # Download Options:
        'limit-rate|r=s' => undef, # number with prefix
        'retries|R=i' => undef,
        'fragment-retries=i' => undef,
        'skip-unavailable-fragments' => undef,
        'abort-on-unavailable-fragment' => undef,
        'keep-fragments' => undef,
        'buffer-size=s' => undef, # number or number with prefix
        'no-resize-buffer' => undef,
        'http-chunk-size=s' => undef, # e.g. 10485760 or 10M
        'playlist-reverse' => undef,
        'playlist-random' => undef,
        'xattr-set-filesize' => undef,
        'hls-prefer-native' => undef,
        'hls-prefer-ffmpeg' => undef,
        'hls-use-mpegts' => undef,
        'external-downloader=s' => {completion=>["aria2c", "axel", "curl", "httpie", "wget"]},
        'external-downloader-args=s' => undef,

        # Filesystem Options:
        'batch-file|a=s' => undef,
        'id' => undef,
        'output|o=s' => {completion=>$comp_file},
        'autonumber-start=i' => undef,
        '--restrict-filenames' => undef,
        'no-overwrites|w' => undef,
        'continue|c' => undef,
        'no-continue' => undef,
        'no-part' => undef,
        'no-mtime' => undef,
        'write-description' => undef,
        'write-info-json' => undef,
        'write-annotations' => undef,
        'load-info-json=s' => {completion=>$comp_file},
        'cookies=s' => {completion=>$comp_file},
        'cache-dir=s' => {completion=>$comp_dir},
        'no-cache-dir' => undef,
        'rm-cache-dir' => undef,

        # Thumbnail images:
        'write-thumbnail' => undef,
        'write-all-thumbnails' => undef,
        'list-thumbnails' => undef,

        # Verbosity / Simulation Options:
        'quiet|q' => undef,
        'no-warnings' => undef,
        'simulate|s' => undef,
        'skip-download' => undef,
        'get-url|g' => undef,
        'get-title|e' => undef,
        'get-id' => undef,
        'get-thumbnail' => undef,
        'get-description' => undef,
        'get-duration' => undef,
        'get-filename' => undef,
        'get-format' => undef,
        'dump-json|j' => undef,
        'dump-single-json|J' => undef,
        'print-json' => undef,
        'newline' => undef,
        'no-progress' => undef,
        'console-title' => undef,
        'verbose|v' => undef,
        'dump-pages' => undef,
        'write-pages' => undef,
        'print-traffic' => undef,
        'call-home|C' => undef,
        'no-call-home' => undef,

        # Workarounds:
        'encoding=s' => undef,
        'no-check-certificate' => undef,
        'prefer-insecure' => undef,
        'user-agent=s' => undef,
        'referer=s' => undef, # url
        'add-header=s' => undef, # FIELD:VALUE
        'bidi-workaround' => undef,
        'sleep-interval=i' => undef,
        'max-sleep-interval=i' => undef,

        # Video Format Options:
        'format|f=s' => {
            completion => [qw/aac m4a mp3 mp4 ogg wav webm/,
                           qw/best bestvideo bestaudio worst/], # format or format1/format2/format3 (by order of preference)
        },
        'all-formats' => undef,
        'prefer-free-formats' => undef,
        'list-formats|F' => undef,
        'youtube-skip-dash-manifest' => undef,
        'merge-output-format=s' => {completion=>[qw/mkv mp4 ogg webm/]},

        # Subtitle Options:
        'write-sub' => undef,
        'write-auto-sub' => undef,
        'all-subs' => undef,
        'list-subs' => undef,
        'sub-format=s' => {completion=>[qw/aas srt best/]},
        'sub-lang=s' => undef, # e.g. 'en,pt'

        # Authentication Options:
        'username|u=s' => undef,
        'password|p:s' => undef,
        'twofactor|2=s' => undef,
        'netrc|n' => undef,
        'video-password=s' => undef,

        # Adobe Pass Options:
        'ap-mso=s' => undef,
        'ap-username=s' => undef,
        'ap-password=s' => undef,
        'ap-list-mso' => undef,

        # Post-processing Options:
        'extract-audio|x' => undef,
        'audio-format=s' => {completion=>["best", "aac", "flac", "mp3", "m4a", "opus", "vorbis", "wav"]},
        'audio-quality=s' => {completion=>[0..9]}, # 0..9 or bitrate
        'recode-video=s' => {completion=>[qw/mp4 flv ogg webm mkv avi/]},
        'postprocessor-args=s' => undef,
        'keep-video|k' => undef,
        'no-post-overwrites' => undef,
        'embed-subs' => undef,
        'embed-thumbnail' => undef,
        'add-metadata' => undef,
        'metadata-from-title=s' => undef,
        'xattrs' => undef,
        'fixup=s' => {completion=>[qw/nothing warn detect_or_warn/]},
        'prefer-avconv' => undef,
        'prefer-ffmpeg' => undef,
        'ffmpeg-location=s' => {completion=>$comp_exec_file},
        'exec=s' => undef,
        'convert-subs=s' => undef,
    },
};

1;
# ABSTRACT: Metadata for youtube-dl CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Meta::YoutubeDl - Metadata for youtube-dl CLI

=head1 VERSION

This document describes version 0.001 of CLI::Meta::YoutubeDl (from Perl distribution CLI-Meta-YoutubeDl), released on 2020-09-09.

=head1 SYNOPSIS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CLI-Meta-YoutubeDl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CLI-Meta-YoutubeDl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CLI-Meta-YoutubeDl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

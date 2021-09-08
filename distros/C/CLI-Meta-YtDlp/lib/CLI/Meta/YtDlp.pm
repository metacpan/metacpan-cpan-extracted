package CLI::Meta::YtDlp;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-07'; # DATE
our $DIST = 'CLI-Meta-YtDlp'; # DIST
our $VERSION = '0.001'; # VERSION

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
        'ignore-errors|no-abort-on-error|i' => undef,
        'abort-on-error|no-ignore-errors' => undef,
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
        'compat-options=s' => undef,

        # Network Options:
        'proxy=s' => undef,
        'socket-timeout=i' => undef,
        'source-address=s' => undef,
        'force-ipv4|4' => undef,
        'force-ipv6|6' => undef,

        # Geo-restrictions:
        'geo-verification-proxy=s' => undef,
        'geo-bypass!' => undef,
        'geo-bypass-country=s' => {completion=>$comp_country_code},
        'geo-bypass-ip-block=s' => undef,

        # Video Selection:
        'playlist-start=i' => undef,
        'playlist-end=i' => undef,
        'playlist-items=s' => undef, # e.g. 1,2,3,10-13
        'max-downloads=i' => undef,
        'min-filesize=s' => undef, # number or number with prefix
        'max-filesize=s' => undef, # number or number with prefix
        'date=s' => undef,
        'datebefore=s' => undef,
        'dateafter=s' => undef,
        'match-filter=s' => undef,
        'min-views=i' => undef,
        'max-views=i' => undef,
        'match-filter=s' => undef, # e.g. "like_count > 100 & dislike_count <? 50 & description"
        'no-match-filter' => undef,
        'no-playlist' => undef,
        'yes-playlist' => undef,
        'age-limit=i' => undef,
        'download-archive=s' => {completion=>$comp_file},
        'break-on-existing' => undef,
        'break-on-reject' => undef,
        'skip-playlist-after-errors=i' => undef,
        'no-download-archive' => undef,

        # Download Options:
        'concurrent-fragments|N=i' => undef,
        'limit-rate|r=s' => undef, # number with prefix
        'throttled-rate|r=s' => undef, # number with prefix
        'retries|R=i' => undef,
        'fragment-retries=i' => undef,
        'skip-unavailable-fragments|no-abort-on-unavailable-fragments' => undef,
        'abort-on-unavailable-fragment|no-skip-unavailable-fragments' => undef,
        'keep-fragments!' => undef,
        'buffer-size=s' => undef, # number or number with prefix
        'resize-buffer!' => undef,
        'http-chunk-size=s' => undef, # e.g. 10485760 or 10M
        'playlist-reverse!' => undef,
        'playlist-random' => undef,
        'xattr-set-filesize' => undef,
        'hls-use-mpegts!' => undef,
        'downloader|external-downloader=s' => {completion=>["aria2c", "axel", "curl", "httpie", "wget"]},
        'downloader-args|external-downloader-args=s' => undef,

        # Filesystem Options:
        'batch-file|a=s' => undef,
        'paths|P=s' => undef,
        'output|o=s' => {completion=>$comp_file},
        'output-na-placeholder=s' => undef,
        'restrict-filenames!' => undef,
        'windows-filenames!' => undef,
        'trim-filenames=i' => undef,
        'no-overwrites|w' => undef,
        'force-overwrites!' => undef,
        'continue|c' => undef,
        'no-continue' => undef,
        'part!' => undef,
        'mtime!' => undef,
        'write-description!' => undef,
        'write-info-json!' => undef,
        'write-playlist-metafiles!' => undef,
        'clean-infojson!' => undef,
        'write-comments|get-comments!' => undef,
        'load-info-json=s' => {completion=>$comp_file},
        'cookies=s' => {completion=>$comp_file},
        'no-cookies' => undef,
        'cookies-from-browser=s' => {completion=>[qw/brave chrome chromium edge firefox opera safari vivaldi/]}, # XXX should be browser:profile, complete firefox/chrome profiles
        'no-cookies-from-browser' => undef,
        'cache-dir=s' => {completion=>$comp_dir},
        'no-cache-dir' => undef,
        'rm-cache-dir' => undef,

        # Thumbnail Options:
        'write-thumbnail!' => undef,
        'write-all-thumbnails' => undef,
        'list-thumbnails' => undef,

        # Internet Shortcut Options:
        'write-link' => undef,
        'write-url-link' => undef,
        'write-webloc-link' => undef,
        'write-desktop-link' => undef,

        # Verbosity / Simulation Options:
        'quiet|q' => undef,
        'no-warnings' => undef,
        'simulate|s' => undef,
        'no-simulate' => undef,
        'ignore-no-formats-error!' => undef,
        'skip-download|no-download' => undef,
        'print|O=s' => undef,
        'dump-json|j' => undef,
        'dump-single-json|J' => undef,
        'force-write-archive|force-download-archive' => undef,
        'newline' => undef,
        'no-progress' => undef,
        'console-title' => undef,
        'verbose|v' => undef,
        'dump-pages' => undef,
        'write-pages' => undef,
        'print-traffic' => undef,

        # Workarounds:
        'encoding=s' => undef,
        'no-check-certificate' => undef,
        'prefer-insecure' => undef,
        'user-agent=s' => undef,
        'referer=s' => undef, # url
        'add-header=s' => undef, # FIELD:VALUE
        'bidi-workaround' => undef,
        'sleep-requests=i' => undef,
        'sleep-interval=i' => undef,
        'max-sleep-interval=i' => undef,
        'sleep-subtitles=i' => undef,

        # Video Format Options:
        'format|f=s' => {
            completion => [qw/aac m4a mp3 mp4 ogg wav webm/,
                           qw/best bestvideo bestaudio worst/], # format or format1/format2/format3 (by order of preference)
        },
        'format-sort|S=s' => undef,
        'format-sort-force!' => undef,
        'video-multistreams!' => undef,
        'audio-multistreams!' => undef,
        'prefer-free-formats!' => undef,
        'check-formats!' => undef,
        'list-formats|F' => undef,
        'merge-output-format=s' => {completion=>[qw/mkv mp4 ogg webm flv/]},

        # Subtitle Options:
        'write-subs!' => undef,
        'write-auto-subs!' => undef,
        'list-subs' => undef,
        'sub-format=s' => {completion=>[qw/aas srt best/]},
        'sub-langs=s' => undef, # e.g. 'en,pt'

        # Authentication Options:
        'username|u=s' => undef,
        'password|p:s' => undef,
        'twofactor|2=s' => undef,
        'netrc|n' => undef,
        'video-password=s' => undef,
        'ap-mso=s' => undef,
        'ap-username=s' => undef,
        'ap-password=s' => undef,
        'ap-list-mso' => undef,

        # Post-processing Options:
        'extract-audio|x' => undef,
        'audio-format=s' => {completion=>["best", "aac", "flac", "mp3", "m4a", "opus", "vorbis", "wav"]},
        'audio-quality=s' => {completion=>[0..9]}, # 0..9 or bitrate
        'remux-video=s'  => {completion=>[qw/mp4 mkv flv webm mov avi mp3 mka m4a ogg opus/]},
        'recode-video=s' => {completion=>[qw/mp4 mkv flv webm mov avi mp3 mka m4a ogg opus/]},
        'postprocessor-args=s' => undef,
        'keep-video|k' => undef,
        'no-keep-video' => undef,
        'post-overwrites!' => undef,
        'embed-subs!' => undef,
        'embed-thumbnail!' => undef,
        'embed-metadata!' => undef,
        'embed-chapters!' => undef,
        'parse-metadata=s' => undef, # FROM:TO
        'replace-in-metadata=s{3}' => undef, # FIELDS REGEX REPLACE
        'xattrs' => undef,
        'fixup=s' => {completion=>[qw/nothing warn detect_or_warn/]},
        'ffmpeg-location=s' => {completion=>$comp_exec_file},
        'exec=s' => undef,
        'no-exec' => undef,
        'exec-before-download=s' => undef,
        'no-exec-before-download' => undef,
        'convert-subs|convert-subtitles=s' => {completion=>[qw/srt vtt ass lrc/]},
        'split-chapters!' => undef,
        'remove-chapters=s' => undef,
        'no-remove-chapters' => undef,
        'force-keyframes-at-cuts!' => undef,

        # SponsorBlock Options:
        'sponsorblock-mark=s'   => {completion=>[qw/all sponsor intro outro selfpromo interaction preview music_offtopic/]}, # XXX allow "-" prefix; allow multiple cats
        'sponsorblock-remove=s' => {completion=>[qw/all sponsor intro outro selfpromo interaction preview music_offtopic/]}, # XXX allow "-" prefix; allow multiple cats
        'sponsorblock-chapter-title=s' => undef,
        'no-sponsorblock' => undef,
        'sponsorblock-api=s' => undef, # url

        # Extractor Options:
        'extractor-retries=i' => undef,
        'allow-dynamic-mpd|no-ignore-dynamic-mpd' => undef,
        'ignore-dynamic-mpd|no-allow-dynamic-mpd' => undef,
        'hls-split-discontinuity!' => undef,
        'extractor-args=s' => undef, # KEY:ARGS
    },
};

1;
# ABSTRACT: Metadata for yt-dlp CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Meta::YtDlp - Metadata for yt-dlp CLI

=head1 VERSION

This document describes version 0.001 of CLI::Meta::YtDlp (from Perl distribution CLI-Meta-YtDlp), released on 2021-09-07.

=head1 SYNOPSIS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CLI-Meta-YtDlp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CLI-Meta-YtDlp>.

=head1 SEE ALSO

L<CLI::Meta::YoutubeDl> for C<youtube-dl> CLI

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CLI-Meta-YtDlp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

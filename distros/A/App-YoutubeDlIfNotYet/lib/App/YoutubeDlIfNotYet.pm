package App::YoutubeDlIfNotYet;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-05'; # DATE
our $DIST = 'App-YoutubeDlIfNotYet'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use IPC::System::Options qw(system);
use YouTube::Util;

our %SPEC;

sub _search_id_in_log_file {
    my ($id, $path) = @_;

    state $cache = do {
        my %mem;
        open my($fh), "<", $path or die "Can't open log file '$path': $!";
        while (my $line = <$fh>) {
            chomp $line;
            if (my $video_id = YouTube::Util::extract_youtube_video_id($line)) {
                next if $mem{$video_id};
                $mem{$video_id} = $line;
            }
        }
        #use DD; dd \%mem;
        \%mem;
    };

    $cache->{$id};
}

$SPEC{youtube_dl_if_not_yet} = {
    v => 1.1,
    summary => '(DEPRECATED) Download videos using youtube-dl only if videos have not been donwnloaded yet',
    description => <<'_',

This is a wrapper for **youtube-dl**; it tries to extract downloaded video ID's
from filenames or URL's or video ID's listed in a text file, e.g.:

    35682594        Table Tennis Shots- If Were Not Filmed, Nobody Would Believe [HD]-dUjxqFbWzQo.mp4       date:[2019-12-29 ]

or:

    https://www.youtube.com/embed/U9v2S49sHeQ?rel=0

or:

    U9v2S49sHeQ

When a video ID is found then it is assumed to be already downloaded in the past
and will not be downloaded again.

_
    args => {
        urls_or_ids => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'url_or_id',
            schema => ['array*', of=>'str*', min_len=>1],
            req => 1,
            pos => 0,
            greedy => 1,
        },
        log_file => {
            summary => 'File that contains list of download filenames',
            schema => 'str*', # XXX filename
            default => do {
                my $path;
                my @paths = (
                    "$ENV{HOME}/notes/download-logs.org",
                    "$ENV{HOME}/download-logs.org",
                );
                for my $p (@paths) {
                    if (-f $p) {
                        $path = $p; last;
                    }
                }
                die "Cannot find download log file, please specify using ".
                    "--log-file or put the log file in one of: ".
                    (join ", ", @paths) unless $path;
                $path;
            },
        },
    },
    deps => {
        prog => 'youtube-dl',
    },
};
sub youtube_dl_if_not_yet {
    my %args = @_;

    my @argv_for_youtube_dl;
    for my $arg (@{$args{urls_or_ids}}) {
        my $video_id = YouTube::Util::extract_youtube_video_id($arg);
        if ($video_id) {
            log_trace "Got video ID %s for argument %s", $video_id, $arg;
            if (my $filename = _search_id_in_log_file($video_id, $args{log_file})) {
                log_info "Video ID %s (%s) has been downloaded, skipped", $video_id, $filename;
                next;
            } else {
                log_trace "Video ID %s is not in downloaded list, passing to youtube-dl", $video_id;
            }
        }
        push @argv_for_youtube_dl, $arg;
    }

    system({log=>1, die=>1}, "youtube-dl", @argv_for_youtube_dl);
    [200];
}

1;
# ABSTRACT: (DEPRECATED) Download videos using youtube-dl only if videos have not been donwnloaded yet

__END__

=pod

=encoding UTF-8

=head1 NAME

App::YoutubeDlIfNotYet - (DEPRECATED) Download videos using youtube-dl only if videos have not been donwnloaded yet

=head1 VERSION

This document describes version 0.003 of App::YoutubeDlIfNotYet (from Perl distribution App-YoutubeDlIfNotYet), released on 2020-04-05.

=head1 DEPRECATION NOTICE

Superseded by L<youtube-dl-if> (from L<App::YoutubeDlIf>).

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 youtube_dl_if_not_yet

Usage:

 youtube_dl_if_not_yet(%args) -> [status, msg, payload, meta]

(DEPRECATED) Download videos using youtube-dl only if videos have not been donwnloaded yet.

This is a wrapper for B<youtube-dl>; it tries to extract downloaded video ID's
from filenames or URL's or video ID's listed in a text file, e.g.:

 35682594        Table Tennis Shots- If Were Not Filmed, Nobody Would Believe [HD]-dUjxqFbWzQo.mp4       date:[2019-12-29 ]

or:

 https://www.youtube.com/embed/U9v2S49sHeQ?rel=0

or:

 U9v2S49sHeQ

When a video ID is found then it is assumed to be already downloaded in the past
and will not be downloaded again.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<log_file> => I<str> (default: "/home/s1/notes/download-logs.org")

File that contains list of download filenames.

=item * B<urls_or_ids>* => I<array[str]>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HISTORY

First written in Apr 2016. Packaged as CPAN distribution in Apr 2020.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-YoutubeDlIfNotYet>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-YoutubeDlIfNotYet>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-YoutubeDlIfNotYet>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::YouTubeUtils> for other YouTube-related CLIs.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

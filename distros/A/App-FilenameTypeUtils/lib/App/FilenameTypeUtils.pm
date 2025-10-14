package App::FilenameTypeUtils;

use strict;
use warnings;

use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-21'; # DATE
our $DIST = 'App-FilenameTypeUtils'; # DIST
our $VERSION = '0.003'; # VERSION

my %argsopt = (
    quiet => {
        schema => 'bool*',
        cmdline_aliases => {q=>{}},
    },
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

sub _gen_wrapper {
    my $what = shift;

    sub {
        my ($orig, %args) = (shift, @_);
        my $detail = delete $args{detail};
        my $quiet  = delete $args{quiet};
        my $res0 = $orig->(@_);
        my $boolres = $res0 ? 1:0;
        my $hashres = $boolres ? $res0 : {};
        [200, "OK", $detail ? $hashres : $boolres, {
            ('cmdline.result' => $quiet ? "" : "Filename '$args{filename}' ".($boolres ? "indicates" : "does NOT indicate")." being $what") x !$detail,
            'cmdline.exit_code' => $boolres ? 0 : 1,
        }];
    };
}

require Filename::Type::Archive;
gen_modified_sub(
    base_name => 'Filename::Type::Archive::check_archive_filename',
    add_args => {
        %argsopt,
    },
    modify_meta => sub {
        $_[0]{result_naked} = 0;
        # XXX we should adjust the examples instead
        delete $_[0]{examples};
    },
    wrap_code => _gen_wrapper('an archive'),
);

require Filename::Type::Audio;
gen_modified_sub(
    base_name => 'Filename::Type::Audio::check_audio_filename',
    add_args => {
        %argsopt,
    },
    modify_meta => sub {
        $_[0]{result_naked} = 0;
        # XXX we should adjust the examples instead
        delete $_[0]{examples};
    },
    wrap_code => _gen_wrapper('an audio file'),
);

require Filename::Type::Backup;
gen_modified_sub(
    base_name => 'Filename::Type::Backup::check_backup_filename',
    add_args => {
        %argsopt,
    },
    modify_meta => sub {
        $_[0]{result_naked} = 0;
        # XXX we should adjust the examples instead
        delete $_[0]{examples};
    },
    wrap_code => _gen_wrapper('a backup file'),
);

require Filename::Type::Compressed;
gen_modified_sub(
    base_name => 'Filename::Type::Compressed::check_compressed_filename',
    add_args => {
        %argsopt,
    },
    modify_meta => sub {
        $_[0]{result_naked} = 0;
        # XXX we should adjust the examples instead
        delete $_[0]{examples};
    },
    wrap_code => _gen_wrapper('a compressed file'),
);

require Filename::Type::Ebook;
gen_modified_sub(
    base_name => 'Filename::Type::Ebook::check_ebook_filename',
    add_args => {
        %argsopt,
    },
    modify_meta => sub {
        $_[0]{result_naked} = 0;
        # XXX we should adjust the examples instead
        delete $_[0]{examples};
    },
    wrap_code => _gen_wrapper('an ebook'),
);

require Filename::Type::Executable;
gen_modified_sub(
    base_name => 'Filename::Type::Executable::check_executable_filename',
    add_args => {
        %argsopt,
    },
    modify_meta => sub {
        $_[0]{result_naked} = 0;
        # XXX we should adjust the examples instead
        delete $_[0]{examples};
    },
    wrap_code => _gen_wrapper('an executable'),
);

require Filename::Type::Image;
gen_modified_sub(
    base_name => 'Filename::Type::Image::check_image_filename',
    add_args => {
        %argsopt,
    },
    modify_meta => sub {
        $_[0]{result_naked} = 0;
        # XXX we should adjust the examples instead
        delete $_[0]{examples};
    },
    wrap_code => _gen_wrapper('an image (picture)'),
);

require Filename::Type::Media;
gen_modified_sub(
    base_name => 'Filename::Type::Media::check_media_filename',
    add_args => {
        %argsopt,
    },
    modify_meta => sub {
        $_[0]{result_naked} = 0;
        # XXX we should adjust the examples instead
        delete $_[0]{examples};
    },
    wrap_code => _gen_wrapper('a media (image/audio/video) file'),
);

require Filename::Type::Video;
gen_modified_sub(
    base_name => 'Filename::Type::Video::check_video_filename',
    add_args => {
        %argsopt,
    },
    modify_meta => sub {
        $_[0]{result_naked} = 0;
        # XXX we should adjust the examples instead
        delete $_[0]{examples};
    },
    wrap_code => _gen_wrapper('a video file'),
);

1;
# ABSTRACT: CLIs for Filename::Type::*

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FilenameTypeUtils - CLIs for Filename::Type::*

=head1 VERSION

This document describes version 0.003 of App::FilenameTypeUtils (from Perl distribution App-FilenameTypeUtils), released on 2024-12-21.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Filename::Type::*
modules:

=over

=item 1. L<check-archive-filename>

=item 2. L<check-audio-filename>

=item 3. L<check-backup-filename>

=item 4. L<check-compressed-filename>

=item 5. L<check-ebook-filename>

=item 6. L<check-executable-filename>

=item 7. L<check-image-filename>

=item 8. L<check-media-filename>

=item 9. L<check-video-filename>

=back

=head1 FUNCTIONS


=head2 check_archive_filename

Usage:

 check_archive_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filename indicates being an archive file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<filename>* => I<str>

(No description)

=item * B<ignore_case> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<quiet> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: C<archive_name>, C<archive_suffix>,
C<compressor_info>, C<filename_without_suffix>.



=head2 check_audio_filename

Usage:

 check_audio_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filename indicates being an audio file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<filename>* => I<filename>

(No description)

=item * B<quiet> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.



=head2 check_backup_filename

Usage:

 check_backup_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filename indicates being a backup file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<detail> => I<bool>

(No description)

=item * B<filename>* => I<str>

(No description)

=item * B<quiet> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (bool|hash)


Return false if not detected as backup name. Otherwise return a hash, which may
contain these keys: C<original_filename>. In the future there will be extra
information returned, e.g. editor name (if filename indicates backup from
certain backup program), date (if filename contains date information), and so
on.



=head2 check_compressed_filename

Usage:

 check_compressed_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filename indicates being compressed.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<filename>* => I<str>

(No description)

=item * B<ignore_case> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<quiet> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (bool|hash)


Return false if no compressor suffixes detected. Otherwise return a hash of
information, which contains these keys: C<compressor_name>, C<compressor_suffix>,
C<uncompressed_filename>.



=head2 check_ebook_filename

Usage:

 check_ebook_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filename indicates being an e-book.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<detail> => I<bool>

(No description)

=item * B<filename>* => I<str>

(No description)

=item * B<quiet> => I<bool>

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



=head2 check_executable_filename

Usage:

 check_executable_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filename indicates being an executable programE<sol>script.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<detail> => I<bool>

(No description)

=item * B<filename>* => I<str>

(No description)

=item * B<quiet> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: C<exec_type>, C<exec_ext>,
C<exec_name>.



=head2 check_image_filename

Usage:

 check_image_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filename indicates being an image.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<filename>* => I<filename>

(No description)

=item * B<quiet> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.



=head2 check_media_filename

Usage:

 check_media_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filename indicates being a media (audioE<sol>videoE<sol>image) file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<filename>* => I<filename>

(No description)

=item * B<quiet> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.



=head2 check_video_filename

Usage:

 check_video_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filename indicates being a video file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<filename>* => I<filename>

(No description)

=item * B<quiet> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FilenameTypeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FilenameUtils>.

=head1 SEE ALSO

C<Filename::Type::*>, e.g.: L<Filename::Type::Archive>,
L<Filename::Type::Audio>, etc.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FilenameTypeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

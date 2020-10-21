package App::FilenameUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-21'; # DATE
our $DIST = 'App-FilenameUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Perinci::Sub::Util qw(gen_modified_sub);

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

require Filename::Archive;
gen_modified_sub(
    base_name => 'Filename::Archive::check_archive_filename',
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

require Filename::Audio;
gen_modified_sub(
    base_name => 'Filename::Audio::check_audio_filename',
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

require Filename::Backup;
gen_modified_sub(
    base_name => 'Filename::Backup::check_backup_filename',
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

require Filename::Compressed;
gen_modified_sub(
    base_name => 'Filename::Compressed::check_compressed_filename',
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

require Filename::Ebook;
gen_modified_sub(
    base_name => 'Filename::Ebook::check_ebook_filename',
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

require Filename::Executable;
gen_modified_sub(
    base_name => 'Filename::Executable::check_executable_filename',
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

require Filename::Image;
gen_modified_sub(
    base_name => 'Filename::Image::check_image_filename',
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

require Filename::Media;
gen_modified_sub(
    base_name => 'Filename::Media::check_media_filename',
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

require Filename::Video;
gen_modified_sub(
    base_name => 'Filename::Video::check_video_filename',
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
# ABSTRACT: CLIs for Filename::*

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FilenameUtils - CLIs for Filename::*

=head1 VERSION

This document describes version 0.002 of App::FilenameUtils (from Perl distribution App-FilenameUtils), released on 2020-10-21.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Filename::* modules:

=over

=item * L<check-archive-filename>

=item * L<check-audio-filename>

=item * L<check-backup-filename>

=item * L<check-compressed-filename>

=item * L<check-ebook-filename>

=item * L<check-executable-filename>

=item * L<check-image-filename>

=item * L<check-media-filename>

=item * L<check-video-filename>

=back

=head1 FUNCTIONS


=head2 check_archive_filename

Usage:

 check_archive_filename(%args) -> [status, msg, payload, meta]

Check whether filename indicates being an archive file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<detail> => I<bool>

=item * B<filename>* => I<str>

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: C<archive_name>, C<archive_suffix>,
C<compressor_info>.



=head2 check_audio_filename

Usage:

 check_audio_filename(%args) -> [status, msg, payload, meta]

Check whether filename indicates being an audio file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<filename>* => I<filename>

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.



=head2 check_backup_filename

Usage:

 check_backup_filename(%args) -> [status, msg, payload, meta]

Check whether filename indicates being a backup file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<detail> => I<bool>

=item * B<filename>* => I<str>

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (bool|hash)


Return false if not detected as backup name. Otherwise return a hash, which may
contain these keys: C<original_filename>. In the future there will be extra
information returned, e.g. editor name (if filename indicates backup from
certain backup program), date (if filename contains date information), and so
on.



=head2 check_compressed_filename

Usage:

 check_compressed_filename(%args) -> [status, msg, payload, meta]

Check whether filename indicates being compressed.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<detail> => I<bool>

=item * B<filename>* => I<str>

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (bool|hash)


Return false if no compressor suffixes detected. Otherwise return a hash of
information, which contains these keys: C<compressor_name>, C<compressor_suffix>,
C<uncompressed_filename>.



=head2 check_ebook_filename

Usage:

 check_ebook_filename(%args) -> [status, msg, payload, meta]

Check whether filename indicates being an e-book.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<detail> => I<bool>

=item * B<filename>* => I<str>

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 check_executable_filename

Usage:

 check_executable_filename(%args) -> [status, msg, payload, meta]

Check whether filename indicates being an executable programE<sol>script.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<detail> => I<bool>

=item * B<filename>* => I<str>

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: C<exec_type>, C<exec_ext>,
C<exec_name>.



=head2 check_image_filename

Usage:

 check_image_filename(%args) -> [status, msg, payload, meta]

Check whether filename indicates being an image.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<filename>* => I<filename>

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.



=head2 check_media_filename

Usage:

 check_media_filename(%args) -> [status, msg, payload, meta]

Check whether filename indicates being a media (audioE<sol>videoE<sol>image) file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<filename>* => I<filename>

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.



=head2 check_video_filename

Usage:

 check_video_filename(%args) -> [status, msg, payload, meta]

Check whether filename indicates being a video file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<filename>* => I<filename>

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FilenameUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FilenameUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FilenameUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Filename::Archive>, L<Filename::Audio>, etc.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

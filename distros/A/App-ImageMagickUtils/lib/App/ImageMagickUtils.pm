package App::ImageMagickUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Exporter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-08'; # DATE
our $DIST = 'App-ImageMagickUtils'; # DIST
our $VERSION = '0.017'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to ImageMagick',
};

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

our %argspecs_delete = (
    delete_original => {
        summary => 'Delete (unlink) the original file after downsizing',
        schema => 'bool*',
        description => <<'_',

See also the `trash_original` option.

_
        cmdline_aliases => {D=>{}},
    },
    trash_original => {
        summary => 'Trash the original file after downsizing',
        schema => 'bool*',
        description => <<'_',

This option uses the <pm:File::Trash::FreeDesktop> module to do the trashing.
Compared to deletion, with this option you can still restore the trashed
original files from the Trash directory.

See also the `delete_original` option.

_
        cmdline_aliases => {T=>{}},
    },
);

our %args_rels = (
    choose_one => [qw/delete_original trash_original/],
);

sub _nearest {
    sprintf("%d", $_[0]/$_[1]) * $_[1];
}

$SPEC{downsize_image} = {
    v => 1.1,
    summary => 'Reduce image size, by default via compressing to JPEG quality 40 and downsizing to 1024p',
    description => <<'_',

This utility uses <prog:convert> utility to compress an image into JPEG with
default quality of 40 and downsized to 1024p (shortest side to 1024px).

Output filenames are:

    ORIGINAL_NAME.q40.jpg

or (if downsizing is done):

    ORIGINAL_NAME.1024p-q40.jgp

_
    args => {
        %argspec0_files,
        quality => {
            schema => ['int*', between=>[0,100]],
            default => 40,
            cmdline_aliases => {q=>{}},
        },
        downsize_to => {
            schema => ['str*', in=>['', '640', '800', '1024', '1536', '2048']],
            default => '1024',
            description => <<'_',

Downsizing will only be done if the input image's shortest side is indeed larger
then the target downsize.

To disable downsizing, set `--downsize-to` to '' (empty string), or specify on
`--dont-downsize` on the CLI.

_
            cmdline_aliases => {
                dont_downsize => {summary=>"Alias for --downsize-to ''", is_flag=>1, code=>sub {$_[0]{downsize_to} = ''}},
                no_downsize   => {summary=>"Alias for --downsize-to ''", is_flag=>1, code=>sub {$_[0]{downsize_to} = ''}},
                1536          => {summary=>"Shortcut for --downsize-to=1536", is_flag=>1, code=>sub {$_[0]{downsize_to} = '1536'}},
                2048          => {summary=>"Shortcut for --downsize-to=2048", is_flag=>1, code=>sub {$_[0]{downsize_to} = '2048'}},
            },
        },
        skip_whatsapp => {
            summary => 'Skip WhatsApp images',
            'summary.alt.bool.not' => 'Do not skip WhatsApp images',
            schema => 'bool*',
            default => 1,
            description => <<'_',

By default, assuming that WhatsApp already compresses images, when given a
filename that matches a WhatsApp image filename, e.g. `IMG-20220508-WA0001.jpg`
(will be checked using <pm:Regexp::Pattern::Filename::Image::WhatsApp>), will
skip downsizing. The `--no-skip-whatsapp` option will process such filenames
nevertheless.

_
        },
        skip_downsized => {
            summary => 'Skip previously downsized images',
            'summary.alt.bool.not' => 'Do not skip previously downsized images',
            schema => 'bool*',
            default => 1,
            description => <<'_',

By default, when given a filename that looks like it's already downsized, e.g.
`foo.1024-q40.jpg` or `foo.q40.jpg`, will skip downsizing. The
`--no-skip-downsized` option will process such filenames nevertheless.

_
        },
        %argspecs_delete,
    },
    args_rels => \%args_rels,
    features => {
        dry_run => 1,
    },
    examples => [
        {
            summary => 'The default setting is to downsize to 1024p',
            src => 'downsize-image *',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Do not downsize, just recompress to JPEG quality 40, delete original files',
            src => 'downsize-image --dont-downsize --delete-original *',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub downsize_image {
    require File::Which;
    require Image::Size;
    require IPC::System::Options;
    #require Filename::Image;

    my %args = @_;

    my $convert_path = File::Which::which("convert");
    my $downsize_to = $args{downsize_to};
    my $skip_whatsapp = $args{skip_whatsapp} // 1;
    my $skip_downsized = $args{skip_downsized} // 1;

    unless ($args{-dry_run}) {
        return [400, "Cannot find convert in path"] unless defined $convert_path;
        return [400, "convert path $convert_path is not executable"] unless -x $convert_path;
    }

    my ($num_files, $num_success) = (0, 0);
    my $trash;
  FILE:
    for my $file (@{$args{files}}) {
        log_info "Processing file %s ...", $file;
        $num_files++;

        unless (-f $file) {
            log_error "No such file %s, skipped", $file;
            next FILE;
        }

        #my $res = Filename::Image::check_image_filename(filename => $file);
        my ($width, $height, $fmt) = Image::Size::imgsize($file);
        unless ($width) {
            log_error "Filename '%s' is not image (%s), skipped", $file, $fmt;
            next FILE;
        }

        if ($skip_whatsapp) {
            require Regexp::Pattern::Filename::Image::WhatsApp;
            if ($file =~ $Regexp::Pattern::Filename::Image::WhatsApp::RE{filename_image_whatsapp}{pat}) {
                log_info "Filename '%s' looks like a WhatsApp image, skip downsizing due to --skip-whatsapp option is in effect", $file;
                next FILE;
            }
        }

        if ($skip_downsized) {
            if ($file =~ /\.(?:\d+p?-)?q(?:\d{1,3})\.\w+\z/) {
                log_info "Filename '%s' looks like it's already downsized, skip downsizing due to --skip-downsized option is in effect", $file;
                next FILE;
            }
        }

        my $q = $args{quality} // 40;
        my @convert_args = (
            $file,
        );

        my $downsized;
        #say "D:downsize_to=<$downsize_to>, width=<$width>, height=<$height>, q=<$q>";
      DOWNSIZE: {
            last unless $downsize_to;
            my $ratio;
            my $shortest_side = $width > $height ? $height : $width;
            last unless $shortest_side > $downsize_to;
            $downsized++;
            push @convert_args, "-resize", "$downsize_to^>";
        } # DOWNSIZE

        push @convert_args, "-quality", $q;

        my $output_file = $file;
        my $ext = $downsized ? ".$downsize_to-q$q.jpg" : ".q$q.jpg";
        $output_file =~ s/(\.\w{3,4})?\z/($1 eq ".jpg" ? "" : $1) . $ext/e;

        push @convert_args, (
            $output_file,
        );

        if ($args{-dry_run}) {
            log_info "[DRY-RUN] Running $convert_path with args %s ...", \@convert_args;
            $num_success++;
            next FILE;
        }

        IPC::System::Options::system(
            {log=>1},
            $convert_path, @convert_args,
        );
        if ($?) {
            my ($exit_code, $signal, $core_dump) = ($? < 0 ? $? : $? >> 8, $? & 127, $? & 128);
            log_error "convert for $file failed: exit_code=$exit_code, signal=$signal, core_dump=$core_dump";
        } else {
            if ($args{trash_original}) {
                require File::Trash::FreeDesktop;
                $trash //= File::Trash::FreeDesktop->new;
                log_info "Trashing original file %s ...", $file;
                # will die upon failure, currently we don't trap
                $trash->trash($file);
            } elsif ($args{delete_original}) {
                # currently we ignore the results
                log_info "Deleting original file %s ...", $file;
                unlink $file;
            }
            $num_success++;
        }
    }

    $num_success == 0 ? [500, "All files failed"] : [200];
}

$SPEC{convert_image_to} = {
    v => 1.1,
    summary => 'Convert images using ImageMagick\'s \'convert\' utility, with multiple file support and automatic output naming',
    description => <<'_',

This is a simple wrapper to ImageMagick's `convert` utility to let you process
multiple files using a single command:

    % convert-image-to --to pdf *.jpg

is basically equivalent to:

    % for f in *.jpg; do convert "$f" "$f.pdf"; done

_
    args => {
        %argspec0_files,
        to => {
            schema => ['str*', match=>qr/\A\w+\z/],
            req => 1,
            examples => [qw/pdf jpg png/], # for tab completion
        },
        %argspecs_delete,
    },
    #features => {
    #    dry_run => 1,
    #},
    deps => {
        prog => 'convert',
    },
    examples => [
    ],
};
sub convert_image_to {
    require IPC::System::Options;
    require Perinci::Object;
    require Process::Status;

    my %args = @_;

    my $to = $args{to} or return [400, "Please specify target format in `to`"];

    my $envres = Perinci::Object::envresmulti();
    my $trash;
    for my $file (@{$args{files}}) {
        log_info "Processing file %s ...", $file;
        IPC::System::Options::system(
            {log=>1},
            "convert", $file, "$file.$to",
        );
        my $ps = Process::Status->new;

        if ($ps->is_success) {
            $envres->add_result(200, "OK", {item_id=>$file});
            if ($args{trash_original}) {
                require File::Trash::FreeDesktop;
                $trash //= File::Trash::FreeDesktop->new;
                log_info "Trashing original file %s ...", $file;
                # will die upon failure, currently we don't trap
                $trash->trash($file);
            } elsif ($args{delete_original}) {
                # currently we ignore the result of deletion
                log_info "Deleting original file %s ...", $file;
                unlink $file;
            }
        } else {
            $envres->add_result(500, "Failed (exit code ".$ps->exitstatus.")", {item_id=>$file});
        }
    }
    $envres->as_struct;
}

$SPEC{convert_image_to_pdf} = {
    v => 1.1,
    summary => 'Convert images to PDF using ImageMagick\'s \'convert\' utility',
    description => <<'_',

This is a wrapper to `convert-image-to`, with `--to` set to `pdf`:

    % convert-image-to-pdf *.jpg

is equivalent to:

    % convert-image-to --to pdf *.jpg

which in turn is equivalent to:

    % for f in *.jpg; do convert "$f" "$f.pdf"; done

_
    args => {
        %argspec0_files,
        %argspecs_delete,
    },
    #features => {
    #    dry_run => 1,
    #},
    deps => {
        prog => 'convert',
    },
    examples => [
    ],
};
sub convert_image_to_pdf {
    my %args = @_;
    convert_image_to(%args, to=>'pdf');
}

1;
# ABSTRACT: Utilities related to ImageMagick

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ImageMagickUtils - Utilities related to ImageMagick

=head1 VERSION

This document describes version 0.017 of App::ImageMagickUtils (from Perl distribution App-ImageMagickUtils), released on 2022-05-08.

=head1 DESCRIPTION

This distribution includes the following CLI utilities related to ImageMagick:

=over

=item * L<calc-image-resized-size>

=item * L<convert-image-to>

=item * L<convert-image-to-pdf>

=item * L<downsize-image>

=item * L<image-resize-notation-to-human>

=item * L<img2pdf>

=back

=head1 FUNCTIONS


=head2 convert_image_to

Usage:

 convert_image_to(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert images using ImageMagick's 'convert' utility, with multiple file support and automatic output naming.

This is a simple wrapper to ImageMagick's C<convert> utility to let you process
multiple files using a single command:

 % convert-image-to --to pdf *.jpg

is basically equivalent to:

 % for f in *.jpg; do convert "$f" "$f.pdf"; done

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<delete_original> => I<bool>

Delete (unlink) the original file after downsizing.

See also the C<trash_original> option.

=item * B<files>* => I<array[filename]>

=item * B<to>* => I<str>

=item * B<trash_original> => I<bool>

Trash the original file after downsizing.

This option uses the L<File::Trash::FreeDesktop> module to do the trashing.
Compared to deletion, with this option you can still restore the trashed
original files from the Trash directory.

See also the C<delete_original> option.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_image_to_pdf

Usage:

 convert_image_to_pdf(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert images to PDF using ImageMagick's 'convert' utility.

This is a wrapper to C<convert-image-to>, with C<--to> set to C<pdf>:

 % convert-image-to-pdf *.jpg

is equivalent to:

 % convert-image-to --to pdf *.jpg

which in turn is equivalent to:

 % for f in *.jpg; do convert "$f" "$f.pdf"; done

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<delete_original> => I<bool>

Delete (unlink) the original file after downsizing.

See also the C<trash_original> option.

=item * B<files>* => I<array[filename]>

=item * B<trash_original> => I<bool>

Trash the original file after downsizing.

This option uses the L<File::Trash::FreeDesktop> module to do the trashing.
Compared to deletion, with this option you can still restore the trashed
original files from the Trash directory.

See also the C<delete_original> option.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 downsize_image

Usage:

 downsize_image(%args) -> [$status_code, $reason, $payload, \%result_meta]

Reduce image size, by default via compressing to JPEG quality 40 and downsizing to 1024p.

This utility uses L<convert> utility to compress an image into JPEG with
default quality of 40 and downsized to 1024p (shortest side to 1024px).

Output filenames are:

 ORIGINAL_NAME.q40.jpg

or (if downsizing is done):

 ORIGINAL_NAME.1024p-q40.jgp

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<delete_original> => I<bool>

Delete (unlink) the original file after downsizing.

See also the C<trash_original> option.

=item * B<downsize_to> => I<str> (default: 1024)

Downsizing will only be done if the input image's shortest side is indeed larger
then the target downsize.

To disable downsizing, set C<--downsize-to> to '' (empty string), or specify on
C<--dont-downsize> on the CLI.

=item * B<files>* => I<array[filename]>

=item * B<quality> => I<int> (default: 40)

=item * B<skip_downsized> => I<bool> (default: 1)

Skip previously downsized images.

By default, when given a filename that looks like it's already downsized, e.g.
C<foo.1024-q40.jpg> or C<foo.q40.jpg>, will skip downsizing. The
C<--no-skip-downsized> option will process such filenames nevertheless.

=item * B<skip_whatsapp> => I<bool> (default: 1)

Skip WhatsApp images.

By default, assuming that WhatsApp already compresses images, when given a
filename that matches a WhatsApp image filename, e.g. C<IMG-20220508-WA0001.jpg>
(will be checked using L<Regexp::Pattern::Filename::Image::WhatsApp>), will
skip downsizing. The C<--no-skip-whatsapp> option will process such filenames
nevertheless.

=item * B<trash_original> => I<bool>

Trash the original file after downsizing.

This option uses the L<File::Trash::FreeDesktop> module to do the trashing.
Compared to deletion, with this option you can still restore the trashed
original files from the Trash directory.

See also the C<delete_original> option.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-ImageMagickUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ImageMagickUtils>.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ImageMagickUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

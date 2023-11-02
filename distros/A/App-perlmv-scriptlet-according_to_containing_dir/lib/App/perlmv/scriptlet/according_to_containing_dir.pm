package App::perlmv::scriptlet::according_to_containing_dir;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-26'; # DATE
our $DIST = 'App-perlmv-scriptlet-according_to_containing_dir'; # DIST
our $VERSION = '0.001'; # VERSION

our $SCRIPTLET = {
    summary => q[Rename file according to its containing directory's name, e.g. foo/1.txt to foo/foo.txt, or foo/somejpeg to foo/foo.jpg],
    description => <<'MARKDOWN',

In addition to renaming the file according to the name of its container
directory, if the file does not have an extension yet, an extension will be
given by guessing according to its MIME type using <pm:File::MimeInfo::Magic>,
similar to what the `add_extension_according_to_mime_type` scriptlet does.

MARKDOWN
    code => sub {
        package
            App::perlmv::code;

        # we skip directories
        if (-d $_) {
            warn "Directory '$_' skipped\n";
            return;
        }

        # guess file extension
        my ($ext) = /\.(\w+)\z/;
      GUESS_EXT: {
            if (defined $ext) {
                warn "DEBUG: File '$_' already has extension '$ext', skipped guessing extension\n" if $ENV{DEBUG};
                last;
            }

            require File::MimeInfo::Magic;

            my $arg;
            if (-l $_) { open my $fh, "<", $_ or do { warn "Can't open symlink $_: $!, skipped\n"; return }; $arg = $fh } else { $arg = $_ }
            my $type = File::MimeInfo::Magic::mimetype($arg);
            unless ($type) {
                warn "Can't get MIME type from file '$_', skipped guessing extension\n";
                last;
            }
            my @exts = File::MimeInfo::Magic::extensions($type) or die "Bug! extensions() does not return extensions for type '$type'";
            warn "DEBUG: extensions from extensions($type) for file '$_': ".join(", ", @exts)."\n" if $ENV{DEBUG};

            $ext = $exts[0];
        } # GUESS_EXT

        # determine the container directory's name
        no warnings 'once';
        my $dirname = $App::perlmv::code::DIR;
        $dirname =~ s!/\z!!;
        $dirname =~ s!.+/!!;

        defined $ext ? "$dirname.$ext" : $dirname;
    },
};

1;

# ABSTRACT: Rename file according to its containing directory's name, e.g. foo/1.txt to foo/foo.txt, or foo/somejpeg to foo/foo.jpg

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::according_to_containing_dir - Rename file according to its containing directory's name, e.g. foo/1.txt to foo/foo.txt, or foo/somejpeg to foo/foo.jpg

=head1 VERSION

This document describes version 0.001 of App::perlmv::scriptlet::according_to_containing_dir (from Perl distribution App-perlmv-scriptlet-according_to_containing_dir), released on 2023-10-26.

=head1 DESCRIPTION

In addition to renaming the file according to the name of its container
directory, if the file does not have an extension yet, an extension will be
given by guessing according to its MIME type using L<File::MimeInfo::Magic>,
similar to what the C<add_extension_according_to_mime_type> scriptlet does.

=head1 ENVIRONMENT

=head2 DEBUG

Bool. If set to true, will print debugging messages to stderr.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv-scriptlet-according_to_containing_dir>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv-scriptlet-according_to_containing_dir>.

=head1 SEE ALSO

L<App::perlmv::scriptlet::add_extension_according_to_mime_type>

L<perlmv> (from L<App::perlmv>)

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv-scriptlet-according_to_containing_dir>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

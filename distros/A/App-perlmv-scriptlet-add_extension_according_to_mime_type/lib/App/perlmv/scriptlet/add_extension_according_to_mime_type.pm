package App::perlmv::scriptlet::add_extension_according_to_mime_type;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-30'; # DATE
our $DIST = 'App-perlmv-scriptlet-add_extension_according_to_mime_type'; # DIST
our $VERSION = '0.607'; # VERSION

our $SCRIPTLET = {
    summary => q[Guess the file content's MIME type using File::MimeInfo::Magic then if type can be guessed and file doesn't yet have extension or has unmatching extension then add an extension],
    code => sub {
        package
            App::perlmv::code;
        require File::MimeInfo::Magic;

        # we skip directories
        return if -d $_;

        my $arg;
        if (-l $_) { open my $fh, "<", $_ or do { warn "Can't open symlink $_: $!, skipped\n"; return }; $arg = $fh } else { $arg = $_ }
        my $type = File::MimeInfo::Magic::mimetype($arg);
        return unless $type;
        my @exts = File::MimeInfo::Magic::extensions($type) or die "Bug! extensions() does not return extensions for type '$type'";
        warn "DEBUG: extensions from type: ".join(", ", @exts)."\n" if $ENV{DEBUG};
        my $has_ext;
        for my $ext (@exts) {
            if (/\.\Q$ext\E\z/i) {
                $has_ext++;
                last;
            }
        }
        if ($has_ext) { warn "DEBUG: filename $_ already has extension, skipped\n" if $ENV{DEBUG} }
        $_ = "$_.$exts[0]" unless $has_ext;
        $_;
    },
};

1;

# ABSTRACT: Guess the file content's MIME type using File::MimeInfo::Magic then if type can be guessed and file doesn't yet have extension or has unmatching extension then add an extension

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::add_extension_according_to_mime_type - Guess the file content's MIME type using File::MimeInfo::Magic then if type can be guessed and file doesn't yet have extension or has unmatching extension then add an extension

=head1 VERSION

This document describes version 0.607 of App::perlmv::scriptlet::add_extension_according_to_mime_type (from Perl distribution App-perlmv-scriptlet-add_extension_according_to_mime_type), released on 2023-06-30.

=head1 ENVIRONMENT

=head2 DEBUG

Bool. If set to true, will print debugging messages to stderr.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv-scriptlet-add_extension_according_to_mime_type>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv-scriptlet-add_extension_according_to_mime_type>.

=head1 SEE ALSO

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv-scriptlet-add_extension_according_to_mime_type>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

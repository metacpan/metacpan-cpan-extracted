package Acme::CPANModules::CLI::Wrapper::UnixCommand;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-14'; # DATE
our $DIST = 'Acme-CPANModules-CLI-Wrapper-UnixCommand'; # DIST
our $VERSION = '0.007'; # VERSION

our $LIST = {
    summary => "Various CLIs that wrap existing Unix commands",
    description => <<'_',

These CLI's usually are meant to be called as the Unix commands they wrap, e.g.:

    alias ssh=sshwrap-hostcolor

But they perform additional stuffs.

If you know of others, please drop me a message.

_
    entries => [
        # convert (ImageMagick)
        {
            summary => 'Simple wrappers for ImageMagick\'s convert to process multiple filenames and automatically set output filenames',
            module => 'App::ImageMagickUtils',
            script => ['convert-image-to', 'convert-image-to-pdf'],
            'x.command' => 'convert',
        },

        # cp, mv (ImageMagick)
        {
            summary => 'Wrappers for cp & mv to adjust relative symlinks',
            module => 'App::CpMvUtils',
            script => ['cp-and-adjust-symlinks', 'mv-and-adjust-symlinks'],
            'x.command' => ['cp', 'mv'],
        },

        # diff
        {
            summary => 'Wraps (or filters output of) diff to add colors and highlight words',
            module => 'App::diffwc',
            script => ['diffwc', 'diffwc-filter-u'],
            'x.command' => 'diff',
        },
        {
            summary => 'Diffs two office word-processor documents by first converting them to plaintext',
            module => 'App::DiffDocText',
            script => ['diff-doc-text'],
            'x.command' => 'diff',
        },
        {
            summary => 'Diffs two PDF files by first converting to plaintext',
            module => 'App::DiffPDFText',
            script => ['diff-pdf-text'],
            'x.command' => 'diff',
        },
        {
            summary => 'Diffs two office spreadsheets by first converting them to directories of CSV files',
            module => 'App::DiffXlsText',
            script => ['diff-xls-text'],
            'x.command' => 'diff',
        },
        {
            summary => 'Provides sdif (diff side-by-side with nice color theme), cdif (highlight words with nice color scheme), and watchdiff (watch command and diff output)',
            module => 'App::sdif',
            script => ['sdif', 'cdif', 'watchdiff'],
            'x.command' => ['diff', 'watch'],
        },

        # git
        {
            summary => 'Wraps git to do additional stuff, e.g. set user+email automatically',
            module => 'App::gitwrap',
            script => 'gitwrap',
            'x.command' => 'git',
        },

        # grep
        {
            summary => 'Print lines that match terms (each term need not be in particular order, support negative search)',
            module => 'App::GrepUtils',
            script => ['grep-terms'],
            'x.command' => ['grep'],
        },

        # man
        {
            summary => 'Wraps man to search for (and tab-complete) Perl module documentation',
            module => 'App::manwrap::pm',
            script => 'manwrap-pm',
            'x.command' => 'man',
        },

        # rsync
        {
            summary => 'Wraps rsync to add color to output, particularly highlighting deletion',
            module => 'App::rsynccolor',
            script => 'rsynccolor',
            'x.command' => 'rsync',
        },
        {
            summary => 'Wraps rsync to check that source is newer than target',
            module => 'App::rsync::new2old',
            script => 'rsync-new2old',
            'x.command' => 'rsync',
        },

        # ssh
        {
            summary => 'Wraps ssh to remember the background terminal color of each user+host you went to',
            module => 'App::sshwrap::hostcolor',
            script => 'sshwrap-hostcolor',
            'x.command' => 'ssh',
        },

    ],
};

1;
# ABSTRACT: Various CLIs that wrap existing Unix commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CLI::Wrapper::UnixCommand - Various CLIs that wrap existing Unix commands

=head1 VERSION

This document describes version 0.007 of Acme::CPANModules::CLI::Wrapper::UnixCommand (from Perl distribution Acme-CPANModules-CLI-Wrapper-UnixCommand), released on 2021-11-14.

=head1 DESCRIPTION

These CLI's usually are meant to be called as the Unix commands they wrap, e.g.:

 alias ssh=sshwrap-hostcolor

But they perform additional stuffs.

If you know of others, please drop me a message.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::ImageMagickUtils> - Simple wrappers for ImageMagick's convert to process multiple filenames and automatically set output filenames

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Scripts: L<convert-image-to>, L<convert-image-to-pdf>

=item * L<App::CpMvUtils> - Wrappers for cp & mv to adjust relative symlinks

Scripts: L<cp-and-adjust-symlinks>, L<mv-and-adjust-symlinks>

=item * L<App::diffwc> - Wraps (or filters output of) diff to add colors and highlight words

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Scripts: L<diffwc>, L<diffwc-filter-u>

=item * L<App::DiffDocText> - Diffs two office word-processor documents by first converting them to plaintext

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<diff-doc-text>

=item * L<App::DiffPDFText> - Diffs two PDF files by first converting to plaintext

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<diff-pdf-text>

=item * L<App::DiffXlsText> - Diffs two office spreadsheets by first converting them to directories of CSV files

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<diff-xls-text>

=item * L<App::sdif> - Provides sdif (diff side-by-side with nice color theme), cdif (highlight words with nice color scheme), and watchdiff (watch command and diff output)

Author: L<UTASHIRO|https://metacpan.org/author/UTASHIRO>

Scripts: L<sdif>, L<cdif>, L<watchdiff>

=item * L<App::gitwrap> - Wraps git to do additional stuff, e.g. set user+email automatically

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<gitwrap>

=item * L<App::GrepUtils> - Print lines that match terms (each term need not be in particular order, support negative search)

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<grep-terms>

=item * L<App::manwrap::pm> - Wraps man to search for (and tab-complete) Perl module documentation

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<manwrap-pm>

=item * L<App::rsynccolor> - Wraps rsync to add color to output, particularly highlighting deletion

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<rsynccolor>

=item * L<App::rsync::new2old> - Wraps rsync to check that source is newer than target

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<rsync-new2old>

=item * L<App::sshwrap::hostcolor> - Wraps ssh to remember the background terminal color of each user+host you went to

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<sshwrap-hostcolor>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n CLI::Wrapper::UnixCommand

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CLI::Wrapper::UnixCommand | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CLI::Wrapper::UnixCommand -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CLI::Wrapper::UnixCommand -E'say $_->{module} for @{ $Acme::CPANModules::CLI::Wrapper::UnixCommand::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CLI-Wrapper-UnixCommand>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CLI-Wrapper-UnixCommand>.

=head1 SEE ALSO

Other variants for C<grep>: L<Acme::CPANModules::GrepVariants>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CLI-Wrapper-UnixCommand>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

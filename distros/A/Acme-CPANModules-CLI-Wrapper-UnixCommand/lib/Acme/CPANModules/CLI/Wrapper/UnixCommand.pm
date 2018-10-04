package Acme::CPANModules::CLI::Wrapper::UnixCommand;

our $DATE = '2018-09-30'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Various CLIs that wrap (popular) Unix commands",
    description => <<'_',

These CLI's usually are meant to be called as the Unix commands they wrap, e.g.:

    alias ssh=sshwrap-hostcolor

But they perform additional stuff.

If you know of others, please drop me a message.

_
    entries => [
        {
            summary => 'Wraps ssh to remember the background terminal color of each user+host you went to',
            module => 'App::sshwrap::hostcolor',
            script => 'sshwrap-hostcolor',
            'x.command' => 'ssh',
        },
        {
            summary => 'Wraps man to search for (and tab-complete) Perl module documentation',
            module => 'App::manwrap::pm',
            script => 'manwrap-pm',
            'x.command' => 'man',
        },
        {
            summary => 'Wraps git to do additional stuff, e.g. set user+email automatically',
            module => 'App::gitwrap',
            script => 'gitwrap',
            'x.command' => 'git',
        },
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
        {
            summary => 'Wraps cpanm to use local CPAN mirror and let you specify script name to install instead of module name',
            module => 'App::lcpan',
            script => ['lcpanm', 'lcpanm-script'],
            'x.command' => 'cpanm',
        },
        {
            summary => 'Wraps (or filters output of) diff to add colors and highlight words',
            module => 'App::diffwc',
            script => ['diffwc', 'diffwc-filter-u'],
            'x.command' => 'diff',
        },
    ],
};

1;
# ABSTRACT: Various CLIs that wrap (popular) Unix commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CLI::Wrapper::UnixCommand - Various CLIs that wrap (popular) Unix commands

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::CLI::Wrapper::UnixCommand (from Perl distribution Acme-CPANModules-CLI-Wrapper-UnixCommand), released on 2018-09-30.

=head1 DESCRIPTION

Various CLIs that wrap (popular) Unix commands.

These CLI's usually are meant to be called as the Unix commands they wrap, e.g.:

 alias ssh=sshwrap-hostcolor

But they perform additional stuff.

If you know of others, please drop me a message.

=head1 INCLUDED MODULES

=over

=item * L<App::sshwrap::hostcolor> - Wraps ssh to remember the background terminal color of each user+host you went to

=item * L<App::manwrap::pm> - Wraps man to search for (and tab-complete) Perl module documentation

=item * L<App::gitwrap> - Wraps git to do additional stuff, e.g. set user+email automatically

=item * L<App::rsynccolor> - Wraps rsync to add color to output, particularly highlighting deletion

=item * L<App::rsync::new2old> - Wraps rsync to check that source is newer than target

=item * L<App::lcpan> - Wraps cpanm to use local CPAN mirror and let you specify script name to install instead of module name

=item * L<App::diffwc> - Wraps (or filters output of) diff to add colors and highlight words

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CLI-Wrapper-UnixCommand>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CLI-Wrapper-UnixCommand>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CLI-Wrapper-UnixCommand>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Acme::CPANModules::UnixCommandVariants;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-09-19'; # DATE
our $DIST = 'Acme-CPANModules-UnixCommandVariants'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of various CLIs that are some variants of traditional Unix commands",
    description => <<'MARKDOWN',

MARKDOWN
    entries => [
        # cat
        {
            module => 'App::prefixcat',
            script => 'prefixcat',
            'x.command' => 'cat',
            summary => 'A `cat` variant that print filename at the start of each output line (can also print other prefix)',
        },

        # find
        {
            module => 'App::findsort',
            script => 'findsort',
            'x.command' => 'find',
            'x.is_wrapper' => 1,
            summary => 'A `find` variant (actually wrapper) that can sort its output',
        },

        # rsync
        {
            module => 'App::rsynccolor',
            script => 'rsynccolor',
            'x.command' => 'rsync',
            'x.is_wrapper' => 1,
            summary => 'An `rsync` variant (actually wrapper) that colors its output for visual hints',
        },

        # uniq
        {
            module => 'App::nauniq',
            script => 'nauniq',
            'x.command' => 'uniq',
            summary => 'A `uniq` variant that can remember non-adjacent duplicate lines',
        },
    ],
};

1;
# ABSTRACT: List of various CLIs that are some variants of traditional Unix commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::UnixCommandVariants - List of various CLIs that are some variants of traditional Unix commands

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::UnixCommandVariants (from Perl distribution Acme-CPANModules-UnixCommandVariants), released on 2024-09-19.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::prefixcat>

A `cat` variant that print filename at the start of each output line (can also print other prefix).

Script: L<prefixcat>

=item L<App::findsort>

A `find` variant (actually wrapper) that can sort its output.

Script: L<findsort>

=item L<App::rsynccolor>

An `rsync` variant (actually wrapper) that colors its output for visual hints.

Script: L<rsynccolor>

=item L<App::nauniq>

A `uniq` variant that can remember non-adjacent duplicate lines.

Script: L<nauniq>

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

 % cpanm-cpanmodules -n UnixCommandVariants

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries UnixCommandVariants | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=UnixCommandVariants -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::UnixCommandVariants -E'say $_->{module} for @{ $Acme::CPANModules::UnixCommandVariants::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-UnixCommandVariants>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-UnixCommandVariants>.

=head1 SEE ALSO

Variants for C<grep> have their own list: L<Acme::CPANModules::GrepVariants>

L<Acme::CPANModules::UnixCommandWrappers>

L<Acme::CPANModules::UnixCommandImplementations>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-UnixCommandVariants>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

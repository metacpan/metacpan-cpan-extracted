package Acme::CPANModules::CLI::Sort;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-CLI-Sort'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of various CLIs to perform sorting",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            summary => 'Sort JSON objects by key field(s)',
            module => 'App::PipeFilter',
            script => 'jsort',
        },
        {
            summary => 'Sort version numbers',
            module => 'App::VersionUtils',
            script => 'sort-versions',
        },
        {
            summary => 'Sort lines of text using Sort::Sub routines',
            module => 'App::subsort',
            script => 'subsort',
            related_modules => ['Sub::Sort'],
        },
        {
            summary => 'Sort XML "records"',
            module => 'Unicode::Tussle',
            script => 'xmlsort',
        },
        {
            summary => 'Topological sort',
            module => 'PerlPowerTools',
            script => 'tsort',
        },
        {
            summary => 'Another topological sort script',
            module => 'App::toposort',
            script => 'toposort',
        },
        {
            summary => 'Sort lines of text (Perl port of the sort Unix command)',
            module => 'PerlPowerTools',
            script => 'sort',
        },
        {
            summary => 'Sort lines of text using cmp operator or custom Perl code',
            module => 'App::psort',
            script => 'psort',
        },
        {
            summary => 'Sort lines of text by their length',
            module => 'App::lensort',
            script => 'lensort',
        },
    ],
};

1;
# ABSTRACT: List of various CLIs to perform sorting

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CLI::Sort - List of various CLIs to perform sorting

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::CLI::Sort (from Perl distribution Acme-CPANModules-CLI-Sort), released on 2022-03-18.

=head1 DESCRIPTION

If you know of others, please drop me a message.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::PipeFilter> - Sort JSON objects by key field(s)

Author: L<RCAPUTO|https://metacpan.org/author/RCAPUTO>

Script: L<jsort>

=item * L<App::VersionUtils> - Sort version numbers

Script: L<sort-versions>

=item * L<App::subsort> - Sort lines of text using Sort::Sub routines

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Related modules: L<Sub::Sort>

Script: L<subsort>

=item * L<Unicode::Tussle> - Sort XML "records"

Author: L<BDFOY|https://metacpan.org/author/BDFOY>

Script: L<xmlsort>

=item * L<PerlPowerTools> - Topological sort

Author: L<BDFOY|https://metacpan.org/author/BDFOY>

Script: L<tsort>

=item * L<App::toposort> - Another topological sort script

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<toposort>

=item * L<PerlPowerTools> - Sort lines of text (Perl port of the sort Unix command)

Author: L<BDFOY|https://metacpan.org/author/BDFOY>

Script: L<sort>

=item * L<App::psort> - Sort lines of text using cmp operator or custom Perl code

Author: L<SREZIC|https://metacpan.org/author/SREZIC>

Script: L<psort>

=item * L<App::lensort> - Sort lines of text by their length

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<lensort>

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

 % cpanm-cpanmodules -n CLI::Sort

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CLI::Sort | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CLI::Sort -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CLI::Sort -E'say $_->{module} for @{ $Acme::CPANModules::CLI::Sort::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CLI-Sort>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CLI-Sort>.

=head1 SEE ALSO

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

This software is copyright (c) 2022, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CLI-Sort>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package Acme::CPANModules::PERLANCAR::Weird;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-01'; # DATE
our $DIST = 'Acme-CPANModulesBundle-PERLANCAR'; # DIST
our $VERSION = '0.014'; # VERSION

our $LIST = {
    summary => 'List of weird modules',
    description => <<'_',

List of modules I find weird (non-pejoratively speaking) in one way or another,
e.g. peculiar API, name.

_
    entries => [
        {
            module => 'String::Tools',
            description => <<'_',

Function names chosen are too similar with perl's builtins and will be prone to
typos: `subst` (`substr`), `define` (`defined`). I don't think `stitch` is more
intuitive to me compared to `join()`.

_
        },
    ],
};

1;
# ABSTRACT: List of weird modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::Weird - List of weird modules

=head1 VERSION

This document describes version 0.014 of Acme::CPANModules::PERLANCAR::Weird (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2023-11-01.

=head1 DESCRIPTION

List of modules I find weird (non-pejoratively speaking) in one way or another,
e.g. peculiar API, name.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<String::Tools>

Author: L<BOBK|https://metacpan.org/author/BOBK>

Function names chosen are too similar with perl's builtins and will be prone to
typos: C<subst> (C<substr>), C<define> (C<defined>). I don't think C<stitch> is more
intuitive to me compared to C<join()>.


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

 % cpanm-cpanmodules -n PERLANCAR::Weird

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PERLANCAR::Weird | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PERLANCAR::Weird -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PERLANCAR::Weird -E'say $_->{module} for @{ $Acme::CPANModules::PERLANCAR::Weird::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesBundle-PERLANCAR>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

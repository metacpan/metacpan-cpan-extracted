package Acme::CPANModules::Interop::Ruby;

use strict;
#use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-04'; # DATE
our $DIST = 'Acme-CPANModules-Interop-Ruby'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of modules/applications that help interoperate with the Ruby world",
    entries => [
        {
            module => 'Inline::Ruby',
            summary => 'Write Ruby code inside your Perl code',
            tags => ['code'],
        },
        {
            module => 'Ruby',
            summary => 'API to local Ruby interpreter',
            tags => ['interpreter'],
        },
        {
            module => 'Data::Format::Pretty::Ruby',
            summary => 'Like Data::Dumper but outputs Ruby code',
            tags => ['data'],
        },
        {
            module => 'mRuby',
            summary => 'Binding to the embedded Ruby interpreter',
            tags => ['interpreter'],
        },
        {
            module => 'HTML::ERuby',
            summary => 'Parse ERuby document',
            tags => [],
        },
    ],
};

1;
# ABSTRACT: List of modules/applications that help interoperate with the Ruby world

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Interop::Ruby - List of modules/applications that help interoperate with the Ruby world

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::Interop::Ruby (from Perl distribution Acme-CPANModules-Interop-Ruby), released on 2022-02-04.

=head1 DESCRIPTION

=head2 SEE ALSO

L<Acme::CPANModules::Interop::Python> and other
C<Acme::CPANModules::Interop::*> modules.

L<Acme::CPANModules::PortedFrom::Ruby>

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Inline::Ruby> - Write Ruby code inside your Perl code

Author: L<SHLOMIF|https://metacpan.org/author/SHLOMIF>

=item * L<Ruby> - API to local Ruby interpreter

Author: L<GFUJI|https://metacpan.org/author/GFUJI>

=item * L<Data::Format::Pretty::Ruby> - Like Data::Dumper but outputs Ruby code

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<mRuby> - Binding to the embedded Ruby interpreter

Author: L<KARUPA|https://metacpan.org/author/KARUPA>

=item * L<HTML::ERuby> - Parse ERuby document

Author: L<IKEBE|https://metacpan.org/author/IKEBE>

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

 % cpanm-cpanmodules -n Interop::Ruby

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Interop::Ruby | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Interop::Ruby -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Interop::Ruby -E'say $_->{module} for @{ $Acme::CPANModules::Interop::Ruby::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Interop-Ruby>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Interop-Ruby>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Interop-Ruby>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

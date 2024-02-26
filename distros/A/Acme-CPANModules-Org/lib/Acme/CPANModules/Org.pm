package Acme::CPANModules::Org;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-Org'; # DIST
our $VERSION = '0.005'; # VERSION

our $LIST = {
    summary => "List of modules related to Org format",
    description => <<'_',


_
    entries => [
        {module=>'App::org2wp'},
        {module=>'App::orgdaemon'},
        {module=>'App::orgsel'},
        {module=>'App::OrgUtils'},
        {module=>'Data::CSel'},
        {module=>'Data::Dmp::Org'},
        {module=>'Org::Dump'},
        {module=>'Org::Examples'},
        {module=>'Org::Parser'},
        {module=>'Org::Parser::Tiny'},
        {module=>'Org::To::HTML'},
        {module=>'Org::To::HTML::WordPress'},
        {module=>'Org::To::Pod'},
        {module=>'Org::To::Text'},
        {module=>'Org::To::VCF'},
        {module=>'Text::Table::Org'},
    ],
};

1;
# ABSTRACT: List of modules related to Org format

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Org - List of modules related to Org format

=head1 VERSION

This document describes version 0.005 of Acme::CPANModules::Org (from Perl distribution Acme-CPANModules-Org), released on 2023-10-29.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::org2wp>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::orgdaemon>

Author: L<SREZIC|https://metacpan.org/author/SREZIC>

=item L<App::orgsel>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::OrgUtils>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Data::CSel>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Data::Dmp::Org>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Org::Dump>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Org::Examples>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Org::Parser>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Org::Parser::Tiny>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Org::To::HTML>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Org::To::HTML::WordPress>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Org::To::Pod>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Org::To::Text>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Org::To::VCF>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::Org>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n Org

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Org | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Org -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Org -E'say $_->{module} for @{ $Acme::CPANModules::Org::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Org>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Org>.

=head1 SEE ALSO

L<https://orgmode.org>

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

This software is copyright (c) 2023, 2021, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Org>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

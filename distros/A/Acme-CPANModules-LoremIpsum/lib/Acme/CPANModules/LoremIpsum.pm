package Acme::CPANModules::LoremIpsum;

use strict;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-17'; # DATE
our $DIST = 'Acme-CPANModules-LoremIpsum'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'List of modules related to "Lorem Ipsum", or lipsum, placeholder Latin text',
    description => <<'_',

**Generating**

<pm:Text::Lorem> - You can specify number of words/sentences/paragraphs to
generate. Cannot generate text which really starts with 'Lorem ipsum ...'.

<pm:Text::Lorem::More> - Like Text::Lorem, except it allows filling out a
template with placeholder name, title, username, tld, email, url, and a few
others. Also cannot generate text which really starts with 'Lorem ipsum ...'.

WWW::Lipsum - a client to generate text from www.lipsum.com. As of this writing,
last release is in 2015, and it no longer works.

<pm:Text::Lorem::JA> - Japanese lipsum generator.

_
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules related to "Lorem Ipsum", or lipsum, placeholder Latin text

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::LoremIpsum - List of modules related to "Lorem Ipsum", or lipsum, placeholder Latin text

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::LoremIpsum (from Perl distribution Acme-CPANModules-LoremIpsum), released on 2023-11-17.

=head1 DESCRIPTION

B<Generating>

L<Text::Lorem> - You can specify number of words/sentences/paragraphs to
generate. Cannot generate text which really starts with 'Lorem ipsum ...'.

L<Text::Lorem::More> - Like Text::Lorem, except it allows filling out a
template with placeholder name, title, username, tld, email, url, and a few
others. Also cannot generate text which really starts with 'Lorem ipsum ...'.

WWW::Lipsum - a client to generate text from www.lipsum.com. As of this writing,
last release is in 2015, and it no longer works.

L<Text::Lorem::JA> - Japanese lipsum generator.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Text::Lorem>

Author: L<ADEOLA|https://metacpan.org/author/ADEOLA>

=item L<Text::Lorem::More>

Author: L<RKRIMEN|https://metacpan.org/author/RKRIMEN>

=item L<Text::Lorem::JA>

Author: L<DAYFLOWER|https://metacpan.org/author/DAYFLOWER>

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

 % cpanm-cpanmodules -n LoremIpsum

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries LoremIpsum | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=LoremIpsum -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::LoremIpsum -E'say $_->{module} for @{ $Acme::CPANModules::LoremIpsum::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-LoremIpsum>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-LoremIpsum>.

=head1 SEE ALSO

L<Acme::CPANModules::GeneratingRandomData>

L<Acme::CPANModules::GeneratingRandomText>

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-LoremIpsum>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

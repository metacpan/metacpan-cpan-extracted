package Acme::CPANModules::Locale::ID;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-Locale-ID'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "List of modules related to the Indonesian locale (language, country)",
    entries => [
        {module=>'App::cal::idn'},
        {module=>'Acme::ID::CompanyName'},
        {module=>'App::LinguaIDUtils'},
        {module=>'ArrayData::Lingua::Word::ID::KBBI'},
        {module=>'ArrayData::Lingua::Word::ID::Wordle'},
        {module=>'Calendar::Indonesia::Holiday'},
        {module=>'Graphics::ColorNames::HTML_ID'},
        {module=>'Graphics::ColorNamesLite::HTML_ID'},
        {module=>'Lingua::ID::Number::Format::MixWithWords'},
        {module=>'Lingua::ID::Nums2Words'},
        {module=>'Lingua::ID::Words2Nums'},
        {module=>'Locale::ID::District'},
        {module=>'Locale::ID::GuessGender::FromFirstName'},
        {module=>'Locale::ID::Locality'},
        {module=>'Locale::ID::ParseName::Person'},
        {module=>'Locale::ID::Province'},
        {module=>'Locale::ID::Village'},
        {module=>'Parse::Date::Month::ID'},
        {module=>'Parse::Number::ID'},
        {module=>'Parse::PhoneNumber::ID'},
        {module=>'WordList::ID::AnimalName::PERLANCAR'},
        {module=>'WordList::ID::BIP39'},
        {module=>'WordList::ID::ColorName::HTML_ID'},
        {module=>'WordList::ID::ColorName::PERLANCAR'},
        {module=>'WordList::ID::FruitName::PERLANCAR'},
        {module=>'WordList::ID::KBBI'},
        {module=>'WordList::ID::Wordle'},
        {module=>'WordList::Phrase::ID::Proverb::KBBI'},
        {module=>'WordLists::ID::Common'},
    ],
};

1;
# ABSTRACT: List of modules related to the Indonesian locale (language, country)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Locale::ID - List of modules related to the Indonesian locale (language, country)

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Locale::ID (from Perl distribution Acme-CPANModules-Locale-ID), released on 2023-08-06.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::cal::idn>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::ID::CompanyName>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::LinguaIDUtils>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<ArrayData::Lingua::Word::ID::KBBI>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<ArrayData::Lingua::Word::ID::Wordle>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Calendar::Indonesia::Holiday>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Graphics::ColorNames::HTML_ID>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Graphics::ColorNamesLite::HTML_ID>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Lingua::ID::Number::Format::MixWithWords>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Lingua::ID::Nums2Words>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Lingua::ID::Words2Nums>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Locale::ID::District>

=item L<Locale::ID::GuessGender::FromFirstName>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Locale::ID::Locality>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Locale::ID::ParseName::Person>

=item L<Locale::ID::Province>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Locale::ID::Village>

=item L<Parse::Date::Month::ID>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Parse::Number::ID>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Parse::PhoneNumber::ID>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordList::ID::AnimalName::PERLANCAR>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordList::ID::BIP39>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordList::ID::ColorName::HTML_ID>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordList::ID::ColorName::PERLANCAR>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordList::ID::FruitName::PERLANCAR>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordList::ID::KBBI>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordList::ID::Wordle>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordList::Phrase::ID::Proverb::KBBI>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordLists::ID::Common>

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

 % cpanm-cpanmodules -n Locale::ID

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Locale::ID | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Locale::ID -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Locale::ID -E'say $_->{module} for @{ $Acme::CPANModules::Locale::ID::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Locale-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Locale-ID>.

=head1 SEE ALSO

Other C<Acme::CPANModules::Locale::*>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Locale-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

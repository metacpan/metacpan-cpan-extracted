package Acme::CPANModules::RandomPassword;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-04-10'; # DATE
our $DIST = 'Acme-CPANModules-RandomPassword'; # DIST
our $VERSION = '0.002'; # VERSION

my $text = <<'_';

<pm:App::genpw> can generate passwords with patterns and wordlists. It loads
secure random number generator if available. By default it generates 12-20
character-long passwords comprising of ASCII letters and digits. There are
several variants which are basically wrappers for convenience:
<pm:App::genpw::base64>, <pm:App::genpw::base58>, <pm:App::genpw::base56>,
<pm:App::genpw::wordlist> (use words from wordlists), <pm:App::genpw::ind> (use
Indonesian words). The module will use `rand()` from `Data::Entropy::Algorithms`
if the module is available, for stronger random number generation.

<pm:Crypt::GeneratePassword> creates secure random pronounceable passwords. It
provides function `word()` which generates a sequence of letters with vocals in
between consonants so the word is still pronounceable, even though it's a
nonsense word. It also provides `chars()` which produces a sequence of random
letters, digits, and some symbols. It still uses `rand()` by default which is
not cryptographically secure.

<pm:Crypt::RandPasswd> implements the old FIPS 181 (1993, withdrawn 2015)
standard to generate pronounceable password, which is no longer recommended.

<pm:Crypt::PassGen>, yet another module to create random words that look like
real words. It does not use a secure random number generator by default.

<pm:Data::SimplePassword>

<pm:String::MkPasswd>

<pm:Data::Random::String> and <pm:Data::Random>.

<pm:Text::Password::Pronounceable::RandomCase>

<pm:String::Random>

<pm:String::Urandom>

<pm:Crypt::XkcdPassword>, a password generator module inspired by
<http://xkcd.com/936/>.

<pm:CtrlO::Crypt::XkcdPassword>, another password generator module inspired by
<http://xkcd.com/936/>.

<pm:App::GenPass>

<pm:Crypt::PW44>

<pm:Crypt::YAPassGen>

<pm:Session::Token>

<pm:Text::Password::Pronounceable>


For other types of random data, see other lists mentioned in the See Also
section.

Keywords: random secure password

_

our $LIST = {
    summary => 'List of modules for generating random passwords',
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules for generating random passwords

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RandomPassword - List of modules for generating random passwords

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::RandomPassword (from Perl distribution Acme-CPANModules-RandomPassword), released on 2023-04-10.

=head1 DESCRIPTION

L<App::genpw> can generate passwords with patterns and wordlists. It loads
secure random number generator if available. By default it generates 12-20
character-long passwords comprising of ASCII letters and digits. There are
several variants which are basically wrappers for convenience:
L<App::genpw::base64>, L<App::genpw::base58>, L<App::genpw::base56>,
L<App::genpw::wordlist> (use words from wordlists), L<App::genpw::ind> (use
Indonesian words). The module will use C<rand()> from C<Data::Entropy::Algorithms>
if the module is available, for stronger random number generation.

L<Crypt::GeneratePassword> creates secure random pronounceable passwords. It
provides function C<word()> which generates a sequence of letters with vocals in
between consonants so the word is still pronounceable, even though it's a
nonsense word. It also provides C<chars()> which produces a sequence of random
letters, digits, and some symbols. It still uses C<rand()> by default which is
not cryptographically secure.

L<Crypt::RandPasswd> implements the old FIPS 181 (1993, withdrawn 2015)
standard to generate pronounceable password, which is no longer recommended.

L<Crypt::PassGen>, yet another module to create random words that look like
real words. It does not use a secure random number generator by default.

L<Data::SimplePassword>

L<String::MkPasswd>

L<Data::Random::String> and L<Data::Random>.

L<Text::Password::Pronounceable::RandomCase>

L<String::Random>

L<String::Urandom>

L<Crypt::XkcdPassword>, a password generator module inspired by
L<http://xkcd.com/936/>.

L<CtrlO::Crypt::XkcdPassword>, another password generator module inspired by
L<http://xkcd.com/936/>.

L<App::GenPass>

L<Crypt::PW44>

L<Crypt::YAPassGen>

L<Session::Token>

L<Text::Password::Pronounceable>

For other types of random data, see other lists mentioned in the See Also
section.

Keywords: random secure password

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::genpw>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::genpw::base64>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::genpw::base58>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::genpw::base56>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::genpw::wordlist>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::genpw::ind>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Crypt::GeneratePassword>

Author: L<NEILB|https://metacpan.org/author/NEILB>

=item L<Crypt::RandPasswd>

Author: L<JANITOR|https://metacpan.org/author/JANITOR>

=item L<Crypt::PassGen>

Author: L<TJENNESS|https://metacpan.org/author/TJENNESS>

=item L<Data::SimplePassword>

Author: L<RYOCHIN|https://metacpan.org/author/RYOCHIN>

=item L<String::MkPasswd>

Author: L<CGRAU|https://metacpan.org/author/CGRAU>

=item L<Data::Random::String>

Author: L<MAKIS|https://metacpan.org/author/MAKIS>

=item L<Data::Random>

Author: L<BAREFOOT|https://metacpan.org/author/BAREFOOT>

=item L<Text::Password::Pronounceable::RandomCase>

Author: L<MDOM|https://metacpan.org/author/MDOM>

=item L<String::Random>

Author: L<SHLOMIF|https://metacpan.org/author/SHLOMIF>

=item L<String::Urandom>

Author: L<MBROOKS|https://metacpan.org/author/MBROOKS>

=item L<Crypt::XkcdPassword>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item L<CtrlO::Crypt::XkcdPassword>

Author: L<DOMM|https://metacpan.org/author/DOMM>

=item L<App::GenPass>

=item L<Crypt::PW44>

Author: L<BRIAND|https://metacpan.org/author/BRIAND>

=item L<Crypt::YAPassGen>

Author: L<GIULIENK|https://metacpan.org/author/GIULIENK>

=item L<Session::Token>

Author: L<FRACTAL|https://metacpan.org/author/FRACTAL>

=item L<Text::Password::Pronounceable>

Author: L<TSIBLEY|https://metacpan.org/author/TSIBLEY>

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

 % cpanm-cpanmodules -n RandomPassword

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries RandomPassword | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RandomPassword -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::RandomPassword -E'say $_->{module} for @{ $Acme::CPANModules::RandomPassword::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RandomPassword>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RandomPassword>.

=head1 SEE ALSO

L<Acme::CPANModules::Import::NEILB::Passwords>, which is extracted from
L<http://neilb.org/reviews/passwords.html>.

L<Acme::CPANModules::RandomData>

L<Acme::CPANModules::RandomPerson>

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RandomPassword>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

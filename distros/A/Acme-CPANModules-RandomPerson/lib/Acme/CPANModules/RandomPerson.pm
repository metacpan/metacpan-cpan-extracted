package Acme::CPANModules::RandomPerson;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-26'; # DATE
our $DIST = 'Acme-CPANModules-RandomPerson'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';
**Generating**

<pm:Data::RandomPerson> can generate random name, title, age, gender dob for
several "types" (language or geographic area): Arabic, Dutch, English,
ModernGreek, Spanish. There are data for other types included in the
distribution though: AncientGreek, Basque, Celtic, Hindi, Japanese, Latvian,
Thai, Viking. At the time of this writing (v0.60), there are 140 English female
first names to choose from, 130 English male first names, and 1003 English last
names.

The <pm:Mock::Person> namespace contains several modules to generate random
person names. The modules here are not exactly part of a single framework so the
interface might slightly differ from one another: <pm:Mock::Person::CZ> (Czech),
<pm:Mock::Person::DE> (German), <pm:Mock::Person::EN> (English),
<pm:Mock::Person::ID> (Indonesian), <pm:Mock::Person::JP> (Japanese),
<pm:Mock::Person::JV> (Javanese), <pm:Mock::Person::RU> (Russian),
<pm:Mock::Person::SK> (Slovak), <pm:Mock::Person::SK::ROM> (Romani),
<pm:Mock::Person::SV> (Swedish), <pm:Mock::Person::US> (American).

<pm:Data::Faker> is a plugin-based framework to generate random person name,
company name, phone number, street address, email, domain name, IP address, and
so on. The included name plugin only generates English names and there is no
option to pick male/female. At the time of this writing (v0.10), there are 474
last names and 3007 first names. It can also add suffixes like II, III, Jr.,
Sr.

<pm:Faker> is another plugin-based random data generator. The included plugins
can generate random street address, color, company name, company jargon/tagline,
buzzwords, IP address, email address, domain name, text ("lorem ipsum ..."),
credit card number, phone number, software name, username. However, some plugins
are currently empty. The name plugin contains 3007 first names and 474 last
names (probably copied from Data::Faker). There is no option to pick male/female
names.

Keywords: date of birth, mock person, fake data, fake person.

_

our $LIST = {
    summary => 'Generating random person (name, title, age, etc)',
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Generating random person (name, title, age, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RandomPerson - Generating random person (name, title, age, etc)

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::RandomPerson (from Perl distribution Acme-CPANModules-RandomPerson), released on 2021-05-26.

=head1 DESCRIPTION

B<Generating>

L<Data::RandomPerson> can generate random name, title, age, gender dob for
several "types" (language or geographic area): Arabic, Dutch, English,
ModernGreek, Spanish. There are data for other types included in the
distribution though: AncientGreek, Basque, Celtic, Hindi, Japanese, Latvian,
Thai, Viking. At the time of this writing (v0.60), there are 140 English female
first names to choose from, 130 English male first names, and 1003 English last
names.

The L<Mock::Person> namespace contains several modules to generate random
person names. The modules here are not exactly part of a single framework so the
interface might slightly differ from one another: L<Mock::Person::CZ> (Czech),
L<Mock::Person::DE> (German), L<Mock::Person::EN> (English),
L<Mock::Person::ID> (Indonesian), L<Mock::Person::JP> (Japanese),
L<Mock::Person::JV> (Javanese), L<Mock::Person::RU> (Russian),
L<Mock::Person::SK> (Slovak), L<Mock::Person::SK::ROM> (Romani),
L<Mock::Person::SV> (Swedish), L<Mock::Person::US> (American).

L<Data::Faker> is a plugin-based framework to generate random person name,
company name, phone number, street address, email, domain name, IP address, and
so on. The included name plugin only generates English names and there is no
option to pick male/female. At the time of this writing (v0.10), there are 474
last names and 3007 first names. It can also add suffixes like II, III, Jr.,
Sr.

L<Faker> is another plugin-based random data generator. The included plugins
can generate random street address, color, company name, company jargon/tagline,
buzzwords, IP address, email address, domain name, text ("lorem ipsum ..."),
credit card number, phone number, software name, username. However, some plugins
are currently empty. The name plugin contains 3007 first names and 474 last
names (probably copied from Data::Faker). There is no option to pick male/female
names.

Keywords: date of birth, mock person, fake data, fake person.

=head1 ACME::MODULES ENTRIES

=over

=item * L<Data::RandomPerson>

=item * L<Mock::Person>

=item * L<Mock::Person::CZ>

=item * L<Mock::Person::DE>

=item * L<Mock::Person::EN>

=item * L<Mock::Person::ID>

=item * L<Mock::Person::JP>

=item * L<Mock::Person::JV>

=item * L<Mock::Person::RU>

=item * L<Mock::Person::SK>

=item * L<Mock::Person::SK::ROM>

=item * L<Mock::Person::SV>

=item * L<Mock::Person::US>

=item * L<Data::Faker>

=item * L<Faker>

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

 % cpanm-cpanmodules -n RandomPerson

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries RandomPerson | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RandomPerson -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::RandomPerson -E'say $_->{module} for @{ $Acme::CPANModules::RandomPerson::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RandomPerson>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RandomPerson>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RandomPerson>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::RandomData>

L<Acme::CPANModules::RandomPassword>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

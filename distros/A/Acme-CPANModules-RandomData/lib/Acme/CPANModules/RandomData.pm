package Acme::CPANModules::RandomData;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-04-10'; # DATE
our $DIST = 'Acme-CPANModules-RandomData'; # DIST
our $VERSION = '0.004'; # VERSION

my $text = <<'_';
<pm:Data::Random> generates random number, random generated word, random
dictionary word (default wordlist provided), date (in YYYY-MM-DD format), time
(in HH::MM:SS format), datetime, image (just a blank PNG with random size and
background color).

<pm:Data::Maker> can generate realistic fake data including IP address, email,
password, person (first name, middle name, last name, SSN). It focuses on
performance (200 records/sec number is cited).

<pm:Data::Faker> is yet another moduxsle, with plugins to generate company name,
person name, date/time, phone number, street address, domain/IP/email/username.

<pm:Mock::Data> can generate several types of mock data including number, UUID,
IP/hostname/email, date/time, text.

<pm:Mock::Populate> in non-plugin-based, can generate random image, string,
name, date/time.

<pm:Faker> is another plugin-based random data generator. The included plugins
can generate random street address, color, company name, company jargon/tagline,
buzzwords, IP address, email address, domain name, text ("lorem ipsum ..."),
credit card number, phone number, software name, username. However, some plugins
are currently empty. The name plugin contains 3007 first names and 474 last
names (probably copied from Data::Faker). There is no option to pick male/female
names.

Other: <pm:Text::Lorem>.


For more specific types of random data (person, password, etc), see other lists
mentioned in the See Also section.

Keywords: random data, fake data, mock data.

_

our $LIST = {
    summary => 'List of modules for generating random (fake, mock) data',
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules for generating random (fake, mock) data

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RandomData - List of modules for generating random (fake, mock) data

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::RandomData (from Perl distribution Acme-CPANModules-RandomData), released on 2023-04-10.

=head1 DESCRIPTION

L<Data::Random> generates random number, random generated word, random
dictionary word (default wordlist provided), date (in YYYY-MM-DD format), time
(in HH::MM:SS format), datetime, image (just a blank PNG with random size and
background color).

L<Data::Maker> can generate realistic fake data including IP address, email,
password, person (first name, middle name, last name, SSN). It focuses on
performance (200 records/sec number is cited).

L<Data::Faker> is yet another moduxsle, with plugins to generate company name,
person name, date/time, phone number, street address, domain/IP/email/username.

L<Mock::Data> can generate several types of mock data including number, UUID,
IP/hostname/email, date/time, text.

L<Mock::Populate> in non-plugin-based, can generate random image, string,
name, date/time.

L<Faker> is another plugin-based random data generator. The included plugins
can generate random street address, color, company name, company jargon/tagline,
buzzwords, IP address, email address, domain name, text ("lorem ipsum ..."),
credit card number, phone number, software name, username. However, some plugins
are currently empty. The name plugin contains 3007 first names and 474 last
names (probably copied from Data::Faker). There is no option to pick male/female
names.

Other: L<Text::Lorem>.

For more specific types of random data (person, password, etc), see other lists
mentioned in the See Also section.

Keywords: random data, fake data, mock data.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Data::Random>

Author: L<BAREFOOT|https://metacpan.org/author/BAREFOOT>

=item L<Data::Maker>

Author: L<JINGRAM|https://metacpan.org/author/JINGRAM>

=item L<Data::Faker>

Author: L<WSHELDAHL|https://metacpan.org/author/WSHELDAHL>

=item L<Mock::Data>

Author: L<NERDVANA|https://metacpan.org/author/NERDVANA>

=item L<Mock::Populate>

Author: L<GENE|https://metacpan.org/author/GENE>

=item L<Faker>

Author: L<AWNCORP|https://metacpan.org/author/AWNCORP>

=item L<Text::Lorem>

Author: L<ADEOLA|https://metacpan.org/author/ADEOLA>

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

 % cpanm-cpanmodules -n RandomData

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries RandomData | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RandomData -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::RandomData -E'say $_->{module} for @{ $Acme::CPANModules::RandomData::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RandomData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RandomData>.

=head1 SEE ALSO

L<Acme::CPANModules::RandomPerson>

L<Acme::CPANModules::RandomPassword>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RandomData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

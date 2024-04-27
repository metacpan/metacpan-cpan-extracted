package Acme::CPANModules::BPOM::FoodRegistration;

use strict;
use warnings;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-22'; # DATE
our $DIST = 'Acme-CPANModules-BPOM-FoodRegistration'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'MARKDOWN';

The following are some utilities which can be used if you are doing food
registration at BPOM.


**Searching for products**

<prog:cek-bpom-products> (from <pm:App::CekBpom>) is a CLI front-end for
<https://cekbpom.pom.go.id>. Currently broken (not yet updated to the latest
version of the website).


**List of food additives**

<prog:bpom-list-food-additives> (from <pm:App::BPOMUtils::Table::FoodAdditive>)
is a CLI tool to search the database, which is scraped from BPOM website
(<https://ereg-rba.pom.go.id>).


**List of food ingredients**

<prog:bpom-list-food-ingredients-rba> (from
<pm:App::BPOMUtils::Table::FoodIngredient>) is a CLI tool to search the "daftar
bahan pangan" database, which is scraped from BPOM website
(<https://ereg-rba.pom.go.id>).


**List of food categories**

<prog:bpom-list-food-categories-rba> (from
<pm:App::BPOMUtils::Table::FoodCategory>) is a CLI tool to query the "kategori
pangan" database, which is scraped from BPOM website
(<https://ereg-rba.pom.go.id>).


**List of food types**

<prog:bpom-list-food-types-rba-importer> and
<prog:bpom-list-food-types-rba-producer> (from
<pm:App::BPOMUtils::Table::FoodType>) is a CLI tool to query the "jenis pangan"
database, which is scraped from BPOM website (<https://ereg-rba.pom.go.id>).


**List of registration code prefixes**

<prog:bpom-list-reg-code-prefixes> (from
<pm:App::BPOMUtils::Table::RegCodePrefix>) is a CLI tool to query the list of
known alphabetical prefixes in BPOM registered product codes.


**Conversion utilities**

From <pm:App::BPOMUtils::Additives>: <prog:convert-benzoate-unit>.

From <pm:App::MineralUtils>: <prog:convert-magnesium-unit>,
<prog:convert-potassium-unit>, <prog:convert-sodium-unit>.

From <pm:App::VitaminUtils>: <prog:convert-choline-unit>,
<prog:convert-cobalamin-unit>, <prog:convert-pantothenic-acid-unit>,
<prog:convert-pyridoxine-unit>, <prog:convert-vitamin-a-unit>,
<prog:convert-vitamin-b12-unit>, <prog:convert-vitamin-b5-unit>,
<prog:convert-vitamin-b6-unit>, <prog:convert-vitamin-d-unit>,
<prog:convert-vitamin-e-unit>.


**Producing Nutrition Facts tables**

<prog:bpom-show-nutrition-facts> (from <pm:App::BPOMUtils::NutritionFacts>).


**TableData**

<pm:TableData::Business::ID::BPOM::FoodCategory> and
<pm:TableData::Business::ID::BPOM::FoodTypeq> are lists of food categories and
food types, in TableData packaging. See <pm:TableData> for more details.


**Miscelanous**

<pm:App::BPOMUtils::RPO::Ingredients> contains some utilities, e.g.
<prog:bpom-rpo-ingredients-group-for-label> to help in creating/formatting
ingredients list on food label.

<pm:App::BPOMUtils::RPO::Checker> contains some utilities for checking your
documents before you upload them to BPOM website, e.g.
<prog:bpom-rpo-check-files>, <prog:bpom-rpo-check-files-label-design>.


**Keywords**

Indonesian Food and Drug Authority, pendaftaran pangan olahan, registrasi pangan
olahan, RPO.

MARKDOWN

our $LIST = {
    summary => 'List of modules and utilities related to Food Registration at BPOM',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules and utilities related to Food Registration at BPOM

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::BPOM::FoodRegistration - List of modules and utilities related to Food Registration at BPOM

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::BPOM::FoodRegistration (from Perl distribution Acme-CPANModules-BPOM-FoodRegistration), released on 2024-03-22.

=head1 DESCRIPTION

The following are some utilities which can be used if you are doing food
registration at BPOM.

B<Searching for products>

L<cek-bpom-products> (from L<App::CekBpom>) is a CLI front-end for
L<https://cekbpom.pom.go.id>. Currently broken (not yet updated to the latest
version of the website).

B<List of food additives>

L<bpom-list-food-additives> (from L<App::BPOMUtils::Table::FoodAdditive>)
is a CLI tool to search the database, which is scraped from BPOM website
(L<https://ereg-rba.pom.go.id>).

B<List of food ingredients>

L<bpom-list-food-ingredients-rba> (from
L<App::BPOMUtils::Table::FoodIngredient>) is a CLI tool to search the "daftar
bahan pangan" database, which is scraped from BPOM website
(L<https://ereg-rba.pom.go.id>).

B<List of food categories>

L<bpom-list-food-categories-rba> (from
L<App::BPOMUtils::Table::FoodCategory>) is a CLI tool to query the "kategori
pangan" database, which is scraped from BPOM website
(L<https://ereg-rba.pom.go.id>).

B<List of food types>

L<bpom-list-food-types-rba-importer> and
L<bpom-list-food-types-rba-producer> (from
L<App::BPOMUtils::Table::FoodType>) is a CLI tool to query the "jenis pangan"
database, which is scraped from BPOM website (L<https://ereg-rba.pom.go.id>).

B<List of registration code prefixes>

L<bpom-list-reg-code-prefixes> (from
L<App::BPOMUtils::Table::RegCodePrefix>) is a CLI tool to query the list of
known alphabetical prefixes in BPOM registered product codes.

B<Conversion utilities>

From L<App::BPOMUtils::Additives>: L<convert-benzoate-unit>.

From L<App::MineralUtils>: L<convert-magnesium-unit>,
L<convert-potassium-unit>, L<convert-sodium-unit>.

From L<App::VitaminUtils>: L<convert-choline-unit>,
L<convert-cobalamin-unit>, L<convert-pantothenic-acid-unit>,
L<convert-pyridoxine-unit>, L<convert-vitamin-a-unit>,
L<convert-vitamin-b12-unit>, L<convert-vitamin-b5-unit>,
L<convert-vitamin-b6-unit>, L<convert-vitamin-d-unit>,
L<convert-vitamin-e-unit>.

B<Producing Nutrition Facts tables>

L<bpom-show-nutrition-facts> (from L<App::BPOMUtils::NutritionFacts>).

B<TableData>

L<TableData::Business::ID::BPOM::FoodCategory> and
L<TableData::Business::ID::BPOM::FoodTypeq> are lists of food categories and
food types, in TableData packaging. See L<TableData> for more details.

B<Miscelanous>

L<App::BPOMUtils::RPO::Ingredients> contains some utilities, e.g.
L<bpom-rpo-ingredients-group-for-label> to help in creating/formatting
ingredients list on food label.

L<App::BPOMUtils::RPO::Checker> contains some utilities for checking your
documents before you upload them to BPOM website, e.g.
L<bpom-rpo-check-files>, L<bpom-rpo-check-files-label-design>.

B<Keywords>

Indonesian Food and Drug Authority, pendaftaran pangan olahan, registrasi pangan
olahan, RPO.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::CekBpom>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::BPOMUtils::Table::FoodAdditive>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::BPOMUtils::Table::FoodIngredient>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::BPOMUtils::Table::FoodCategory>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::BPOMUtils::Table::FoodType>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::BPOMUtils::Table::RegCodePrefix>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::BPOMUtils::Additives>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::MineralUtils>

=item L<App::VitaminUtils>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::BPOMUtils::NutritionFacts>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<TableData::Business::ID::BPOM::FoodCategory>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<TableData::Business::ID::BPOM::FoodTypeq>

=item L<TableData>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::BPOMUtils::RPO::Ingredients>

=item L<App::BPOMUtils::RPO::Checker>

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

 % cpanm-cpanmodules -n BPOM::FoodRegistration

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries BPOM::FoodRegistration | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=BPOM::FoodRegistration -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::BPOM::FoodRegistration -E'say $_->{module} for @{ $Acme::CPANModules::BPOM::FoodRegistration::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-BPOM-FoodRegistration>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-BPOM-FoodRegistration>.

=head1 SEE ALSO

L<Acme::CPANModules::BPOM::SupplementRegistration> (a.k.a.
L<Acme::CPANModules::BPOM::TradMedicineRegistration>)

L<Acme::CPANModules::BPOM::DrugRegistration>

L<Acme::CPANModules::BPOM::CosmeticsRegistration>>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-BPOM-FoodRegistration>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package Acme::CPANModules::CountryCodes;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-CountryCodes'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'List of modules related to country codes',
    description => <<'MARKDOWN',

## Basics

<pm:Locale::Country> and <pm:Locale::Codes::Country> (both part of
<pm:Locale::Codes now) should be your first go-to module. It is a core module
since perl 5.14 (Locale::Country from 5.8) and supports converting between
English country names and 2-letter- and 3-letter ISO country codes, and retired
codes. If you need to squeeze some milliseconds of loading time, you can use
<pm:Locale::Codes::Country_Codes> directly.


## Multilingual

There are some modules for non-English country names, e.g.
<pm:Locale::Codes::Country::FR> (for French). There is also
<pm:Locale::Country::Multilingual> to map ISO codes to localized country names.


## Subcountries

<pm:Locale::SubCountry>


## Types

Sah: <pm:Sah::Schema::country::code>, <pm:Sah::Schema::country::code::alpha2>,
<pm:Sah::Schema::country::code::alpha2>.

Moose: <pm:MooseX::Types::Locale::Country>,
<pm:MooseX::Types::Locale::Country::Fast>.


## Other utilities

<pm:Locale::Util::Country>

MARKDOWN
    'x.app.cpanmodules.show_entries' => 0,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules related to country codes

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CountryCodes - List of modules related to country codes

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::CountryCodes (from Perl distribution Acme-CPANModules-CountryCodes), released on 2023-08-06.

=head1 DESCRIPTION

=head2 Basics

L<Locale::Country> and L<Locale::Codes::Country> (both part of
<pm:Locale::Codes now) should be your first go-to module. It is a core module
since perl 5.14 (Locale::Country from 5.8) and supports converting between
English country names and 2-letter- and 3-letter ISO country codes, and retired
codes. If you need to squeeze some milliseconds of loading time, you can use
L<Locale::Codes::Country_Codes> directly.

=head2 Multilingual

There are some modules for non-English country names, e.g.
L<Locale::Codes::Country::FR> (for French). There is also
L<Locale::Country::Multilingual> to map ISO codes to localized country names.

=head2 Subcountries

L<Locale::SubCountry>

=head2 Types

Sah: L<Sah::Schema::country::code>, L<Sah::Schema::country::code::alpha2>,
L<Sah::Schema::country::code::alpha2>.

Moose: L<MooseX::Types::Locale::Country>,
L<MooseX::Types::Locale::Country::Fast>.

=head2 Other utilities

L<Locale::Util::Country>

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Locale::Country>

Author: L<SBECK|https://metacpan.org/author/SBECK>

=item L<Locale::Codes::Country>

Author: L<SBECK|https://metacpan.org/author/SBECK>

=item L<Locale::Codes::Country_Codes>

Author: L<SBECK|https://metacpan.org/author/SBECK>

=item L<Locale::Codes::Country::FR>

Author: L<NHORNE|https://metacpan.org/author/NHORNE>

=item L<Locale::Country::Multilingual>

Author: L<OSCHWALD|https://metacpan.org/author/OSCHWALD>

=item L<Locale::SubCountry>

Author: L<KIMRYAN|https://metacpan.org/author/KIMRYAN>

=item L<Sah::Schema::country::code>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Sah::Schema::country::code::alpha2>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<MooseX::Types::Locale::Country>

Author: L<MORIYA|https://metacpan.org/author/MORIYA>

=item L<MooseX::Types::Locale::Country::Fast>

Author: L<MORIYA|https://metacpan.org/author/MORIYA>

=item L<Locale::Util::Country>

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

 % cpanm-cpanmodules -n CountryCodes

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CountryCodes | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CountryCodes -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CountryCodes -E'say $_->{module} for @{ $Acme::CPANModules::CountryCodes::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CountryCodes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CountryCodes>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CountryCodes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

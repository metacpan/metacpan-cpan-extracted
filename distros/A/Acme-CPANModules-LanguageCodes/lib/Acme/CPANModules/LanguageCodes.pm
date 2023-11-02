package Acme::CPANModules::LanguageCodes;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-LanguageCodes'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules related to language codes',
    description => <<'MARKDOWN',

## Basics

<pm:Locale::Language> and <pm:Locale::Codes::Language> (both part of
<pm:Locale::Codes now) should be your first go-to module. It is a core module
since perl 5.14 (Locale::Language from 5.8) and supports converting between
English language names and 2-letter- and 3-letter ISO country codes, and retired
codes. If you need to squeeze some milliseconds of loading time, you can use
<pm:Locale::Codes::Language_Codes> directly.


## Types

Sah: <pm:Sah::Schema::language::code>, <pm:Sah::Schema::language::code::alpha2>,
<pm:Sah::Schema::language::code::alpha3>.

Moose: <pm:MooseX::Types::Locale::Language>,
<pm:MooseX::Types::Locale::Language::Fast>.


## Other utilities

<pm:Locale::Util::Language>

MARKDOWN
    'x.app.cpanmodules.show_entries' => 0,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules related to language codes

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::LanguageCodes - List of modules related to language codes

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::LanguageCodes (from Perl distribution Acme-CPANModules-LanguageCodes), released on 2023-08-06.

=head1 DESCRIPTION

=head2 Basics

L<Locale::Language> and L<Locale::Codes::Language> (both part of
<pm:Locale::Codes now) should be your first go-to module. It is a core module
since perl 5.14 (Locale::Language from 5.8) and supports converting between
English language names and 2-letter- and 3-letter ISO country codes, and retired
codes. If you need to squeeze some milliseconds of loading time, you can use
L<Locale::Codes::Language_Codes> directly.

=head2 Types

Sah: L<Sah::Schema::language::code>, L<Sah::Schema::language::code::alpha2>,
L<Sah::Schema::language::code::alpha3>.

Moose: L<MooseX::Types::Locale::Language>,
L<MooseX::Types::Locale::Language::Fast>.

=head2 Other utilities

L<Locale::Util::Language>

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Locale::Language>

Author: L<SBECK|https://metacpan.org/author/SBECK>

=item L<Locale::Codes::Language>

Author: L<SBECK|https://metacpan.org/author/SBECK>

=item L<Locale::Codes::Language_Codes>

Author: L<SBECK|https://metacpan.org/author/SBECK>

=item L<Sah::Schema::language::code>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Sah::Schema::language::code::alpha2>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Sah::Schema::language::code::alpha3>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<MooseX::Types::Locale::Language>

Author: L<MORIYA|https://metacpan.org/author/MORIYA>

=item L<MooseX::Types::Locale::Language::Fast>

Author: L<MORIYA|https://metacpan.org/author/MORIYA>

=item L<Locale::Util::Language>

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

 % cpanm-cpanmodules -n LanguageCodes

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries LanguageCodes | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=LanguageCodes -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::LanguageCodes -E'say $_->{module} for @{ $Acme::CPANModules::LanguageCodes::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-LanguageCodes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-LanguageCodes>.

=head1 SEE ALSO

Related lists: L<Acme::CPANModules::CountryCodes>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-LanguageCodes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

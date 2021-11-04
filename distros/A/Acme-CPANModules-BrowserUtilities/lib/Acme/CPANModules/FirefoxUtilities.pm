package Acme::CPANModules::FirefoxUtilities;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-09'; # DATE
our $DIST = 'Acme-CPANModules-BrowserUtilities'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use Acme::CPANModules::BrowserUtilities;
use Acme::CPANModulesUtil::Misc;

our $LIST = {
    summary => "Utilities for Firefox browser",
    description => $Acme::CPANModules::BrowserUtilities::text_firefox,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Utilities for Firefox browser

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::FirefoxUtilities - Utilities for Firefox browser

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::FirefoxUtilities (from Perl distribution Acme-CPANModules-BrowserUtilities), released on 2021-06-09.

=head1 DESCRIPTION

L<App::FirefoxUtils> (comes with CLIs like L<pause-firefox>,
L<unpause-firefox>, L<kill-firefox>, L<list-firefox-profiles>, etc).

L<App::DumpFirefoxHistory> (comes with CLI: L<dump-firefox-history>).

L<App::FirefoxMultiAccountContainersUtils> (comes with CLIs like:
L<firefox-mua-sort-containers>, L<firefox-mua-modify-containers>).

L<Firefox::Util::Profile>

L<Firefox::Sync::Client>

Install latest Firefox using L<instopt> (from L<App::instopt>) and
L<Software::Catalog::SW::firefox>.

L<WordList::HTTP::UserAgentString::Browser::Firefox>

B<I<Automating Firefox>>

L<Firefox::Marionette>

L<Selenium::Firefox>

L<WWW::Mechanize::Firefox> and L<MozRepl> used to be an alternative but no
longer work on current Firefox version (they require Firefox 54 or earlier).
Included in this group are: L<Firefox::Application>,
L<WWW::Mechanize::Firefox::Extended>.

=head1 ACME::MODULES ENTRIES

=over

=item * L<App::FirefoxUtils>

=item * L<App::DumpFirefoxHistory>

=item * L<App::FirefoxMultiAccountContainersUtils>

=item * L<Firefox::Util::Profile>

=item * L<Firefox::Sync::Client>

=item * L<App::instopt>

=item * L<Software::Catalog::SW::firefox>

=item * L<WordList::HTTP::UserAgentString::Browser::Firefox>

=item * L<Firefox::Marionette>

=item * L<Selenium::Firefox>

=item * L<WWW::Mechanize::Firefox>

=item * L<MozRepl>

=item * L<Firefox::Application>

=item * L<WWW::Mechanize::Firefox::Extended>

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

 % cpanm-cpanmodules -n FirefoxUtilities

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries FirefoxUtilities | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=FirefoxUtilities -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::FirefoxUtilities -E'say $_->{module} for @{ $Acme::CPANModules::FirefoxUtilities::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-BrowserUtilities>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-BrowserUtilities>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-BrowserUtilities>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::BrowserUtilities>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

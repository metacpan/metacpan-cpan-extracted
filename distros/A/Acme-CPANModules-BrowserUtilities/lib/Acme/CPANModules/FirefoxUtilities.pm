package Acme::CPANModules::FirefoxUtilities;

use strict;
use Acme::CPANModules::BrowserUtilities;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-BrowserUtilities'; # DIST
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => "List of utilities for Firefox browser",
    description => $Acme::CPANModules::BrowserUtilities::text_firefox,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of utilities for Firefox browser

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::FirefoxUtilities - List of utilities for Firefox browser

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::FirefoxUtilities (from Perl distribution Acme-CPANModules-BrowserUtilities), released on 2022-03-18.

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

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::FirefoxUtils> - Utilities related to Firefox

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::DumpFirefoxHistory> - Dump Firefox history

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::FirefoxMultiAccountContainersUtils> - Utilities related to Firefox Multi-Account Containers add-on

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Firefox::Util::Profile> - Given a Firefox profile name, return its directory

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Firefox::Sync::Client> - A Client for the Firefox Sync Server

Author: L<SCHRORG|https://metacpan.org/author/SCHRORG>

=item * L<App::instopt> - Download and install software

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Software::Catalog::SW::firefox> - Firefox

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<WordList::HTTP::UserAgentString::Browser::Firefox> - Collection of Firefox browser User-Agent strings

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Firefox::Marionette> - Automate the Firefox browser with the Marionette protocol

Author: L<DDICK|https://metacpan.org/author/DDICK>

=item * L<Selenium::Firefox> - Use FirefoxDriver without a Selenium server

Author: L<TEODESIAN|https://metacpan.org/author/TEODESIAN>

=item * L<WWW::Mechanize::Firefox> - use Firefox as if it were WWW::Mechanize

Author: L<CORION|https://metacpan.org/author/CORION>

=item * L<MozRepl> - Perl interface of MozRepl

Author: L<ZIGOROU|https://metacpan.org/author/ZIGOROU>

=item * L<Firefox::Application> - inspect and automate the Firefox UI

Author: L<CORION|https://metacpan.org/author/CORION>

=item * L<WWW::Mechanize::Firefox::Extended> - Adds handy functions to WWW::Mechanize::Firefox

Author: L<HOEKIT|https://metacpan.org/author/HOEKIT>

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
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-BrowserUtilities>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-BrowserUtilities>.

=head1 SEE ALSO

L<Acme::CPANModules::BrowserUtilities>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-BrowserUtilities>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package Acme::CPANModules::ChromeUtilities;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-09'; # DATE
our $DIST = 'Acme-CPANModules-BrowserUtilities'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use Acme::CPANModules::BrowserUtilities;
use Acme::CPANModulesUtil::Misc;

our $LIST = {
    summary => "Utilities for Google Chrome browser",
    description => $Acme::CPANModules::BrowserUtilities::text_chrome,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Utilities for Google Chrome browser

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ChromeUtilities - Utilities for Google Chrome browser

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::ChromeUtilities (from Perl distribution Acme-CPANModules-BrowserUtilities), released on 2021-06-09.

=head1 DESCRIPTION

L<App::ChromeUtils> (comes with CLIs like L<pause-chrome>,
L<unpause-chrome>, L<kill-chrome>, L<list-chrome-profiles>, etc).

L<App::DumpChromeHistory> (comes with CLI: L<dump-chrome-history>).

L<Chrome::Util::Profile>

L<WWW::Mechanize::Chrome>

=head1 ACME::MODULES ENTRIES

=over

=item * L<App::ChromeUtils>

=item * L<App::DumpChromeHistory>

=item * L<Chrome::Util::Profile>

=item * L<WWW::Mechanize::Chrome>

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

 % cpanm-cpanmodules -n ChromeUtilities

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ChromeUtilities | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ChromeUtilities -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ChromeUtilities -E'say $_->{module} for @{ $Acme::CPANModules::ChromeUtilities::LIST->{entries} }' | cpanm -n

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

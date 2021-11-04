package Acme::CPANModules::VivaldiUtilities;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-09'; # DATE
our $DIST = 'Acme-CPANModules-BrowserUtilities'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use Acme::CPANModules::BrowserUtilities;
use Acme::CPANModulesUtil::Misc;

our $LIST = {
    summary => "Utilities for Vivaldi browser",
    description => $Acme::CPANModules::BrowserUtilities::text_vivaldi,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Utilities for Vivaldi browser

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::VivaldiUtilities - Utilities for Vivaldi browser

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::VivaldiUtilities (from Perl distribution Acme-CPANModules-BrowserUtilities), released on 2021-06-09.

=head1 DESCRIPTION

L<App::VivaldiUtils> (comes with CLIs like L<pause-vivaldi>,
L<unpause-vivaldi>, L<kill-vivaldi>, L<list-vivaldi-profiles>, etc).

L<App::DumpVivaldiHistory> (comes with CLI: L<dump-vivaldi-history>).

L<Vivaldi::Util::Profile>

=head1 ACME::MODULES ENTRIES

=over

=item * L<App::VivaldiUtils>

=item * L<App::DumpVivaldiHistory>

=item * L<Vivaldi::Util::Profile>

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

 % cpanm-cpanmodules -n VivaldiUtilities

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries VivaldiUtilities | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=VivaldiUtilities -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::VivaldiUtilities -E'say $_->{module} for @{ $Acme::CPANModules::VivaldiUtilities::LIST->{entries} }' | cpanm -n

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

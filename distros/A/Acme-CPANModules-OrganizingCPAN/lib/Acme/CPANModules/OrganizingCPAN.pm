package Acme::CPANModules::OrganizingCPAN;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-03'; # DATE
our $DIST = 'Acme-CPANModules-OrganizingCPAN'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';
This list catalog efforts to organize CPAN and help users navigate the sea of
modules on CPAN.

**Bundles and Tasks**

A `Bundle::*` module lists several modules that will all get installed simply by
installing the Bundle module. A later project <pm:Task> aims to address some of
the shortcomings of `Bundle::*` modules.

**CPANAuthors**

<pm:Acme::CPANAuthors>::* modules contains lists of CPAN author ID's, grouped by
some criteria.

**CPANModules**

<pm:Acme::CPANModules>::* modules contains lists of CPAN modules (or scripts),
grouped by some criteria.

**Map of CPAN**

The Map of CPAN project, <https://mapofcpan.org>, visualizes modules on CPAN as
a map, with top namespaces with lots of modules under them appearing as islands
while less popular namespaces are shown in the water regions.

**CPAN ratings**

CPAN ratings, <https://cpanratings.perl.org/>, is an inactive project that
allows users to rate and review any CPAN module. In 2018, it no longer accepts
new submission. But all existing submissions are still browsable.

**PrePAN**

Calling itself "Social Reviewing for Perl Modules", <http://prepan.org/> lets an
author post about a module she plans to release, or perhaps just an idea of a
module, to get input on name, interface, or what have you. Alternatively, the
usual places where Perl communities hang out can be used for this use-case,
including the Perl subreddit (<https://reddit.com/r/perl>), IRC channels (see
<https://irc.perl.org>), or PerlMonks (https://www.perlmonks.org>).

_

our $LIST = {
    summary => "Efforts to organize CPAN",
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Efforts to organize CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::OrganizingCPAN - Efforts to organize CPAN

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::OrganizingCPAN (from Perl distribution Acme-CPANModules-OrganizingCPAN), released on 2021-06-03.

=head1 DESCRIPTION

This list catalog efforts to organize CPAN and help users navigate the sea of
modules on CPAN.

B<Bundles and Tasks>

A C<Bundle::*> module lists several modules that will all get installed simply by
installing the Bundle module. A later project L<Task> aims to address some of
the shortcomings of C<Bundle::*> modules.

B<CPANAuthors>

L<Acme::CPANAuthors>::* modules contains lists of CPAN author ID's, grouped by
some criteria.

B<CPANModules>

L<Acme::CPANModules>::* modules contains lists of CPAN modules (or scripts),
grouped by some criteria.

B<Map of CPAN>

The Map of CPAN project, L<https://mapofcpan.org>, visualizes modules on CPAN as
a map, with top namespaces with lots of modules under them appearing as islands
while less popular namespaces are shown in the water regions.

B<CPAN ratings>

CPAN ratings, L<https://cpanratings.perl.org/>, is an inactive project that
allows users to rate and review any CPAN module. In 2018, it no longer accepts
new submission. But all existing submissions are still browsable.

B<PrePAN>

Calling itself "Social Reviewing for Perl Modules", L<http://prepan.org/> lets an
author post about a module she plans to release, or perhaps just an idea of a
module, to get input on name, interface, or what have you. Alternatively, the
usual places where Perl communities hang out can be used for this use-case,
including the Perl subreddit (L<https://reddit.com/r/perl>), IRC channels (see
L<https://irc.perl.org>), or PerlMonks (https://www.perlmonks.org>).

=head1 ACME::MODULES ENTRIES

=over

=item * L<Task>

=item * L<Acme::CPANAuthors>

=item * L<Acme::CPANModules>

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

 % cpanm-cpanmodules -n OrganizingCPAN

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries OrganizingCPAN | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=OrganizingCPAN -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::OrganizingCPAN -E'say $_->{module} for @{ $Acme::CPANModules::OrganizingCPAN::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-OrganizingCPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-OrganizingCPAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-OrganizingCPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

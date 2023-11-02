package Acme::CPANModules::CPANModules;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-CPANModules'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => 'List of modules related to Acme::CPANModules',
    description => <<'_',

## Specification

<pm:Acme::CPANModules> is the specification.


## CLIs

<pm:App::cpanmodules> distribution contains the `cpanmodules` CLI to view lists
and entries from the command-line.

<pm:App::lcpan::CmdBundle::cpanmodules> distribution provides `cpanmodules-*`
subcommands for <pm:App::lcpan> which, like `cpanmodules` CLI, lets you view
lists and entries from the command-line.

<pm:App::CPANModulesUtils> distribution contains more CLI utilities related to
Acme::CPANModules, e.g. `acme-cpanmodules-for` to find whether a module is
mentioned in some Acme::CPANModules::* modules.

<pm:App::CreateAcmeCPANModulesImportModules>

<pm:App::CreateAcmeCPANModulesImportCPANRatingsModules>


## Dist::Zilla (and Pod::Weaver)

If you develop CPAN modules with Dist::Zilla, you can use
<pm:Dist::Zilla::Plugin::Acme::CPANModules> and
<pm:Pod::Weaver::Plugin::Acme::CPANModules>. There is also
<pm:Dist::Zilla::Plugin::Acme::CPANModules::Blacklist> to prevent adding
blacklisted dependencies into your distribution.


## Other modules

<pm:TableData::Acme::CPANModules>

<pm:Acme::CPANLists> is an older, deprecated specification.

<pm:Pod::From::Acme::CPANModules>


## Snippets

Acme::CPANModules::CPANModules contains this snippet to create entries by
extracting `<pm:...>` in the description:

    $LIST->{entries} = [
        map { +{module=>$_} }
            ($LIST->{description} =~ /<pm:(.+?)>/g)
    ];

This does not prevent duplicates. To do so:

    $LIST->{entries} = [
        map { +{module=>$_} }
            do { my %seen; grep { !$seen{$_}++ }
                 ($LIST->{description} =~ /<pm:(.+?)>/g)
             }
    ];

_
    'x.app.cpanmodules.show_entries' => 0,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules related to Acme::CPANModules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CPANModules - List of modules related to Acme::CPANModules

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::CPANModules (from Perl distribution Acme-CPANModules-CPANModules), released on 2023-08-06.

=head1 DESCRIPTION

=head2 Specification

L<Acme::CPANModules> is the specification.

=head2 CLIs

L<App::cpanmodules> distribution contains the C<cpanmodules> CLI to view lists
and entries from the command-line.

L<App::lcpan::CmdBundle::cpanmodules> distribution provides C<cpanmodules-*>
subcommands for L<App::lcpan> which, like C<cpanmodules> CLI, lets you view
lists and entries from the command-line.

L<App::CPANModulesUtils> distribution contains more CLI utilities related to
Acme::CPANModules, e.g. C<acme-cpanmodules-for> to find whether a module is
mentioned in some Acme::CPANModules::* modules.

L<App::CreateAcmeCPANModulesImportModules>

L<App::CreateAcmeCPANModulesImportCPANRatingsModules>

=head2 Dist::Zilla (and Pod::Weaver)

If you develop CPAN modules with Dist::Zilla, you can use
L<Dist::Zilla::Plugin::Acme::CPANModules> and
L<Pod::Weaver::Plugin::Acme::CPANModules>. There is also
L<Dist::Zilla::Plugin::Acme::CPANModules::Blacklist> to prevent adding
blacklisted dependencies into your distribution.

=head2 Other modules

L<TableData::Acme::CPANModules>

L<Acme::CPANLists> is an older, deprecated specification.

L<Pod::From::Acme::CPANModules>

=head2 Snippets

Acme::CPANModules::CPANModules contains this snippet to create entries by
extracting C<< E<lt>pm:...E<gt> >> in the description:

 $LIST->{entries} = [
     map { +{module=>$_} }
         ($LIST->{description} =~ /<pm:(.+?)>/g)
 ];

This does not prevent duplicates. To do so:

 $LIST->{entries} = [
     map { +{module=>$_} }
         do { my %seen; grep { !$seen{$_}++ }
              ($LIST->{description} =~ /<pm:(.+?)>/g)
          }
 ];

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Acme::CPANModules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::cpanmodules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::lcpan::CmdBundle::cpanmodules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::lcpan>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::CPANModulesUtils>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::CreateAcmeCPANModulesImportModules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::CreateAcmeCPANModulesImportCPANRatingsModules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Dist::Zilla::Plugin::Acme::CPANModules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Pod::Weaver::Plugin::Acme::CPANModules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Dist::Zilla::Plugin::Acme::CPANModules::Blacklist>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<TableData::Acme::CPANModules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::CPANLists>

=item L<Pod::From::Acme::CPANModules>

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

 % cpanm-cpanmodules -n CPANModules

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CPANModules | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CPANModules -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CPANModules -E'say $_->{module} for @{ $Acme::CPANModules::CPANModules::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CPANModules>.

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

This software is copyright (c) 2023, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

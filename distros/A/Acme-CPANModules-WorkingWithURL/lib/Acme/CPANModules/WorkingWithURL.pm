package Acme::CPANModules::WorkingWithURL;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-WorkingWithURL'; # DIST
our $VERSION = '0.002'; # VERSION

my $text = <<'_';
**Parsing**

<pm:URI>, the venerable module.

<pm:URI::Info> extracts things from URL.

For specific CPAN-related URLs, there are <pm:CPAN::Info::FromURL>,
<pm:CPAN::Release::FromURL>, <pm:CPAN::Author::FromURL>,
<pm:CPAN::Dist::FromURL>, <pm:CPAN::Module::FromURL>.

<pm:HTML::LinkExtor> extracts links from HTML document.


**Matching with regex**

<pm:Regexp::Common::URI>, <pm:Regexp::Pattern::URI>


** CLIs

<pm:App::grep::url> (contains CLI <prog:grep-url>) greps URLs in lines of text.

_

our $LIST = {
    summary => 'List of modules to work with URL',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to work with URL

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WorkingWithURL - List of modules to work with URL

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::WorkingWithURL (from Perl distribution Acme-CPANModules-WorkingWithURL), released on 2022-03-18.

=head1 DESCRIPTION

B<Parsing>

L<URI>, the venerable module.

L<URI::Info> extracts things from URL.

For specific CPAN-related URLs, there are L<CPAN::Info::FromURL>,
L<CPAN::Release::FromURL>, L<CPAN::Author::FromURL>,
L<CPAN::Dist::FromURL>, L<CPAN::Module::FromURL>.

L<HTML::LinkExtor> extracts links from HTML document.

B<Matching with regex>

L<Regexp::Common::URI>, L<Regexp::Pattern::URI>

** CLIs

L<App::grep::url> (contains CLI L<grep-url>) greps URLs in lines of text.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<URI> - Uniform Resource Identifiers (absolute and relative)

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

=item * L<URI::Info> - Extract various information from a URI (URL)

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<CPAN::Info::FromURL> - Extract/guess information from a URL

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<CPAN::Release::FromURL> - Extract CPAN release (tarball) name from a URL

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<CPAN::Author::FromURL> - Extract CPAN author from a URL

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<CPAN::Dist::FromURL> - Extract CPAN distribution name from a URL

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<CPAN::Module::FromURL> - Extract/guess CPAN module from a URL

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<HTML::LinkExtor> - Extract links from an HTML document

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

=item * L<Regexp::Common::URI>

Author: L<ABIGAIL|https://metacpan.org/author/ABIGAIL>

=item * L<Regexp::Pattern::URI> - Regexp patterns related to URI

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::grep::url> - Print lines having URL(s) (optionally of certain criteria) in them

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

 % cpanm-cpanmodules -n WorkingWithURL

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries WorkingWithURL | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=WorkingWithURL -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::WorkingWithURL -E'say $_->{module} for @{ $Acme::CPANModules::WorkingWithURL::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WorkingWithURL>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WorkingWithURL>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WorkingWithURL>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

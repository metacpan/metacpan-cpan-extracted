package Acme::CPANModules::WorkingWithURL;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-02'; # DATE
our $DIST = 'Acme-CPANModules-WorkingWithURL'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

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
    summary => 'Working with URL',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Working with URL

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WorkingWithURL - Working with URL

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::WorkingWithURL (from Perl distribution Acme-CPANModules-WorkingWithURL), released on 2021-07-02.

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

=head1 ACME::MODULES ENTRIES

=over

=item * L<URI>

=item * L<URI::Info>

=item * L<CPAN::Info::FromURL>

=item * L<CPAN::Release::FromURL>

=item * L<CPAN::Author::FromURL>

=item * L<CPAN::Dist::FromURL>

=item * L<CPAN::Module::FromURL>

=item * L<HTML::LinkExtor>

=item * L<Regexp::Common::URI>

=item * L<Regexp::Pattern::URI>

=item * L<App::grep::url>

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WorkingWithURL>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WorkingWithURL>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WorkingWithURL>

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

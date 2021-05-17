package Acme::CPANModules::ManagingMultipleRepositories;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-02'; # DATE
our $DIST = 'Acme-CPANModules-ManagingMultipleRepositories'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';
This Acme::CPANModules list catalogs tools to manage multiple repositories.

Keywords: git, vcs, cvs

**1. On CPAN**

**1.a git only**

<prog:gitbunch> from <pm:Git::Bunch>

<prog:got> from <pm:App::GitGot>

<prog:group-git> from <pm:Group::Git>


***1.b VCS-agnostic***

TBD


**2. Outside CPAN**

**2.a git only**

TBD


**2.b VCS-agnostic**

mr, <http://joeyh.name/code/mr>

_

our $LIST = {
    summary => 'Managing multiple repositories',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Managing multiple repositories

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ManagingMultipleRepositories - Managing multiple repositories

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ManagingMultipleRepositories (from Perl distribution Acme-CPANModules-ManagingMultipleRepositories), released on 2021-02-02.

=head1 DESCRIPTION

This Acme::CPANModules list catalogs tools to manage multiple repositories.

Keywords: git, vcs, cvs

B<1. On CPAN>

B<1.a git only>

L<gitbunch> from L<Git::Bunch>

L<got> from L<App::GitGot>

L<group-git> from L<Group::Git>

B<I<1.b VCS-agnostic>>

TBD

B<2. Outside CPAN>

B<2.a git only>

TBD

B<2.b VCS-agnostic>

mr, L<http://joeyh.name/code/mr>

=head1 ACME::MODULES ENTRIES

=over

=item * L<Git::Bunch>

=item * L<App::GitGot>

=item * L<Group::Git>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries ManagingMultipleRepositories | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ManagingMultipleRepositories -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ManagingMultipleRepositories -E'say $_->{module} for @{ $Acme::CPANModules::ManagingMultipleRepositories::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ManagingMultipleRepositories>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ManagingMultipleRepositories>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-ManagingMultipleRepositories/issues>

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

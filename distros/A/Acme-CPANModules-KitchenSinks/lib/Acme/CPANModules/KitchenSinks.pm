package Acme::CPANModules::KitchenSinks;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-04'; # DATE
our $DIST = 'Acme-CPANModules-KitchenSinks'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of kitchen sink libraries',
    description => <<'_',

A "kitchen sink" module is a module that tries to provide all sorts of
functions/methods for various things. It often starts as a developer's personal
"general utilities" library that grows and grows to the point of "it should
probably be refactored into multiple modules (but isn't yet)". Often it also
contains functionalities that are already present in other modules, but added
into the module anyway because it is convenient for the developer.

This list catalogs modules that I think are kitchen sink libraries.

_
    entries => [
        {module=>'Data::Table::Text'},
    ],
};

1;
# ABSTRACT: List of kitchen sink libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::KitchenSinks - List of kitchen sink libraries

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::KitchenSinks (from Perl distribution Acme-CPANModules-KitchenSinks), released on 2022-02-04.

=head1 DESCRIPTION

A "kitchen sink" module is a module that tries to provide all sorts of
functions/methods for various things. It often starts as a developer's personal
"general utilities" library that grows and grows to the point of "it should
probably be refactored into multiple modules (but isn't yet)". Often it also
contains functionalities that are already present in other modules, but added
into the module anyway because it is convenient for the developer.

This list catalogs modules that I think are kitchen sink libraries.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Data::Table::Text>

Author: L<PRBRENAN|https://metacpan.org/author/PRBRENAN>

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

 % cpanm-cpanmodules -n KitchenSinks

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries KitchenSinks | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=KitchenSinks -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::KitchenSinks -E'say $_->{module} for @{ $Acme::CPANModules::KitchenSinks::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-KitchenSinks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-KitchenSinks>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-KitchenSinks>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package Acme::CPANModules::KitchenSinks;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-26'; # DATE
our $DIST = 'Acme-CPANModules-KitchenSinks'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $LIST = {
    summary => 'Kitchen sink libraries',
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
# ABSTRACT: Kitchen sink libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::KitchenSinks - Kitchen sink libraries

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::KitchenSinks (from Perl distribution Acme-CPANModules-KitchenSinks), released on 2021-07-26.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-KitchenSinks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-KitchenSinks>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-KitchenSinks>

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

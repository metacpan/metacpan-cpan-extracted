package Acme::CPANModules::ArrayClassBuilder;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-08'; # DATE
our $DIST = 'Acme-CPANModules-ArrayClassBuilder'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of class builders for array-backed classes',
    description => <<'_',

This list catalogs class builders for classes that use array (instead of the
popular hash) as their backend storage.

Hash is the vastly popular backend for object due to its flexibility and
convenient mapping of hash keys to object attributes, but actually Perl objects
can be references to any kind of data (array, scalar, glob). Storing objects as
other kinds of references can be useful in terms of attribute access speed,
memory size, or other aspects. But they are not as versatile and generic as
hash.

_
    entries => [
        {module => 'Class::Accessor::Array'},
        {module => 'Class::Accessor::Array::Glob'},
        {module => 'Class::XSAccessor::Array'},
        {module => 'Class::ArrayObjects'},
        {module => 'Object::ArrayType::New',
         summary => 'Only supports defining constants for array indexes'},
    ],
};

1;
# ABSTRACT: List of class builders for array-backed classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ArrayClassBuilder - List of class builders for array-backed classes

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::ArrayClassBuilder (from Perl distribution Acme-CPANModules-ArrayClassBuilder), released on 2022-03-08.

=head1 DESCRIPTION

This list catalogs class builders for classes that use array (instead of the
popular hash) as their backend storage.

Hash is the vastly popular backend for object due to its flexibility and
convenient mapping of hash keys to object attributes, but actually Perl objects
can be references to any kind of data (array, scalar, glob). Storing objects as
other kinds of references can be useful in terms of attribute access speed,
memory size, or other aspects. But they are not as versatile and generic as
hash.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Class::Accessor::Array> - Generate accessors/constructor for array-based object

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Class::Accessor::Array::Glob> - Generate accessors/constructor for array-based object (supports globbing attribute)

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Class::XSAccessor::Array> - Generate fast XS accessors without runtime compilation

Author: L<SMUELLER|https://metacpan.org/author/SMUELLER>

=item * L<Class::ArrayObjects> - utility class for array based objects

Author: L<RONAN|https://metacpan.org/author/RONAN>

=item * L<Object::ArrayType::New> - Only supports defining constants for array indexes

Author: L<AVENJ|https://metacpan.org/author/AVENJ>

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

 % cpanm-cpanmodules -n ArrayClassBuilder

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ArrayClassBuilder | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ArrayClassBuilder -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ArrayClassBuilder -E'say $_->{module} for @{ $Acme::CPANModules::ArrayClassBuilder::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ArrayClassBuilder>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ArrayClassBuilder>.

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

This software is copyright (c) 2022, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ArrayClassBuilder>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

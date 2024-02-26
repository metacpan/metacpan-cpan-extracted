package Acme::CPANModules::NonMooseStyleClassBuilder;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-NonMooseStyleClassBuilder'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of non-Moose-style class builders',
    description => <<'_',

This list catalogs class builders with interface that is different than the
Moose family.

See also a whole host of Class::Accessor::* modules.

_
    entries => [
        {module => 'Class::Meta::AccessorBuilder',
         summary=>'Part of the Class::Meta framework'},
        {module => 'Class::Struct'},
        {module => 'Class::Builder'},
        {module => 'Class::GenSource',
         summary=>'This is more like code generator, it generates Perl code source for the entire class definition, not just accessors'},
        {module => 'Object::Declare'},
        {module => 'Object::Tiny'},
        {module => 'Class::Tiny'},
        {module => 'Object::New',
         summary=>'Only provides a new() constructor method'},
        {module => 'Class::Accessor',
         summary => 'Also supports Moose-style "has"'},
        {module => 'Class::XSAccessor',
         summary=>'Fast version of Class::Accessor, used by Moo'},
        ],
};

1;
# ABSTRACT: List of non-Moose-style class builders

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::NonMooseStyleClassBuilder - List of non-Moose-style class builders

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::NonMooseStyleClassBuilder (from Perl distribution Acme-CPANModules-NonMooseStyleClassBuilder), released on 2023-10-29.

=head1 DESCRIPTION

This list catalogs class builders with interface that is different than the
Moose family.

See also a whole host of Class::Accessor::* modules.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Class::Meta::AccessorBuilder>

Part of the Class::Meta framework.

Author: L<DWHEELER|https://metacpan.org/author/DWHEELER>

=item L<Class::Struct>

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item L<Class::Builder>

Author: L<HUANGWEI|https://metacpan.org/author/HUANGWEI>

=item L<Class::GenSource>

This is more like code generator, it generates Perl code source for the entire class definition, not just accessors.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Object::Declare>

Author: L<SHLOMIF|https://metacpan.org/author/SHLOMIF>

=item L<Object::Tiny>

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item L<Class::Tiny>

Author: L<DAGOLDEN|https://metacpan.org/author/DAGOLDEN>

=item L<Object::New>

Only provides a new() constructor method.

Author: L<AJKALD|https://metacpan.org/author/AJKALD>

=item L<Class::Accessor>

Also supports Moose-style "has".

Author: L<KASEI|https://metacpan.org/author/KASEI>

=item L<Class::XSAccessor>

Fast version of Class::Accessor, used by Moo.

Author: L<SMUELLER|https://metacpan.org/author/SMUELLER>

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

 % cpanm-cpanmodules -n NonMooseStyleClassBuilder

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries NonMooseStyleClassBuilder | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=NonMooseStyleClassBuilder -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::NonMooseStyleClassBuilder -E'say $_->{module} for @{ $Acme::CPANModules::NonMooseStyleClassBuilder::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-NonMooseStyleClassBuilder>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-NonMooseStyleClassBuilder>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::MooseStyleClassBuilder>

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-NonMooseStyleClassBuilder>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

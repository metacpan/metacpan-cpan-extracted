package Acme::CPANModules::PERLANCAR::NonMooseStyleClassBuilder;

our $DATE = '2018-06-11'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'Non-Moose-style class builders',
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
# ABSTRACT: Non-Moose-style class builders

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::NonMooseStyleClassBuilder - Non-Moose-style class builders

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PERLANCAR::NonMooseStyleClassBuilder (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2018-06-11.

=head1 DESCRIPTION

Non-Moose-style class builders.

This list catalogs class builders with interface that is different than the
Moose family.

See also a whole host of Class::Accessor::* modules.

=head1 INCLUDED MODULES

=over

=item * L<Class::Meta::AccessorBuilder> - Part of the Class::Meta framework

=item * L<Class::Struct>

=item * L<Class::Builder>

=item * L<Class::GenSource> - This is more like code generator, it generates Perl code source for the entire class definition, not just accessors

=item * L<Object::Declare>

=item * L<Object::Tiny>

=item * L<Class::Tiny>

=item * L<Object::New> - Only provides a new() constructor method

=item * L<Class::Accessor> - Also supports Moose-style "has"

=item * L<Class::XSAccessor> - Fast version of Class::Accessor, used by Moo

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesBundle-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

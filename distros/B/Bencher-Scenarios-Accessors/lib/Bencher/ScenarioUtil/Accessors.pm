package Bencher::ScenarioUtil::Accessors;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.14'; # VERSION

our %classes = (
    # manual
    'Perl::Examples::Accessors::Hash'                 => {backend=>'hash'  , immutable=>0, generator=>undef, name=>'no generator (hash-based)'},
    'Perl::Examples::Accessors::Array'                => {backend=>'array' , immutable=>0, generator=>undef, name=>'no generator (array-based)'},
    'Perl::Examples::Accessors::Scalar'               => {backend=>'scalar', immutable=>1, generator=>undef, name=>'no generator (scalar-based)'},

    # Class::Struct
    'Perl::Examples::Accessors::ClassStruct'          => {backend=>'hash'  , immutable=>0, generator=>'Class::Struct'},

    # Moo* big family
    'Perl::Examples::Accessors::Mo'                   => {backend=>'hash'  , immutable=>0, generator=>'Mo'},
    'Perl::Examples::Accessors::Moo'                  => {backend=>'hash'  , immutable=>0, generator=>'Moo'},
    'Perl::Examples::Accessors::Moos'                 => {backend=>'hash'  , immutable=>0, generator=>'Moos'},
    'Perl::Examples::Accessors::Moose'                => {backend=>'hash'  , immutable=>0, generator=>'Moose'},
    'Perl::Examples::Accessors::Mouse'                => {backend=>'hash'  , immutable=>0, generator=>'Mouse'},
    'Perl::Examples::Accessors::Moops'                => {backend=>'hash'  , immutable=>0, generator=>'Moops'},

    # Mojo::Base family
    'Perl::Examples::Accessors::MojoBase'             => {backend=>'hash'  , immutable=>0, generator=>'Mojo::Base'},
    'Perl::Examples::Accessors::MojoBaseXS'           => {backend=>'hash'  , immutable=>0, generator=>'Mojo::Base::XS'},
    'Perl::Examples::Accessors::ObjectSimple'         => {backend=>'hash'  , immutable=>0, generator=>'Object::Simple'},

    # Class::Accessors and variants
    'Perl::Examples::Accessors::ClassAccessor'        => {backend=>'hash'  , immutable=>0, generator=>'Class::Accessor'},
    'Perl::Examples::Accessors::ClassAccessorArray'   => {backend=>'array' , immutable=>0, generator=>'Class::Accessor::Array'},
    'Perl::Examples::Accessors::ClassInsideOut'       => {backend=>'hash'  , immutable=>0, generator=>'Class::InsideOut', name=>'Class::InsideOut'},
    #'Perl::Examples::Accessors::ClassAccessorArrayGlob' => {backend=>'array' , immutable=>0, generator=>'Class::Accessor::Array::Glob'},
    #'Perl::Examples::Accessors::ClassBuildArrayGlob'  => {backend=>'array'  , immutable=>0, generator=>'Class::Build::Array::Glob'},
    'Perl::Examples::Accessors::ClassXSAccessor'      => {backend=>'hash'  , immutable=>0, generator=>'Class::XSAccessor'},
    'Perl::Examples::Accessors::ClassXSAccessorArray' => {backend=>'array' , immutable=>0, generator=>'Class::XSAccessor::Array'},

    'Perl::Examples::Accessors::SimpleAccessor'       => {backend=>'hash'  , immutable=>0, generator=>'Simple::Accessor'},

    # Class::Tiny and variants
    'Perl::Examples::Accessors::ClassTiny'            => {backend=>'hash'  , immutable=>0, generator=>'Class::Tiny'},

    # Object::Tiny and variants
    'Perl::Examples::Accessors::ObjectTiny'           => {backend=>'hash'  , immutable=>0, generator=>'Object::Tiny', supports_setters=>0},
    'Perl::Examples::Accessors::ObjectTinyXS'         => {backend=>'hash'  , immutable=>0, generator=>'Object::Tiny::XS', supports_setters=>0},
    'Perl::Examples::Accessors::ObjectTinyRW'         => {backend=>'hash'  , immutable=>0, generator=>'Object::Tiny::RW'},
    'Perl::Examples::Accessors::ObjectTinyRWXS'       => {backend=>'hash'  , immutable=>0, generator=>'Object::Tiny::RW::XS'},

    # others
    'Perl::Examples::Accessors::EvoClass'             => {backend=>'hash'  , immutable=>0, generator=>'Evo::Class'},

);

our %attrs = (
    attr1 => {is=>'rw'},
);

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioUtil::Accessors - Utility routines

=head1 VERSION

This document describes version 0.14 of Bencher::ScenarioUtil::Accessors (from Perl distribution Bencher-Scenarios-Accessors), released on 2017-01-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Accessors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Accessors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Bencher::ScenarioUtil::Accessors;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Accessors'; # DIST
our $VERSION = '0.151'; # VERSION

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
    'Perl::Examples::Accessors::ClassAccessorPackedString'    => {backend=>'scalar' , immutable=>0, generator=>'Class::Accessor::PackedString'},
    'Perl::Examples::Accessors::ClassAccessorPackedStringSet' => {backend=>'scalar' , immutable=>0, generator=>'Class::Accessor::PackedString::Set'},
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

    # Object::Pad
    'Perl::Examples::Accessors::ObjectPad'            => {backend=>'hash'  , immutable=>0, generator=>'Object::Pad', supports_setters=>1, setter_name=>"set_attr1"},

    # others
    #'Perl::Examples::Accessors::EvoClass'             => {backend=>'hash'  , immutable=>0, generator=>'Evo::Class'}, # removed 2021-08-03 in Perl-Examples-Accessors due to non-working code

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

This document describes version 0.151 of Bencher::ScenarioUtil::Accessors (from Perl distribution Bencher-ScenarioBundle-Accessors), released on 2024-05-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Accessors>.

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

This software is copyright (c) 2024, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Accessors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

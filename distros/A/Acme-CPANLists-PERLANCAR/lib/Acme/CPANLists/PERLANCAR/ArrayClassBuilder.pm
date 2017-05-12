package Acme::CPANLists::PERLANCAR::ArrayClassBuilder;

our $DATE = '2016-12-28'; # DATE
our $VERSION = '0.19'; # VERSION

our @Module_Lists = (
    {
        summary => 'Class builders for array-backed classes',
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
    },
);

1;
# ABSTRACT: Class builders for array-backed classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::ArrayClassBuilder - Class builders for array-backed classes

=head1 VERSION

This document describes version 0.19 of Acme::CPANLists::PERLANCAR::ArrayClassBuilder (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2016-12-28.

=head1 MODULE LISTS

=head2 Class builders for array-backed classes

This list catalogs class builders for classes that use array (instead of the
popular hash) as their backend storage.

Hash is the vastly popular backend for object due to its flexibility and
convenient mapping of hash keys to object attributes, but actually Perl objects
can be references to any kind of data (array, scalar, glob). Storing objects as
other kinds of references can be useful in terms of attribute access speed,
memory size, or other aspects. But they are not as versatile and generic as
hash.


=over

=item * L<Class::Accessor::Array>

=item * L<Class::Accessor::Array::Glob>

=item * L<Class::XSAccessor::Array>

=item * L<Class::ArrayObjects>

=item * L<Object::ArrayType::New> - Only supports defining constants for array indexes

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANLists-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANLists-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANLists-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists> - about the Acme::CPANLists namespace

L<acme-cpanlists> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

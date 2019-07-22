package Acme::CPANModules::DataStructureWalker;

our $DATE = '2019-06-30'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "Modules that traverse your data structure",
    description => <<'_',

This list catalogs modules that let you traverse your data structure by visiting
each node/item: each element of an array, each key/value pair of a hash,
recursively. Sort of like <pm:File::Find> for your data instead of filesystem.
These modules can be used for searching or modifying your data.

Many modules in this list mimic Perl's `map` interface, for example:
<pm:Data::Rmap>, <pm:Data::Dmap>, <pm:Data::Traverse>. The difference among
these modules lies in the details: in how you specify option to skip unsupported
types of references, or whether some let you control the recursion (e.g.
Data::Rmap's and Data::Dmap's `cut`),

<pm:Data::Walk> models its interface on File::Find. It lets you choose whether
you want to go depth-first or breadth-first.

Benchmarks for these modules coming soon.

Related modules:

<pm:Data::Clean> can be used to clean/sanitize your data structure more
performantly compared to your manual walking (e.g. using Data::Rmap). It works
by generating Perl code specifically for your cleaning needs.

_
    entries => [
        {module => 'Data::Rmap'},
        {module => 'Data::Dmap'},
        {module => 'Data::Visitor'},
        {module => 'Data::Transformer'},
        {module => 'Data::Traverse'},
        {module => 'Data::Leaf::Walker'},
        {module => 'Data::Walk'},

        {module => 'Data::Clean'},
    ],
};

1;
# ABSTRACT: Modules that traverse your data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::DataStructureWalker - Modules that traverse your data structure

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::DataStructureWalker (from Perl distribution Acme-CPANModules-DataStructureWalker), released on 2019-06-30.

=head1 DESCRIPTION

Modules that traverse your data structure.

This list catalogs modules that let you traverse your data structure by visiting
each node/item: each element of an array, each key/value pair of a hash,
recursively. Sort of like L<File::Find> for your data instead of filesystem.
These modules can be used for searching or modifying your data.

Many modules in this list mimic Perl's C<map> interface, for example:
L<Data::Rmap>, L<Data::Dmap>, L<Data::Traverse>. The difference among
these modules lies in the details: in how you specify option to skip unsupported
types of references, or whether some let you control the recursion (e.g.
Data::Rmap's and Data::Dmap's C<cut>),

L<Data::Walk> models its interface on File::Find. It lets you choose whether
you want to go depth-first or breadth-first.

Benchmarks for these modules coming soon.

Related modules:

L<Data::Clean> can be used to clean/sanitize your data structure more
performantly compared to your manual walking (e.g. using Data::Rmap). It works
by generating Perl code specifically for your cleaning needs.

=head1 INCLUDED MODULES

=over

=item * L<Data::Rmap>

=item * L<Data::Dmap>

=item * L<Data::Visitor>

=item * L<Data::Transformer>

=item * L<Data::Traverse>

=item * L<Data::Leaf::Walker>

=item * L<Data::Walk>

=item * L<Data::Clean>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-DataStructureWalker>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-DataStructureWalker>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-DataStructureWalker>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

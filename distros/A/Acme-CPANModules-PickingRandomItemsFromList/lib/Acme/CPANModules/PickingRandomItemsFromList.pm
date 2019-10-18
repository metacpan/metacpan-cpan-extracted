package Acme::CPANModules::PickingRandomItemsFromList;

our $DATE = '2019-09-15'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Picking random items from a list',
    description => <<'_',

If you are picking random lines from a file, there's a separate CPANModules list
for it: <pm:Acme::CPANModules::PickingRandomLinesFromFile>. If your "list" is a
Perl array, there's `shuffle` from <pm:List::Util> and `samples` from
<pm:List::MoreUtils> (if you don't want duplicates) or you can just select
random elements using `rand()` if you don't mind duplicates.

_
    tags => ['task'],
    entries => [
        {
            module=>'List::Util',
        },
        {
            module=>'List::MoreUtils',
        },
    ],
};

1;
# ABSTRACT: Picking random items from a list

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PickingRandomItemsFromList - Picking random items from a list

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::PickingRandomItemsFromList (from Perl distribution Acme-CPANModules-PickingRandomItemsFromList), released on 2019-09-15.

=head1 DESCRIPTION

Picking random items from a list.

If you are picking random lines from a file, there's a separate CPANModules list
for it: L<Acme::CPANModules::PickingRandomLinesFromFile>. If your "list" is a
Perl array, there's C<shuffle> from L<List::Util> and C<samples> from
L<List::MoreUtils> (if you don't want duplicates) or you can just select
random elements using C<rand()> if you don't mind duplicates.

=head1 INCLUDED MODULES

=over

=item * L<List::Util>

=item * L<List::MoreUtils>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PickingRandomItemsFromList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PickingRandomItemsFromList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PickingRandomItemsFromList>

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

package Acme::CPANLists::PERLANCAR::Task::WorkingWithTree;

our $DATE = '2017-09-08'; # DATE
our $VERSION = '0.26'; # VERSION

my $text = <<'_';
**Basics**

Perl classes to represent tree (node) structure: <pm:Tree::Object> and
<pm:Tree::ObjectXS> (comes with several varieties). They provide methods like
walking a tree, checking whether a node is the first child, getting sibling
nodes, and so on.

Perl modules to manipulate tree: <pm:Data::Tree>, <pm:Tree::Simple>.

Memory-efficient tree nodes in Perl: <pm:Tree::Node>.


**Creating**

<pm:Tree::FromStruct>, <pm:Tree::FromText>, <pm:Tree::FromTextLines>,
<pm:Tree::Create::Callback>, <pm:Tree::Create::Callback::ChildrenPerLevel>,
<pm:Tree::Create::Size>, <pm:Tree::FromFS>.

<pm:Data::Random::Tree>.


**Visualizing as text**

<pm:Tree::ToText>, <pm:Tree::ToTextLines>.


**Visualizing as graphic**

TODO


**Other modules**

<pm:Tree::ToFS>.

Special kinds of trees: TODO.


**Roles**

<pm:Role::TinyCommons::Tree>.

_

our @Module_Lists = (
    {
        summary => 'Working with tree data structure in Perl',
        description => $text,
        tags => ['task'],
        entries => [
            map { +{module=>$_} } $text =~ /`(\w+(?:::\w+)+)`/g
        ],
    },
);

1;
# ABSTRACT: Working with tree data structure in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::Task::WorkingWithTree - Working with tree data structure in Perl

=head1 VERSION

This document describes version 0.26 of Acme::CPANLists::PERLANCAR::Task::WorkingWithTree (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-09-08.

=head1 MODULE LISTS

=head2 Working with tree data structure in Perl

B<Basics>

Perl classes to represent tree (node) structure: L<Tree::Object> and
L<Tree::ObjectXS> (comes with several varieties). They provide methods like
walking a tree, checking whether a node is the first child, getting sibling
nodes, and so on.

Perl modules to manipulate tree: L<Data::Tree>, L<Tree::Simple>.

Memory-efficient tree nodes in Perl: L<Tree::Node>.

B<Creating>

L<Tree::FromStruct>, L<Tree::FromText>, L<Tree::FromTextLines>,
L<Tree::Create::Callback>, L<Tree::Create::Callback::ChildrenPerLevel>,
L<Tree::Create::Size>, L<Tree::FromFS>.

L<Data::Random::Tree>.

B<Visualizing as text>

L<Tree::ToText>, L<Tree::ToTextLines>.

B<Visualizing as graphic>

TODO

B<Other modules>

L<Tree::ToFS>.

Special kinds of trees: TODO.

B<Roles>

L<Role::TinyCommons::Tree>.


=over

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

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

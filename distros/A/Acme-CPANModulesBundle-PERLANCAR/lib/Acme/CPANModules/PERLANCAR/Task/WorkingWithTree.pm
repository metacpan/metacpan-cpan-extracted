package Acme::CPANModules::PERLANCAR::Task::WorkingWithTree;

our $DATE = '2019-01-06'; # DATE
our $VERSION = '0.004'; # VERSION

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

our $LIST = {
    summary => 'Working with tree data structure in Perl',
    description => $text,
    tags => ['task'],
    entries => [
        map { +{module=>$_} } $text =~ /`(\w+(?:::\w+)+)`/g
    ],
};

1;
# ABSTRACT: Working with tree data structure in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::Task::WorkingWithTree - Working with tree data structure in Perl

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::PERLANCAR::Task::WorkingWithTree (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2019-01-06.

=head1 DESCRIPTION

Working with tree data structure in Perl.

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

=head1 INCLUDED MODULES

=over

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

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

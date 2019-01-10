package Acme::CPANModules::WorkingWithTree;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.001'; # VERSION

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
        map { +{module=>$_} } $text =~ /<pm:(\w+(?:::\w+)+)>/g
    ],
};

1;
# ABSTRACT: Working with tree data structure in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WorkingWithTree - Working with tree data structure in Perl

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::WorkingWithTree (from Perl distribution Acme-CPANModules-WorkingWithTree), released on 2019-01-09.

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

=item * L<Tree::Object>

=item * L<Tree::ObjectXS>

=item * L<Data::Tree>

=item * L<Tree::Simple>

=item * L<Tree::Node>

=item * L<Tree::FromStruct>

=item * L<Tree::FromText>

=item * L<Tree::FromTextLines>

=item * L<Tree::Create::Callback>

=item * L<Tree::Create::Callback::ChildrenPerLevel>

=item * L<Tree::Create::Size>

=item * L<Tree::FromFS>

=item * L<Data::Random::Tree>

=item * L<Tree::ToText>

=item * L<Tree::ToTextLines>

=item * L<Tree::ToFS>

=item * L<Role::TinyCommons::Tree>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WorkingWithTree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WorkingWithTree>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WorkingWithTree>

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
